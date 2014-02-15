//
//  MainViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "MainViewController.h"
#import "NSView+ViewControllerAssociation.h"
#import "NSViewController+Nested.h"
#import "FolderOutlineViewController.h"
#import "ImageViewController.h"
#import "ThumbnailViewController.h"
#import "NSWindow+TracingResponderChain.h"

@implementation MainViewController {
    __weak NSSplitView* splitView;
    NSArray*            contentViewControllers;
    NSViewController*   outlineViewController;
    BOOL                isCollapsedOutlineView;
}

@synthesize presentationViewType;

#define representedViewController ((NSViewController*)contentViewControllers[self.presentationViewType])

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super initWithNibName:@"MainView" bundle:nil];
    if (self){
        isCollapsedOutlineView = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    splitView = (NSSplitView*)self.view;
    
    outlineViewController = [[FolderOutlineViewController alloc] init];
    outlineViewController.representedObject = self.representedObject;

    contentViewControllers = [NSArray arrayWithObjects:[[ImageViewController alloc] init],
                       [[ThumbnailViewController alloc] init], nil];
    for (int i = 0; i < contentViewControllers.count; i++){
        NSViewController* controller = contentViewControllers[i];
        controller.representedObject = self.representedObject;
    }
    self.presentationViewType = typeImageView;
    [self performSelector:@selector(configureOnInit) withObject:nil afterDelay:0.0];
}

- (void)configureOnInit
{
    [self.view.window makeFirstResponder:representedViewController.representationView];
}

//-----------------------------------------------------------------------------------------
// サビビューの配置
//-----------------------------------------------------------------------------------------
- (void) arrangeSubview
{
    // 遷移前の状態を保持
    NSResponder* lastResponder = [self.view.window firstResponder];
    BOOL outlineViewBelongToLastResponderChain = [self.view.window isBelongToResponderChain:outlineViewController.view];
    
    // サブビューをSplitViewから除去
    if (outlineViewController.view.superview){
        [outlineViewController.view removeFromSuperview];
    }
    for (int i = 0; i < contentViewControllers.count; i++){
        NSViewController* controller = contentViewControllers[i];
        if (controller.view.superview){
            [controller.view removeFromSuperview];
        }
    }

    // 必要なサブビューをSplitViewに追加
    int currentViewIndex = 0;
    if (!self.isCollapsedOutlineView){
        [splitView addSubview:outlineViewController.view];
        [splitView setHoldingPriority: NSLayoutPriorityDefaultLow forSubviewAtIndex:currentViewIndex];
        currentViewIndex++;
    }
    [splitView addSubview:representedViewController.view];
    [splitView setHoldingPriority: NSLayoutPriorityFittingSizeCompression forSubviewAtIndex:currentViewIndex];
    
    // キービューループの再計算とfirst responderの設定
    [self.view.window recalculateKeyViewLoop];
    if (lastResponder && outlineViewBelongToLastResponderChain && !self.isCollapsedOutlineView){
        [self.view.window makeFirstResponder:lastResponder];
    }else{
        [self.view.window makeFirstResponder:representedViewController.representationView];
    }
}

//-----------------------------------------------------------------------------------------
// プレゼンテーション形式属性
//-----------------------------------------------------------------------------------------
- (enum RepresentationViewType) presentationViewType
{
    return presentationViewType;
}

- (void) setPresentationViewType:(enum RepresentationViewType)type
{
    presentationViewType = type;
    [self arrangeSubview];
}

//-----------------------------------------------------------------------------------------
// アウトラインビューの折り畳み属性
//-----------------------------------------------------------------------------------------
- (BOOL) isCollapsedOutlineView
{
    return isCollapsedOutlineView;
}

- (void) setIsCollapsedOutlineView:(BOOL)value
{
    isCollapsedOutlineView = value;
    [self arrangeSubview];
}

@end
