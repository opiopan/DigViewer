//
//  Document.m
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import "Document.h"
#import "DocumentConfigController.h"
#import "DocumentWindowController.h"
#import "LoadingSheetController.h"
#import "DVRemoteServer.h"
#import "ImageRenderer.h"

#include "CoreFoundationHelper.h"

//-----------------------------------------------------------------------------------------
// Document class implementation
//-----------------------------------------------------------------------------------------
@implementation Document{
    LoadingSheetController* loader;
    DocumentConfigController* modelOption;
    DocumentConfigController* loadingModelOption;
    BOOL pendingReloadRequest;
    DocumentWindowController* windowController;
}

@synthesize root;

//-----------------------------------------------------------------------------------------
// NSDocument クラスメソッド：ドキュメントの振る舞い
//-----------------------------------------------------------------------------------------
+ (BOOL)autosavesDrafts
{
    return NO;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

+ (BOOL)preservesVersions
{
    return NO;
}

+ (BOOL)usesUbiquitousStorage
{
    return NO;
}

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// WindowController生成
//-----------------------------------------------------------------------------------------
- (void)makeWindowControllers
{
    windowController = [[DocumentWindowController alloc] init];
    [self addWindowController:windowController];
}

//-----------------------------------------------------------------------------------------
// フレームワークからのドキュメントロード指示
//   ・なにもせずロード完了したように振る舞う
//   ・実際のロード処理はnibのロード完了後バックグラウンドスレッドで実施
//　　　(DocumentWindowControllerがスケジュール)
//   ・ロード時間が長い場合にハングしたように見えるのを避けるためこのような仕様とした
//-----------------------------------------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    _documentWindowPreferences = [self loadDocumentWindowPreferencesFromURL:absoluteURL];
    return YES;
}

//-----------------------------------------------------------------------------------------
// ドキュメントロード
// 　・senderがwindowControllerの場合は初回ロード or Shareed User Defaults ControllerからのKVO通知
//   ・senderがwindowControllerでない場合(MainMenuの場合)はメニューからリロードを選択
//-----------------------------------------------------------------------------------------
- (void)loadDocument:(id)sender
{
    if (loader){
        pendingReloadRequest = (sender == windowController);
        return;
    }
    pendingReloadRequest = NO;
    DocumentConfigController* option = [[DocumentConfigController sharedController] snapshot];
    if (sender == windowController && [modelOption isEqualTo:option]){
        return;
    }
    loadingModelOption = option;
    loader = [[LoadingSheetController alloc] init];
    [loader loadPath:[self.fileURL path] forWindow:self.windowForSheet modalDelegate:self
      didEndSelector:@selector(didEndLoadingDocument:) condition:loadingModelOption.condition];
}

- (void)didEndLoadingDocument:(PathNode*)node
{
    if (node){
        modelOption = loadingModelOption;
        [windowController setDocumentData:node];
    }else{
        if (!root){
            [self.windowForSheet close];
        }
    }
    loadingModelOption = nil;
    loader = nil;
    if (pendingReloadRequest){
        [self loadDocument:windowController];
    }
}

//-----------------------------------------------------------------------------------------
// ドキュメントウインドウ設定のロード＆セーブ
// 　・対象フォルダに「.DigViewer.preferences」という隠しファイルを作成
//-----------------------------------------------------------------------------------------
static NSString* PREFARENCES_FILE_NAME = @"/.DigViewer.preferences";

- (NSDictionary*)loadDocumentWindowPreferencesFromURL:(NSURL*)url
{
    NSDictionary* rc = nil;
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];

    if ([[controller.values valueForKey:@"saveWindowPreferences"] boolValue]){
        rc = [NSDictionary dictionaryWithContentsOfFile:[url.path stringByAppendingString:PREFARENCES_FILE_NAME]];
    }
    
    return rc;
}

- (void)saveDocumentWindowPreferences:(NSDictionary *)preferences
{
    NSString* path = [self.fileURL.path stringByAppendingString:PREFARENCES_FILE_NAME];
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    if ([[controller.values valueForKey:@"saveWindowPreferences"] boolValue]){
        [preferences writeToFile:path atomically:NO];
    }else{
        NSFileManager* manager = [NSFileManager defaultManager];
        NSError* error;
        [manager removeItemAtPath:path error:&error];
    }
}

//-----------------------------------------------------------------------------------------
// コンパニオンアプリへのサムネール送信
//-----------------------------------------------------------------------------------------
static const CGFloat thumbnailSize = 256;
- (void)sendThumbnails:(NSArray *)ids
{
    NSString* documentName = self.fileURL.path;
    dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (NSArray* pathID in ids){
        PathNode* currentNode = [root nearestNodeAtPortablePath:pathID];
        dispatch_async(que, ^(void){
            NSImage* image;
            id thumbnail = [currentNode thumbnailImage:thumbnailSize];
            if ([thumbnail isKindOfClass:[NSImage class]]){
                image = thumbnail;
            }else{
                ECGImageRef cgimage;
                cgimage = (__bridge_retained CGImageRef)thumbnail;
                image = [[NSImage alloc] initWithCGImage:cgimage size:NSMakeSize(thumbnailSize, thumbnailSize)];
            }
            NSData* data = [image TIFFRepresentation];
            NSBitmapImageRep* tiffRep = [NSBitmapImageRep imageRepWithData:data];
            NSDictionary* option = @{NSImageCompressionFactor: @0.7};
            NSData* jpegData = [tiffRep representationUsingType:NSJPEGFileType properties:option];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[DVRemoteServer sharedServer] sendThumbnail:jpegData forNodeID:pathID inDocument:documentName];
            });
        });
    }
}

//-----------------------------------------------------------------------------------------
// コンパニオンアプリへフルイメージを送信
//-----------------------------------------------------------------------------------------
- (void)sendFullImage:(NSArray *)nodeId withSize:(CGFloat)maxSize
{
    NSString* documentName = self.fileURL.path;
    PathNode* currentNode = [root nearestNodeAtPortablePath:nodeId];
    NSString* imagePath = currentNode.imagePath;

    dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(que, ^(void){
        ImageRenderer* renderer = [ImageRenderer imageRendererWithPath: imagePath];
        NSInteger rotation = renderer.rotation;
        NSImage* image;
        id fullImage = renderer.image;
        if ([fullImage isKindOfClass:[NSImage class]]){
            image = fullImage;
        }else{
            ECGImageRef cgimage;
            cgimage = (__bridge_retained CGImageRef)fullImage;
            image = [[NSImage alloc] initWithCGImage:cgimage size:NSMakeSize(maxSize, maxSize)];
        }

        NSData* data = [image TIFFRepresentation];
        NSBitmapImageRep* tiffRep = [NSBitmapImageRep imageRepWithData:data];
        NSDictionary* option = @{NSImageCompressionFactor: @0.7};
        NSData* jpegData = [tiffRep representationUsingType:NSJPEGFileType properties:option];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[DVRemoteServer sharedServer] sendFullimage:jpegData forNodeID:nodeId inDocument:documentName
                                            withRotation:rotation];
        });
    });
}

@end
