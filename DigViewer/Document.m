//
//  Document.m
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import "Document.h"
#import "LoadingSheetController.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"

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
    MainViewController* mainViewController;
    UserDefaultsForModel* modelOption;
    UserDefaultsForModel* loadingModelOption;
    BOOL pendingReloadRequest;
}

@synthesize root;
@synthesize selectionIndexPathsForTree;
@synthesize selectionIndexesForImages;
@synthesize isFitWindow;
@synthesize imageTreeController;
@synthesize imageArrayController;

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

- (NSString *)windowNibName
{
    return @"Document";
}

//-----------------------------------------------------------------------------------------
// フレームワークからのドキュメントロード指示
//   ・なにもせずロード完了したように振る舞う
//   ・実際のロード処理はnibのロード完了後バックグラウンドスレッドで実施
//   ・ロード時間が長い場合にハングしたように見えるのを避けるためこのような仕様とした
//-----------------------------------------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    return YES;
}

//-----------------------------------------------------------------------------------------
// Window初期化
//-----------------------------------------------------------------------------------------
- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    mainViewController = [[MainViewController alloc] init];
    mainViewController.representedObject = self;
    [self.placeHolder associateSubViewWithController:mainViewController];
    
    // UserDefaultsの変更に対してObserverを登録
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller addObserver:self forKeyPath:@"values.imageSetType" options:nil context:nil];
    
    // ドキュメントロードをスケジュール
    [self performSelector:@selector(loadDocument:) withObject:self  afterDelay:0.0f];
}

//-----------------------------------------------------------------------------------------
// ドキュメントロード
// 　・senderがselfの場合は初回ロード or Shareed User Defaults ControllerからのKVO通知
//   ・senderがselfでない場合(MainMenuの場合)はメニューからリロードを選択
//-----------------------------------------------------------------------------------------
- (void)loadDocument:(id)sender
{
    if (loader){
        pendingReloadRequest = (sender == self);
        return;
    }
    pendingReloadRequest = NO;
    UserDefaultsForModel* option = [[UserDefaultsForModel alloc] init];
    if (sender == self && [modelOption isEqualTo:option]){
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
        [self loadDocument:self];
    }
}

//-----------------------------------------------------------------------------------------
// オブザーバー通知
//-----------------------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"values.imageSetType"]){
        [self loadDocument:self];
    }
}

//-----------------------------------------------------------------------------------------
// イメージツリー・ウォーキング
//-----------------------------------------------------------------------------------------
- (void)moveToNextImage:(id)sender
{
    [self moveToImageNode:[[self.imageArrayController selectedObjects][0] nextImageNode]];
}

- (void)moveToPreviousImage:(id)sender
{
    [self moveToImageNode:[[self.imageArrayController selectedObjects][0] previousImageNode]];
}

- (void)moveToImageNode:(PathNode*)next
{
    if (next){
        PathNode* current = [imageArrayController selectedObjects][0];
        if (current.parent != next.parent){
            NSIndexPath* indexPath = [next.parent indexPath];
            [imageTreeController setSelectionIndexPath:indexPath];
        }
        [imageArrayController setSelectionIndex:next.indexInParent];
    }
}

- (void)moveToNextFolder:(id)sender
{
    [self moveToFolderNode:[[imageTreeController selectedObjects][0] nextFolderNode]];
}

- (void)moveToPreviousFolder:(id)sender
{
    [self moveToFolderNode:[[imageTreeController selectedObjects][0] previousFolderNode]];
}

- (void)moveToFolderNode:(PathNode*)next
{
    if (next){
        NSIndexPath* indexPath = [next indexPath];
        [imageTreeController setSelectionIndexPath:indexPath];
    }
}

- (void)moveUpFolder:(id)sender
{
    if (self.presentationViewType == typeImageView){
        self.presentationViewType = typeThumbnailView;
    }else{
        PathNode* selected = imageArrayController.selectedObjects[0];
        PathNode* current = selected.parent;
        PathNode* up = current.parent;
        if (up){
            NSUInteger index = current.indexInParent;
            [imageTreeController setSelectionIndexPath:up.indexPath];
            [imageArrayController setSelectionIndex:index];
        }
    }
}

- (void)moveDownFolder:(id)sender
{
    PathNode* selected = imageArrayController.selectedObjects[0];
    if (selected){
        if (selected.isImage){
            self.presentationViewType = typeImageView;
        }else{
            [imageTreeController setSelectionIndexPath:selected.indexPath];
        }
    }
}

//-----------------------------------------------------------------------------------------
// 選択状態属性
//-----------------------------------------------------------------------------------------
- (NSArray*) selectionIndexPathsForTree
{
    return selectionIndexPathsForTree;
}

- (void)setSelectionIndexPathsForTree:(NSArray *)indexPath
{
    selectionIndexPathsForTree = indexPath;
    [imageArrayController setSelectionIndex:0];
}

//-----------------------------------------------------------------------------------------
// 表示形式属性
//-----------------------------------------------------------------------------------------
- (int) presentationViewType
{
    return mainViewController.presentationViewType;
}

- (void) setPresentationViewType:(int)type
{
    mainViewController.presentationViewType = type;
}

- (void) togglePresentationView:(id)sender
{
    self.presentationViewType = self.presentationViewType == typeImageView ? typeThumbnailView : typeImageView;
}

//-----------------------------------------------------------------------------------------
// イメージの拡大表示のトグル（メニューの応答処理）
//-----------------------------------------------------------------------------------------
- (void)fitImageToScreen:(id)sender
{
    self.isFitWindow = ! self.isFitWindow;
    [sender setState:self.isFitWindow ? NSOnState : NSOffState];
}

@end
