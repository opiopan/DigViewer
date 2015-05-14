//
//  DocumentWindowController.m
//  DigViewer
//
//  Created by opiopan on 2014/02/08.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "DocumentWindowController.h"
#import "Document.h"
#import "DocumentConfigController.h"
#import "SlideshowConfigController.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"

//-----------------------------------------------------------------------------------------
// RepresentedObject: 子ビューコントローラの代表オブジェクト用プレースホルダ
//-----------------------------------------------------------------------------------------
@interface RepresentedObject : NSObject
@property (weak) Document* document;
@property (weak) DocumentWindowController* controller;
+ representedObjectWithController:controller;
@end

@implementation RepresentedObject
+ (id)representedObjectWithController:(id)controller
{
    RepresentedObject* object = [[RepresentedObject alloc] init];
    object.controller = controller;
    return object;
}
@end

//-----------------------------------------------------------------------------------------
// DocumentWindowController implementation
//-----------------------------------------------------------------------------------------
@interface DocumentWindowController ()
@end

@implementation DocumentWindowController{
    MainViewController* mainViewController;
    int                 transitionStateCount;
    SlideshowConfigController*  slideshowConfig;
    BOOL                        isInSlideshowMode;
    NSInteger                   slideshowCount;
}
@synthesize selectionIndexPathsForTree = _selectionIndexPathsForTree;

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super initWithWindowNibName:@"Document"];
    if (self) {
        transitionStateCount = 0;
        slideshowConfig = [SlideshowConfigController sharedController];
        isInSlideshowMode = NO;
        slideshowCount = 0;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// Window初期化
//-----------------------------------------------------------------------------------------
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    mainViewController = [[MainViewController alloc] init];
    mainViewController.representedObject = [RepresentedObject representedObjectWithController:self];
    [self.placeHolder associateSubViewWithController:mainViewController];
    [self reflectValueToViewSelectionButton];
    
     // UserDefaultsの変更に対してObserverを登録
    DocumentConfigController* documentConfig = [DocumentConfigController sharedController];
    [documentConfig addObserver:self forKeyPath:@"updateCount" options:nil context:nil];
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller addObserver:self forKeyPath:@"values.pathNodeSortType" options:nil context:nil];
    [controller addObserver:self forKeyPath:@"values.pathNodeSortCaseInsensitive" options:nil context:nil];
    [controller addObserver:self forKeyPath:@"values.pathNodeSortAsNumeric" options:nil context:nil];
    
    // オープン時の表示設定を反映
    self.presentationViewType = [[[controller values] valueForKey:@"defImageViewType"] intValue];
    self.isFitWindow = [[[controller values] valueForKey:@"defFitToWindow"] boolValue];
    self.isCollapsedOutlineView = ![[[controller values] valueForKey:@"defShowNavigator"] boolValue];
    self.isCollapsedInspectorView = ![[[controller values] valueForKey:@"defShowInspector"] boolValue];
    
    // スライドショー状態の初期化
    [self setSlideshowMode:NO];
   
   // ドキュメントロードをスケジュール
    [self.document performSelector:@selector(loadDocument:) withObject:self  afterDelay:0.0f];
}

//-----------------------------------------------------------------------------------------
// Windowクローズ
//-----------------------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)notification
{
    // Observerを削除
    DocumentConfigController* documentConfig = [DocumentConfigController sharedController];
    [documentConfig removeObserver:self forKeyPath:@"updateCount"];
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller removeObserver:self forKeyPath:@"values.pathNodeSortType"];
    
    // ビューコントローラーのクローズ準備
    [mainViewController prepareForClose];
}

//-----------------------------------------------------------------------------------------
// オブザーバー通知
//-----------------------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [DocumentConfigController sharedController]){
        [self.document loadDocument:self];
    }else if ([keyPath isEqualToString:@"values.pathNodeSortType"]){
        PathNode* node = _imageArrayController.selectedObjects.firstObject;
        NSUserDefaultsController* controller = object;
        node.sortType = ((NSNumber*)[controller.values valueForKey:@"pathNodeSortType"]).intValue;
        self.imageArrayController.content = [self.imageTreeController.selection valueForKey:@"images"];
    }else if ([keyPath isEqualToString:@"values.pathNodeSortCaseInsensitive"] ||
              [keyPath isEqualToString:@"values.pathNodeSortAsNumeric"]){
        [self performSelector:@selector(setDocumentData:) withObject:((Document*)self.document).root afterDelay:0.3];
        
    }
}

//-----------------------------------------------------------------------------------------
// ドキュメントデータ設定
//-----------------------------------------------------------------------------------------
- (void)setDocumentData:(PathNode *)root
{
    // ソート設定を最新に更新
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    PathNodeCreateOption option;
    option.isSortByCaseInsensitive = [[controller.values valueForKey:@"pathNodeSortCaseInsensitive"] boolValue];
    option.isSortAsNumeric = [[controller.values valueForKey:@"pathNodeSortAsNumeric"] boolValue];
    if (root.isSortByCaseInsensitive != option.isSortByCaseInsensitive || root.isSortAsNumeric != option.isSortAsNumeric){
        root.isSortByCaseInsensitive = option.isSortByCaseInsensitive;
        root.isSortAsNumeric = option.isSortAsNumeric;
    }
    
    // ドキュメントデータ設定
    NSArray* path = nil;
    if (((Document*)self.document).root){
        PathNode* selectedNode = _imageArrayController.selectedObjects[0];
        path = [selectedNode portablePath];
    }
    if (path){
        [self enterTransitionState];
        ((Document*)self.document).root = root;
        PathNode* selectedNode = [root nearestNodeAtPortablePath:path];
        PathNode* parentNode = selectedNode.parent;
        if (!parentNode){
            parentNode = selectedNode;
            selectedNode = nil;
        }
        NSIndexPath* indexPath = [parentNode indexPath];
        if (selectedNode.indexInParent == 0){
            [self exitTransitionState];
            _imageTreeController.selectionIndexPath = indexPath;
            _imageArrayController.selectionIndex = selectedNode.indexInParent;
        }else{
            _imageTreeController.selectionIndexPath = indexPath;
            _imageArrayController.selectionIndex = 0;
            [self exitTransitionState];
            _imageArrayController.selectionIndex = selectedNode.indexInParent;
        }
    }else{
        ((Document*)self.document).root = root;
    }
}

//-----------------------------------------------------------------------------------------
// ドキュメント再ロード
//-----------------------------------------------------------------------------------------
- (IBAction)refreshDocument:(id)sender {
    [self.document loadDocument:nil];
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
        [self enterTransitionState];
        PathNode* current = [_imageTreeController.selection valueForKey:@"me"];
        if (current != next.parent){
            NSResponder* firstResponder = self.window.firstResponder;
            NSIndexPath* indexPath = [next.parent indexPath];
            [_imageTreeController setSelectionIndexPath:indexPath];
            [self.window makeFirstResponder:firstResponder];
        }
        [self exitTransitionState];
        [_imageArrayController setSelectionIndex:next.indexInParent];
    }
}

- (void)moveToNextFolder:(id)sender
{
    [self moveToFolderNode:[[_imageTreeController selectedObjects][0] nextFolderNode]];
}

- (void)moveToPreviousFolder:(id)sender
{
    [self moveToFolderNode:[[_imageTreeController selectedObjects][0] previousFolderNode]];
}

- (void)moveToFolderNode:(PathNode*)next
{
    if (next){
        NSIndexPath* indexPath = [next indexPath];
        [_imageTreeController setSelectionIndexPath:indexPath];
    }
}

- (void)moveUpFolder:(id)sender
{
    if (self.presentationViewType == typeImageView){
        self.presentationViewType = typeThumbnailView;
    }else{
        PathNode* selected = _imageArrayController.selectedObjects[0];
        PathNode* current = selected.parent;
        PathNode* up = current.parent;
        if (up){
            [self enterTransitionState];
            NSUInteger index = current.indexInParent;
            [_imageTreeController setSelectionIndexPath:up.indexPath];
            [self exitTransitionState];
            [_imageArrayController setSelectionIndex:index];
        }
    }
}

- (void)moveDownFolder:(id)sender
{
    PathNode* selected = _imageArrayController.selectedObjects[0];
    if (selected){
        if (selected.isImage){
            self.presentationViewType = typeImageView;
        }else{
            [_imageTreeController setSelectionIndexPath:selected.indexPath];
        }
    }
}

//-----------------------------------------------------------------------------------------
// 遷移中状態属性
//-----------------------------------------------------------------------------------------
- (BOOL) isInTransitionState
{
    return transitionStateCount != 0;
}

- (void) enterTransitionState
{
    transitionStateCount++;
}

- (void) exitTransitionState
{
    transitionStateCount--;
}


//-----------------------------------------------------------------------------------------
// ビュー選択ボタンと属性の同期
//-----------------------------------------------------------------------------------------
- (IBAction)onViewSelectionButtonDown:(id)sender
{
    BOOL outlineViewState = ![self.viewSelectionButton isSelectedForSegment:0];
    BOOL inspectorViewState = ![self.viewSelectionButton isSelectedForSegment:1];
    self.isCollapsedOutlineView = outlineViewState;
    self.isCollapsedInspectorView = inspectorViewState;
}

- (void)reflectValueToViewSelectionButton
{
    [self.viewSelectionButton setSelected:!mainViewController.isCollapsedOutlineView forSegment:0];
    [self.viewSelectionButton setSelected:!mainViewController.isCollapsedInspectorView forSegment:1];
}

//-----------------------------------------------------------------------------------------
// 選択状態属性
//-----------------------------------------------------------------------------------------
- (NSArray*) selectionIndexPathsForTree
{
    return _selectionIndexPathsForTree;
}

- (void)setSelectionIndexPathsForTree:(NSArray *)indexPath
{
    [self enterTransitionState];
    _selectionIndexPathsForTree = indexPath;
    [self exitTransitionState];
    if (!self.isInTransitionState){
        [_imageArrayController setSelectionIndex:0];
    }
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
    if (type == typeThumbnailView && isInSlideshowMode){
        [self setSlideshowMode:NO];
    }
    mainViewController.presentationViewType = type;
}

- (void) togglePresentationView:(id)sender
{
    self.presentationViewType = self.presentationViewType == typeImageView ? typeThumbnailView : typeImageView;
}

//-----------------------------------------------------------------------------------------
// アウトラインビューの折り畳み属性＆トグル処理(メニューの応答処理)
//-----------------------------------------------------------------------------------------
- (BOOL) isCollapsedOutlineView
{
    return mainViewController.isCollapsedOutlineView;
}

- (void) setIsCollapsedOutlineView:(BOOL)value
{
    mainViewController.isCollapsedOutlineView = value;
    [self reflectValueToViewSelectionButton];
}

- (void) toggleCollapsedOutlineView:(id)sender
{
    self.isCollapsedOutlineView = !self.isCollapsedOutlineView;
}

- (BOOL)validateForToggleCollapsedOutlineView:(NSMenuItem*)menuItem
{
    if (self.isCollapsedOutlineView){
        menuItem.title = NSLocalizedString(@"Show Navigator", nil);
    }else{
        menuItem.title = NSLocalizedString(@"Hide Navigator", nil);
    }
    return YES;
}

//-----------------------------------------------------------------------------------------
// インスペクタービューの折り畳み属性＆トグル処理(メニューの応答処理)
//-----------------------------------------------------------------------------------------
- (BOOL) isCollapsedInspectorView
{
    return mainViewController.isCollapsedInspectorView;
}

- (void) setIsCollapsedInspectorView:(BOOL)value
{
    mainViewController.isCollapsedInspectorView = value;
    [self reflectValueToViewSelectionButton];
}

- (void) toggleCollapsedInspectorView:(id)sender
{
    self.isCollapsedInspectorView = !self.isCollapsedInspectorView;
}

- (BOOL)validateForToggleCollapsedInspectorView:(NSMenuItem*)menuItem
{
    if (self.isCollapsedInspectorView){
        menuItem.title = NSLocalizedString(@"Show Inspector", nil);
    }else{
        menuItem.title = NSLocalizedString(@"Hide Inspector", nil);
    }
    return YES;
}

//-----------------------------------------------------------------------------------------
// イメージの拡大表示のトグル（メニューの応答処理）
//-----------------------------------------------------------------------------------------
- (void)fitImageToScreen:(id)sender
{
    self.isFitWindow = ! self.isFitWindow;
}

- (BOOL)validateForFitImageToScreen:(NSMenuItem*)menuItem
{
    [menuItem setState:self.isFitWindow ? NSOnState : NSOffState];
    return YES;
}

//-----------------------------------------------------------------------------------------
// Preview.appの起動
//-----------------------------------------------------------------------------------------
- (void) launchPreviewApplication:(id)sender
{
    PathNode* current = self.imageArrayController.selectedObjects[0];
    [[NSWorkspace sharedWorkspace] openFile:current.imagePath withApplication:@"Preview.app"];
}

//-----------------------------------------------------------------------------------------
// カーソルキーでのノード移動
//-----------------------------------------------------------------------------------------
- (void)moveRight:(id)sender
{
    [self moveToNextImage:sender];
}

- (void)moveLeft:(id)sender
{
    [self moveToPreviousImage:sender];
}

//-----------------------------------------------------------------------------------------
// スライドショー状態の制御
//-----------------------------------------------------------------------------------------
- (void)setSlideshowMode:(BOOL)slideshowMode
{
    isInSlideshowMode = slideshowMode;
    slideshowCount++;
    if (isInSlideshowMode){
        self.slideshowButtonImage = [[NSBundle mainBundle] imageForResource:@"pause"];
        self.slideshowButtonTooltip = NSLocalizedString(@"SLIDESHOW_TOOLTIP_END", nil);
        if (self.presentationViewType != typeImageView){
            self.presentationViewType = typeImageView;
        }
        [self performSelector:@selector(proceedSlideshow:) withObject:@(slideshowCount)
                   afterDelay:slideshowConfig.interval.doubleValue];
    }else{
        self.slideshowButtonImage = [[NSBundle mainBundle] imageForResource:@"play"];
        self.slideshowButtonTooltip = NSLocalizedString(@"SLIDESHOW_TOOLTIP_BEGIN", nil);
    }
}

- (void)proceedSlideshow:(NSNumber*)count
{
    if (count.integerValue == slideshowCount){
        [self performSelector:@selector(proceedSlideshow:) withObject:@(slideshowCount)
                   afterDelay:slideshowConfig.interval.doubleValue];
        [self moveToNextImage:self];
        PathNode* node = _imageArrayController.selectedObjects[0];
        PathNode* nextNode = node.nextImageNode;
        if (!nextNode){
            [self setSlideshowMode:NO];
        }
    }
}

- (void)toggleSlideshowMode:(id)sender
{
    [self setSlideshowMode:!isInSlideshowMode];
}

- (BOOL)validateForToggleSlideshowMode:(NSMenuItem*)menuItem
{
    if (isInSlideshowMode){
        menuItem.title = NSLocalizedString(@"End Slideshow", nil);
    }else{
        menuItem.title = NSLocalizedString(@"Begin Slideshow", nil);
    }
    return YES;
}

@end
