//
//  ImageViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ImageViewController.h"
#import "ClickableImageView.h"
#import "MainViewController.h"
#import "DocumentWindowController.h"
#import "NSImage+CapabilityDetermining.h"
#include "CoreFoundationHelper.h"

@implementation ImageViewController

- (id)init
{
    self = [super initWithNibName:@"ImageView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.delegate = self;
    [self performSelector:@selector(reflectImageScaling) withObject:nil afterDelay:0.0f];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller addObserver:self forKeyPath:@"isFitWindow" options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.imageBackgroundColor"
                                                                 options:nil context:nil];
    [self reflectBackgroundColor];
    [self.imageArrayController addObserver:self forKeyPath:@"selectedObjects" options:nil context:nil];
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
                imageView.image = node.image;
                [imageView setCGImage:NULL withRotation:0];                
            }else{
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                imageView.image = nil;
                [imageView setCGImage:thumbnail withRotation:orientation.integerValue];
            }
        }else{
            imageView.image = node.image;
            [imageView setCGImage:NULL withRotation:0];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    if (object == controller && [keyPath isEqualToString:@"isFitWindow"]){
        ClickableImageView* imageView = (ClickableImageView*)self.view;
        imageView.imageScaling = (controller.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.imageBackgroundColor"]){
        [self reflectBackgroundColor];
    }else if (object == self.imageArrayController && [keyPath isEqualToString:@"selectedObjects"]){
        [self reflectImage];
    }
}

- (void)onDoubleClickableImageView:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    controller.presentationViewType = typeThumbnailView;
}

@end
