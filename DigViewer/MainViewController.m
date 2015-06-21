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
#import "InspectorViewController.h"
#import "PresentationBaseViewController.h"
#import "NSWindow+TracingResponderChain.h"
#import "FlatSplitView.h"

@implementation MainViewController {
    __weak FlatSplitView*       splitView;
    NSArray*                    contentViewControllers;
    NSViewController*           presentationBaseViewController;
    NSViewController*           outlineViewController;
    InspectorViewController*    inspectorViewController;
    InspectorViewController*    inspectorViewControllerSwapping;
    CGFloat                     outlineViewWidth;
    CGFloat                     inspectorViewWidth;
    CGFloat*                    dividerPosition[2];
    int                         dividerNum;
    BOOL                        isCoordinateFlip[2];
    BOOL                        isCollapsedOutlineView;
    BOOL                        isCollapsedInspectorView;
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
        isCollapsedInspectorView = YES;
        presentationViewType = typeImageView;
        outlineViewWidth = 200;
        inspectorViewWidth = 230;
    }
    return self;
}

- (void)awakeFromNib
{
    splitView = (FlatSplitView*)self.view;
    splitView.delegate = self;
    splitView.cancelOperationSelector = @selector(cancelOperation:);
    
    // サブビュー作成
    outlineViewController = [[FolderOutlineViewController alloc] init];
    outlineViewController.representedObject = self.representedObject;
    inspectorViewController = [[InspectorViewController alloc] init];
    inspectorViewController.representedObject = self.representedObject;
    presentationBaseViewController = [PresentationBaseViewController new];
    presentationBaseViewController.representedObject = self.representedObject;

    contentViewControllers = [NSArray arrayWithObjects:[[ImageViewController alloc] init],
                       [[ThumbnailViewController alloc] init], nil];
    for (int i = 0; i < contentViewControllers.count; i++){
        NSViewController* controller = contentViewControllers[i];
        controller.representedObject = self.representedObject;
    }
    
    
    // Google API Keyの変更を監視するするobserverを登録
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.googleMapsApiKey"
                                                                 options:nil context:nil];

    // サブビューの配置
    [self arrangeSubview];
    [self performSelector:@selector(configureOnInit) withObject:nil afterDelay:0.0];
}

- (void)configureOnInit
{
    [self.view.window makeFirstResponder:representedViewController.representationView];
}

//-----------------------------------------------------------------------------------------
// クローズ(準備)
//-----------------------------------------------------------------------------------------
- (void) prepareForClose
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.googleMapsApiKey"];
    
    [outlineViewController prepareForClose];
    [inspectorViewController prepareForClose];
    for (int i = 0; i < contentViewControllers.count; i++){
        NSViewController* controller = contentViewControllers[i];
        [controller prepareForClose];
    }
}

//-----------------------------------------------------------------------------------------
// サブビューの配置
//-----------------------------------------------------------------------------------------
- (void) arrangeSubview
{
    // 遷移前の状態を保持
    NSResponder* lastResponder = [self.view.window firstResponder];
    BOOL outlineViewBelongToLastResponderChain = [self.view.window isBelongToResponderChain:outlineViewController.view];
    BOOL inspectorViewBelongToLastResponderChain = [self.view.window isBelongToResponderChain:inspectorViewController.view];
    
    // サブビューをSplitViewから除去
    if (outlineViewController.view.superview){
        [outlineViewController.view removeFromSuperview];
        [outlineViewController setIsVisible:NO];
    }
    if (inspectorViewController.view.superview){
        [inspectorViewController.view removeFromSuperview];
        [inspectorViewController setIsVisible:NO];
    }
    for (int i = 0; i < contentViewControllers.count; i++){
        NSViewController* controller = contentViewControllers[i];
        if ([controller.view isBelongToView:self.view]){
            [controller.view removeFromSuperview];
            [controller setIsVisible:NO];
        }
    }
    [presentationBaseViewController.view removeFromSuperview];
    
    // インスペクタビューのスワップ
    if (inspectorViewControllerSwapping){
        inspectorViewControllerSwapping.viewSelector = inspectorViewController.viewSelector;
        [inspectorViewController prepareForClose];
        inspectorViewController = inspectorViewControllerSwapping;
        inspectorViewControllerSwapping = nil;
        inspectorViewBelongToLastResponderChain = false;
    }

    // 必要なサブビューをSplitViewに追加
    int currentViewIndex = 0;
    dividerNum = 0;
    if (!self.isCollapsedOutlineView){
        [splitView addSubview:outlineViewController.view];
        [splitView setHoldingPriority: NSLayoutPriorityDefaultLow forSubviewAtIndex:currentViewIndex];
        dividerPosition[dividerNum] = &outlineViewWidth;
        isCoordinateFlip[dividerNum] = NO;
        dividerNum++;
        currentViewIndex++;
        [outlineViewController setIsVisible:YES];
    }
    [splitView addSubview:presentationBaseViewController.view];
    [splitView setHoldingPriority: NSLayoutPriorityFittingSizeCompression forSubviewAtIndex:currentViewIndex];
    currentViewIndex++;
    [representedViewController setIsVisible:YES];
    [presentationBaseViewController.view associateSubViewWithController:representedViewController];
    if (!self.isCollapsedInspectorView){
        [splitView addSubview:inspectorViewController.view];
        [splitView setHoldingPriority:NSLayoutPriorityDefaultLow forSubviewAtIndex:currentViewIndex];
        dividerPosition[dividerNum] = &inspectorViewWidth;
        isCoordinateFlip[dividerNum] = YES;
        dividerNum++;
        currentViewIndex++;
        [inspectorViewController setIsVisible:YES];
    }

    // divider位置を設定
    //   なぜ2回設定しなければいけないのか?
    //   ・NSSplitViewのdividerの座標系は摩訶不思議
    //   ・サブビューの数でスケール変わる、divider position設定でもスケール変わる場合あり
    //   ・特にサブビュー追加直後のposition設定で移動するため、意図した位置にdividerを設置するためには2回同じ設定が必要であった
    for (int i = 0; i < 2; i++){
    int dividerIndex = dividerNum - 1;
    CGFloat frameWidth = splitView.frame.size.width;
        if (!self.isCollapsedInspectorView){
            CGFloat dividerMax = [splitView maxPossiblePositionOfDividerAtIndex:dividerNum - 1];
            [splitView setPosition:(frameWidth - inspectorViewWidth) * dividerMax / frameWidth ofDividerAtIndex:dividerIndex];
            dividerIndex--;
        }
        if (!self.isCollapsedOutlineView){
            CGFloat dividerMax = [splitView maxPossiblePositionOfDividerAtIndex:dividerNum - 1];
            [splitView setPosition:outlineViewWidth* dividerMax / frameWidth ofDividerAtIndex:dividerIndex];
        }
    }
    
    // キービューループの再計算とfirst responderの設定
    [self.view.window recalculateKeyViewLoop];
    if ((outlineViewBelongToLastResponderChain && !self.isCollapsedOutlineView) ||
        (inspectorViewBelongToLastResponderChain && !self.isCollapsedInspectorView)){
        [self.view.window makeFirstResponder:lastResponder];
    }else{
        [self.view.window makeFirstResponder:representedViewController.representationView];
    }
}

//-----------------------------------------------------------------------------------------
// divider移動通知
//-----------------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)view constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
    CGFloat frameWidth = view.frame.size.width;
    CGFloat dividerMax = [view maxPossiblePositionOfDividerAtIndex:dividerNum - 1];
    if (isCoordinateFlip[dividerIndex]){
        *dividerPosition[dividerIndex] = (dividerMax - proposedPosition) * frameWidth / dividerMax;
    }else{
        *dividerPosition[dividerIndex] = proposedPosition * frameWidth / dividerMax;
    }
    return proposedPosition;
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
// プレゼンテーションビューコントローラー属性
//-----------------------------------------------------------------------------------------
- (NSViewController *)presentationViewController
{
    return contentViewControllers[presentationViewType];
}

- (NSViewController *)imageViewController
{
    return contentViewControllers[typeImageView];
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

//-----------------------------------------------------------------------------------------
// インスペクタービューの折り畳み属性
//-----------------------------------------------------------------------------------------
- (BOOL) isCollapsedInspectorView
{
    return isCollapsedInspectorView;
}

- (void) setIsCollapsedInspectorView:(BOOL)value
{
    isCollapsedInspectorView = value;
    [self arrangeSubview];
}

//-----------------------------------------------------------------------------------------
// オブザーバー応答
// ・Google Maps APIキーが変更された際の処理
//-----------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.googleMapsApiKey"]){
        [self reflectGoogleMapsApiKey];
    }
}

- (void)reflectGoogleMapsApiKey
{
    inspectorViewControllerSwapping = [[InspectorViewController alloc] init];
    inspectorViewControllerSwapping.representedObject = self.representedObject;
    [self arrangeSubview];
}

//-----------------------------------------------------------------------------------------
// escボタン処理
//-----------------------------------------------------------------------------------------
- (void)cancelOperation:(id)sender
{
    [self.view.window.windowController performSelector:@selector(cancelOperation:) withObject:sender];
}

@end
