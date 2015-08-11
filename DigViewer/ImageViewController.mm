//
//  ImageViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ImageViewController.h"
#import "NSViewController+Nested.h"
#import "ClickableImageView.h"
#import "MainViewController.h"
#import "DocumentWindowController.h"
#import "NSImage+CapabilityDetermining.h"
#import "ImageViewConfigController.h"
#include "CoreFoundationHelper.h"

@implementation ImageViewController{
    BOOL _isVisible;
    ImageViewConfigController* _imageViewConfig;
    BOOL _useEmbeddedThumbnailForRAW;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super initWithNibName:@"ImageView" bundle:nil];
    if (self){
        _isVisible = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.delegate = self;
    imageView.notifySwipeSelector = @selector(onSwipeWithDirection:);
    [self performSelector:@selector(reflectImageScaling) withObject:nil afterDelay:0.0f];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    imageView.menu = controller.contextMenu;
    [controller addObserver:self forKeyPath:@"isFitWindow" options:0 context:nil];
    _imageViewConfig = [ImageViewConfigController sharedController];
    [_imageViewConfig addObserver:self forKeyPath:@"updateCount" options:0 context:nil];
    _useEmbeddedThumbnailForRAW = _imageViewConfig.useEmbeddedThumbnailRAW;
    [self reflectImageViewConfig];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.gestureEnable"
                                                                 options:0 context:nil];
    [self reflectGestureConfig];
    [self.imageArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
}

//-----------------------------------------------------------------------------------------
// クローズ準備
//-----------------------------------------------------------------------------------------
- (void)prepareForClose
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller removeObserver:self forKeyPath:@"isFitWindow"];
    [_imageViewConfig removeObserver:self forKeyPath:@"updateCount"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.gestureEnable"];
    [self.imageArrayController removeObserver:self forKeyPath:@"selectedObjects"];
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setIsVisible:(BOOL)isVisible
{
    BOOL lastVisiblility = _isVisible;
    _isVisible = isVisible;
    if (_isVisible && !lastVisiblility){
        [self reflectImage];
    }
}

- (CGFloat)zoomRatio
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    return imageView.zoomRatio;
}

- (void)setZoomRatio:(CGFloat)zoomRatio
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.zoomRatio = zoomRatio;
}


//-----------------------------------------------------------------------------------------
// キー値監視イベント毎のアップデート処理
//-----------------------------------------------------------------------------------------
- (void)reflectImage
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    if (controller.isInTransitionState){
        return;
    }
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    if (self.imageArrayController.selectedObjects.count){
        PathNode* node = self.imageArrayController.selectedObjects[0];
        imageView.relationalImage = node;
    }
}

- (void)reflectImageScaling
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.imageScaling = (controller.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
}

- (void)reflectImageViewConfig
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    if (![imageView.backgroundColor isEqualTo:_imageViewConfig.backgroundColor]){
        imageView.backgroundColor = _imageViewConfig.backgroundColor;
    }
    if (imageView.magnificationFilter != _imageViewConfig.magnificationFilter){
        imageView.magnificationFilter = _imageViewConfig.magnificationFilter;
    }
    if (imageView.minificationFilter != _imageViewConfig.minificationFilter){
        imageView.minificationFilter = _imageViewConfig.minificationFilter;
    }
    if (_useEmbeddedThumbnailForRAW != _imageViewConfig.useEmbeddedThumbnailRAW){
        _useEmbeddedThumbnailForRAW = _imageViewConfig.useEmbeddedThumbnailRAW;
        [self reflectImage];
    }
}

- (void)reflectGestureConfig
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.isDrawingByLayer = [[[controller values] valueForKey:@"gestureEnable"] boolValue];
}

//-----------------------------------------------------------------------------------------
// キー値監視
//-----------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    if (object == controller && [keyPath isEqualToString:@"isFitWindow"]){
        ClickableImageView* imageView = (ClickableImageView*)self.view;
        imageView.imageScaling = (controller.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
    }else if (object == [ImageViewConfigController sharedController]){
        [self reflectImageViewConfig];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.gestureEnable"]){
        [self performSelector:@selector(reflectGestureConfig) withObject:nil afterDelay:0.0];
    }else if (object == self.imageArrayController && [keyPath isEqualToString:@"selectedObjects"]){
        if (_isVisible){
            [self reflectImage];
        }
    }
}

- (void)onDoubleClickableImageView:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    controller.presentationViewType = typeThumbnailView;
}

- (void)onSwipeWithDirection:(NSNumber*)direction
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    if (direction.boolValue){
        [controller moveToNextImage:self];
    }else{
        [controller moveToPreviousImage:self];
    }
}

- (void)moveToDirection:(RelationalImageDirection)direction withTransition:(id)transition
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    [imageView moveToDirection:direction withTransition:transition];
}

- (void)beginSlideshow
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.enableGesture = NO;
    imageView.isDrawingByLayer = YES;
    imageView.backgroundColor = [NSColor blackColor];
    imageView.magnificationFilter = ImageViewFilterBilinear;
    imageView.minificationFilter = ImageViewFilterBilinear;
}

- (void)endSlideshow
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.enableGesture = YES;
    [self reflectImageViewConfig];
    [self reflectGestureConfig];
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー処理: コピー
//-----------------------------------------------------------------------------------------
- (void)copy:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    NSArray* items = [[sender parentItem] representedObject];
    [controller copyItems:items];
    [[sender parentItem] setRepresentedObject:nil];
}

- (BOOL)validateForCopy:(NSMenuItem*)menuItem
{
    PathNode* current = _imageArrayController.selectedObjects[0];
    NSArray* items = @[[NSURL fileURLWithPath:current.imagePath]];
    if (items){
        menuItem.representedObject = items;
        return YES;
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー処理: アプリケーションで開く
//-----------------------------------------------------------------------------------------
- (void)performOpenWithApplicationSubMenu:(id)sender
{
}

- (BOOL)validateForPerformOpenWithApplicationSubMenu:(NSMenuItem*)menuItem
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    PathNode* current = _imageArrayController.selectedObjects[0];
    NSArray* items = @[[NSURL fileURLWithPath:current.imagePath]];
    if (items && items.count == 1){
        menuItem.submenu = [controller openWithApplicationMenuForURL:items[0] withTarget:controller
                                                              action:@selector(performOpenWithApplication:)];
        if (menuItem.submenu != nil){
            menuItem.representedObject = items[0];
        }
        return menuItem.submenu != nil;
    }else{
        return NO;
    }
}

//-----------------------------------------------------------------------------------------
// コンテキストメニュー処理: 共有
//-----------------------------------------------------------------------------------------
- (void)performSharingSubMenu:(id)sender
{
}

- (BOOL)validateForPerformSharingSubMenu:(NSMenuItem*)menuItem
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    PathNode* current = _imageArrayController.selectedObjects[0];
    NSArray* items = @[[NSURL fileURLWithPath:current.imagePath]];
    if (items && items > 0){
        menuItem.submenu = [controller sharingMenuForItems:items withTarget:controller
                                                    action:@selector(performSharing:)];
        if (menuItem.submenu != nil){
            menuItem.representedObject = items;
        }
        return menuItem.submenu != nil;
    }else{
        return NO;
    }
}

@end
