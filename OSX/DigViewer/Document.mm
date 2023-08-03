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
#import "ThumbnailCache.h"

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
        _thumbnailCacheCounter = 0;
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
    [loader loadPath:[self.fileURL path] ofType:self.fileType forWindow:self.windowForSheet modalDelegate:self
      didEndSelector:@selector(didEndLoadingDocument:) condition:loadingModelOption.condition];
}

- (void)didEndLoadingDocument:(PathNode*)node
{
    if (node){
        modelOption = loadingModelOption;
        _thumnailCache = [ThumbnailCache new];
        [node setThumbnailCache:_thumnailCache withDocument:self];
        [windowController setDocumentData:node];
    }else{
        if (!root){
            [self.windowForSheet close];
        }
    }
    [loader cleanupSheet];
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
- (void)sendThumbnail:(NSArray *)pathID
{
    NSString* documentName = self.fileURL.path;
    dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    PathNode* currentNode = [root nearestNodeAtPortablePath:pathID];
    dispatch_async(que, ^(void){
        NSImage* image;
        id thumbnail = [currentNode.imageNode thumbnailImage:thumbnailSize];
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
        NSData* jpegData = [tiffRep representationUsingType:NSBitmapImageFileTypeJPEG properties:option];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[DVRemoteServer sharedServer] sendThumbnail:jpegData forNodeID:pathID
                                              inDocument:documentName withIndex:currentNode.indexInParent];
        });
    });
}

//-----------------------------------------------------------------------------------------
// コンパニオンアプリへフルイメージを送信
//-----------------------------------------------------------------------------------------
- (void)sendFullImage:(NSArray *)nodeId withSize:(CGFloat)maxSize
{
    NSString* documentName = self.fileURL.path;
    PathNode* currentNode = [root nearestNodeAtPortablePath:nodeId];
    NSString* imagePath = currentNode.imagePath;
    BOOL isPhotosLibraryImage = currentNode.isPhotosLibraryImage;

    dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(que, ^(void){
        ImageRenderer* renderer = [ImageRenderer imageRendererWithPath: imagePath isPhotosLibraryImage:isPhotosLibraryImage];
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
        NSData* jpegData = [tiffRep representationUsingType:NSBitmapImageFileTypeJPEG properties:option];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[DVRemoteServer sharedServer] sendFullimage:jpegData forNodeID:nodeId inDocument:documentName
                                            withRotation:rotation];
        });
    });
}

//-----------------------------------------------------------------------------------------
// コンパニオンアプリへディレクトリ内のノード一覧を送信
//-----------------------------------------------------------------------------------------
- (void)sendNodeListInFolder:(NSArray*)nodeId bySession:(DVRemoteSession *)session
{
    NSString* documentName = self.fileURL.path;
    PathNode* currentNode = [root nearestNodeAtPortablePath:nodeId];
    NSArray* path = [currentNode portablePath];
    dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(que, ^(void){
        NSMutableArray* list = [NSMutableArray array];
        for (PathNode* node in currentNode.images){
            NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
            NSString* type;
            if (node.isImage){
                if (node.isPhotosLibraryImage){
                    type = NSLocalizedString(@"MISC_PHOTOS_LIBRARY_IMAGE", nil);
                }else{
                    NSError* error;
                    type = [workspace localizedDescriptionForType:[workspace typeOfFile:node.imagePath error:&error]];
                }
            }else{
                type = [workspace localizedDescriptionForType:@"public.folder"];
            }
            NSDictionary* nodeAttrs = @{DVRCNMETA_ITEM_NAME: node.name,
                                        DVRCNMETA_ITEM_TYPE: type,
                                        DVRCNMETA_ITEM_IS_FOLDER: @(!node.isImage)};
            [list addObject:nodeAttrs];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[DVRemoteServer sharedServer] sendFolderItems:list forNodeID:path inDocument:documentName bySession:session];
        });
    });
}

//-----------------------------------------------------------------------------------------
// update counter for thumbnail cache
//    Update the property that has been provided to allow other view controllers
//    to observe the state changes of an asynchronously rendered thumbnail image pool
//    using KVO
//-----------------------------------------------------------------------------------------
- (void)updateThumbnailCacheCounter
{
    [self willChangeValueForKey:@"thumbnailCacheCounter"];
    _thumbnailCacheCounter++;
    [self didChangeValueForKey:@"thumbnailCacheCounter"];
}

@end
