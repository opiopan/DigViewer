//
//  DocumentWindowController.m
//  DigViewer
//
//  Created by opiopan on 2014/02/08.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "DocumentWindowController.h"
#import "Document.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"
#import "ChildProcess.h"

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
}
@synthesize selectionIndexPathsForTree = _selectionIndexPathsForTree;

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super initWithWindowNibName:@"Document"];
    if (self) {
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

    // UserDefaultsの変更に対してObserverを登録
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller addObserver:self forKeyPath:@"values.imageSetType" options:nil context:nil];
    
    // ドキュメントロードをスケジュール
    [self.document performSelector:@selector(loadDocument:) withObject:self  afterDelay:0.0f];
}

//-----------------------------------------------------------------------------------------
// Windowクローズ
//-----------------------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)notification
{
    // Observerを削除
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller removeObserver:self forKeyPath:@"values.imageSetType"];
}

//-----------------------------------------------------------------------------------------
// オブザーバー通知
//-----------------------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"values.imageSetType"]){
        [self.document loadDocument:self];
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
        PathNode* current = [_imageArrayController selectedObjects][0];
        if (current.parent != next.parent){
            NSIndexPath* indexPath = [next.parent indexPath];
            [_imageTreeController setSelectionIndexPath:indexPath];
        }
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
            NSUInteger index = current.indexInParent;
            [_imageTreeController setSelectionIndexPath:up.indexPath];
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
// 選択状態属性
//-----------------------------------------------------------------------------------------
- (NSArray*) selectionIndexPathsForTree
{
    return _selectionIndexPathsForTree;
}

- (void)setSelectionIndexPathsForTree:(NSArray *)indexPath
{
    _selectionIndexPathsForTree = indexPath;
    [_imageArrayController setSelectionIndex:0];
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
// アウトラインビューの折り畳み属性＆トグル処理(メニューの応答処理)
//-----------------------------------------------------------------------------------------
- (BOOL) isCollapsedOutlineView
{
    return mainViewController.isCollapsedOutlineView;
}

- (void) setIsCollapsedOutlineView:(BOOL)value
{
    mainViewController.isCollapsedOutlineView = value;
}

- (void) toggleCollapsedOutlineView:(id)sender
{
    self.isCollapsedOutlineView = !self.isCollapsedOutlineView;
}

- (BOOL)validateForToggleCollapsedOutlineView:(NSMenuItem*)menuItem
{
    if (self.isCollapsedOutlineView){
        menuItem.title = NSLocalizedString(@"Show Navigation pane", nil);
    }else{
        menuItem.title = NSLocalizedString(@"Hide Navigation pane", nil);
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
    ChildProcess* cmd = [ChildProcess childProcessWithFormat:@"open -a /Applications/Preview.app %@",
                         [ChildProcess escapedString:current.imagePath]];
    [cmd execute];
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

@end
