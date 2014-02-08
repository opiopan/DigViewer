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
    [self performSelector:@selector(reflectImageScaling) withObject:nil afterDelay:0.0f];
    Document* document = [self.representedObject valueForKey:@"document"];
    [document addObserver:self forKeyPath:@"isFitWindow" options:nil context:nil];
}

- (void)reflectImageScaling
{
    Document* document = [self.representedObject valueForKey:@"document"];
    ClickableImageView* imageView = (ClickableImageView*)self.view;
    imageView.imageScaling = (document.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    Document* document = [self.representedObject valueForKey:@"document"];
    if (object == document && [keyPath isEqualToString:@"isFitWindow"]){
        ClickableImageView* imageView = (ClickableImageView*)self.view;
        imageView.imageScaling = (document.isFitWindow ? NSImageScaleProportionallyUpOrDown : NSImageScaleProportionallyDown);
    }
}

- (void)onDoubleClickableImageView:(id)sender
{
    Document* document = [self.representedObject valueForKey:@"document"];
    document.presentationViewType = typeThumbnailView;
}

@end
