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
}

- (void)reflectImageScaling
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.imageScaling = (controller.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    if (object == controller && [keyPath isEqualToString:@"isFitWindow"]){
        ClickableImageView* imageView = (ClickableImageView*)self.view;
        imageView.imageScaling = (controller.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
    }
}

- (void)onDoubleClickableImageView:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    controller.presentationViewType = typeThumbnailView;
}

@end
