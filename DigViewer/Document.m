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

@end
