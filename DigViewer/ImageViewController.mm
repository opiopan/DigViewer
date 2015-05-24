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
#include "CoreFoundationHelper.h"

@implementation ImageViewController{
    BOOL _isVisible;
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
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.imageBackgroundColor"
                                                                 options:0 context:nil];
    [self reflectBackgroundColor];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.gestureEnable"
                                                                 options:0 context:nil];
    [self reflectGestureConfig];
    [self.imageArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
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

- (void)prepareForClose
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller removeObserver:self forKeyPath:@"isFitWindow"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.imageBackgroundColor"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.gestureEnable"];
    [self.imageArrayController removeObserver:self forKeyPath:@"selectedObjects"];
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
        if ([NSImage isRawFileAtPath:node.imagePath]){
            NSURL* url = [NSURL fileURLWithPath:node.imagePath];
            ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
            CGImageRef thumbnail(CGImageSourceCreateThumbnailAtIndex(imageSource, 0, NULL));
            if (!thumbnail){
                [imageView setImage:node.image withRotation:1];
            }else{
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                [imageView setImage:(__bridge id)thumbnail withRotation:orientation.integerValue];
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

- (void)reflectBackgroundColor
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSData* data = [[controller values] valueForKey:@"imageBackgroundColor"];
    if (data){
        ClickableImageView* imageView = (ClickableImageView*)self.view;
        imageView.backgroundColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:data];
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
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.imageBackgroundColor"]){
        [self reflectBackgroundColor];
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
