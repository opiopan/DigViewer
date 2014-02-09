//
//  Document.m
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import "Document.h"
#import "DocumentWindowController.h"
#import "LoadingSheetController.h"

//-----------------------------------------------------------------------------------------
// UserDefaultsForModel:
// ・ Model (PathNodeグラフ)の構造に影響するUser Defaultsを抽象化するクラス
//-----------------------------------------------------------------------------------------
enum ImageSetType {imageSetTypeALL = 0, imageSetTypeExceptRaw, imageSetTypeSmall, imageSetTypeAll};
@interface UserDefaultsForModel : NSObject
@property (assign) enum ImageSetType type;
@property (strong) PathNodeOmmitingCondition* condition;
@end

@implementation UserDefaultsForModel
static NSDictionary* rawSuffixes = nil;

- (id)init
{
    if (!rawSuffixes){
        rawSuffixes = @{
                        @"cr2":@"raw",
                        @"dng":@"raw",
                        @"nef":@"raw",
                        @"orf":@"raw",
                        @"dcr":@"raw",
                        @"raf":@"raw",
                        @"mrw":@"raw",
                        @"mos":@"raw",
                        @"raw":@"raw",
                        @"pef":@"raw",
                        @"srf":@"raw",
                        @"x3f":@"raw",
                        @"erf":@"raw",
                        @"sr2":@"raw",
                        @"kdc":@"raw",
                        @"mfw":@"raw",
                        @"mef":@"raw",
                        @"are":@"raw",
                        @"rw2":@"raw",
                        @"rwl":@"raw",
                        @"psd":@"cpx",
                        @"tif":@"cpx", @"tiff":@"cpx"};
    }
    self = [super init];
    if (self){
        _condition = [[PathNodeOmmitingCondition alloc] init];
        NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
        _type = ((NSNumber*)[[controller values] valueForKey:@"imageSetType"]).intValue;
        if (_type == imageSetTypeExceptRaw){
            _condition.suffixes = rawSuffixes;
        }
    }
    return self;
}

- (BOOL) isEqual:(id)object
{
    if (![[object class] isSubclassOfClass:[self class]]){
        return NO;
    }
    UserDefaultsForModel* o = object;
    if (self->_type != o->_type){
        return NO;
    }
    return YES;
}

@end

//-----------------------------------------------------------------------------------------
// Document class implementation
//-----------------------------------------------------------------------------------------
@implementation Document{
    LoadingSheetController* loader;
    UserDefaultsForModel* modelOption;
    UserDefaultsForModel* loadingModelOption;
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
    UserDefaultsForModel* option = [[UserDefaultsForModel alloc] init];
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
        self.root = node;
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
