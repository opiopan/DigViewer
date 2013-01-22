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
#import "Document.h"

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
    [self performSelector:@selector(updateRepresentationObject) withObject:nil afterDelay:0.0f];
}

- (void)updateRepresentationObject
{
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    Document* document = self.representedObject;
    imageView.imageScaling = (document.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
}

- (void)onDoubleClickableImageView:(id)sender
{
    Document* document = self.representedObject;
    document.presentationViewType = typeThumbnailView;
}

@end
