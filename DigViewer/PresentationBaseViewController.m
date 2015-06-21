//
//  PresentationBaseViewController.m
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "PresentationBaseViewController.h"
#import "ImageVIewConfigController.h"

@implementation PresentationBaseViewController{
    ImageViewConfigController* _imageViewConfig;
}

- (id)init
{
    self = [super initWithNibName:@"PresentationBaseView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    _imageViewConfig = [ImageViewConfigController sharedController];
    [_imageViewConfig addObserver:self forKeyPath:@"updateCount" options:0 context:nil];
    [self reflectImageViewConfig];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _imageViewConfig){
        [self reflectImageViewConfig];
    }
}

- (void)reflectImageViewConfig
{
    NSBox* box = (NSBox*)self.view;
    if (![box.fillColor isEqual:_imageViewConfig.backgroundColor]){
        box.fillColor = _imageViewConfig.backgroundColor;
    }
}

@end
