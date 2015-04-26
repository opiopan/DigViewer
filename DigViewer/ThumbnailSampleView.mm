//
//  ThumbnailSampleView.m
//  DigViewer
//
//  Created by opiopan on 2015/04/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ThumbnailSampleView.h"
#include "CoreFoundationHelper.h"


@implementation ThumbnailSampleView

- (id) init
{
    self = [super init];
    if (self){
        _imageSize = 0;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if (_image && _imageSize > 0){
        NSRect boundsRect = self.bounds;
        CGFloat imageWidth = CGImageGetWidth(_image);
        CGFloat imageHeight = CGImageGetHeight(_image);
        CGFloat ratio = _imageSize / MAX(imageWidth, imageHeight);
        CGFloat xOffset = (boundsRect.size.width - imageWidth * ratio) / 2.;
        CGFloat yOffset = (boundsRect.size.height - imageHeight * ratio) / 2.;
        
        CGContextRef context = reinterpret_cast<CGContext*>([[NSGraphicsContext currentContext] graphicsPort]);

        CGContextTranslateCTM (context, xOffset, yOffset);
        CGContextScaleCTM(context, ratio, ratio);
        CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), _image);
    }
}

- (void)setImage:(CGImageRef)image
{
    if (_image){
        CGImageRelease(_image);
    }
    _image = image;
    CGImageRetain(_image);
    [self display];
}

- (void)setImageSize:(double)imageSize
{
    _imageSize = imageSize;
    [self display];
}

@end
