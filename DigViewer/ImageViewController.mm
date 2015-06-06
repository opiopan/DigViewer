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
    [self performSelector:@selector(reflectImageScaling) withObject:nil afterDelay:0.0f];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
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

- (void)prepareForClose
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller removeObserver:self forKeyPath:@"isFitWindow"];
    [_imageViewConfig removeObserver:self forKeyPath:@"updateCount"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.gestureEnable"];
    [self.imageArrayController removeObserver:self forKeyPath:@"selectedObjects"];
}

- (void)setIsVisible:(BOOL)isVisible
{
    BOOL lastVisiblility = _isVisible;
    _isVisible = isVisible;
    if (_isVisible && !lastVisiblility){
        [self reflectImage];
    }if (!_isVisible && lastVisiblility){
        ClickableImageView* imageView = (ClickableImageView*)self.view;
        [imageView setImage:nil withRotation:0];
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

- (void)reflectImage
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    if (controller.isInTransitionState){
        return;
    }
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    if (self.imageArrayController.selectedObjects.count){
        PathNode* node = self.imageArrayController.selectedObjects[0];
        if ([NSImage isRawFileAtPath:node.imagePath] && _imageViewConfig.useEmbeddedThumbnailRAW){
            NSURL* url = [NSURL fileURLWithPath:node.imagePath];
            ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
            CGImageRef thumbnail(CGImageSourceCreateThumbnailAtIndex(imageSource, 0, NULL));
            if (!thumbnail){
                [imageView setImage:node.image withRotation:1];
            }else{
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                [imageView setImage:(__bridge id)thumbnail withRotation:orientation ? orientation.integerValue : 1];
            }
        }else if ([NSImage isRasterImageAtPath:node.imagePath]){
                NSURL* url = [NSURL fileURLWithPath:node.imagePath];
                ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
                CGImageRef image(CGImageSourceCreateImageAtIndex(imageSource, 0, NULL));
                if (!image){
                    [imageView setImage:node.image withRotation:1];
                }else{
                    NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                    NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                    [imageView setImage:(__bridge id)image withRotation:orientation ? orientation.integerValue : 1];
                }
        }else{
            [imageView setImage:node.image withRotation:1];
        }
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

@end
