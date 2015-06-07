//
//  ImageRenderer.m
//  DigViewer
//
//  Created by opiopan on 2015/06/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageRenderer.h"
#import "ImageViewConfigController.h"
#import "NSImage+CapabilityDetermining.h"
#include "CoreFoundationHelper.h"

@implementation ImageRenderer{
    BOOL _hasBeenRendered;
    NSImage* _nsimage;
    ECGImageRef _cgimage;
    NSInteger _rotation;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
+ (id)imageRendererWithPath:(NSString *)imagePath
{
    return [[ImageRenderer alloc] initWithPath:imagePath];
}

- (id)initWithPath:(NSString *)imagePath
{
    self = [self init];
    if (self){
        _imagePath = imagePath;
        _hasBeenRendered = NO;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// レンダリング
//-----------------------------------------------------------------------------------------
- (void)render
{
    if (!_hasBeenRendered){
        ImageViewConfigController* imageViewConfig = [ImageViewConfigController sharedController];
        NSURL* url = [NSURL fileURLWithPath:_imagePath];
        if ([NSImage isRawFileAtPath:_imagePath] && imageViewConfig.useEmbeddedThumbnailRAW){
            ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
            CGImageRef thumbnail(CGImageSourceCreateThumbnailAtIndex(imageSource, 0, NULL));
            if (!thumbnail){
                _nsimage = [[NSImage alloc] initWithContentsOfURL:url];
                _rotation = 1;
            }else{
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                _cgimage = thumbnail;
                _rotation = orientation ? orientation.integerValue : 1;
            }
        }else if ([NSImage isRasterImageAtPath:_imagePath]){
            ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
            CGImageRef image(CGImageSourceCreateImageAtIndex(imageSource, 0, NULL));
            if (!image){
                _nsimage = [[NSImage alloc] initWithContentsOfURL:url];
                _rotation = 1;
            }else{
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                _cgimage = image;
                _rotation = orientation ? orientation.integerValue : 1;
            }
        }else{
            _nsimage = [[NSImage alloc] initWithContentsOfURL:url];
            _rotation = 1;
        }
        
        _hasBeenRendered = YES;
    }
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (id)image
{
    if (_imagePath){
        [self render];
        return _nsimage ? _nsimage : (__bridge id)(CGImageRef)_cgimage;
    }else{
        return nil;
    }
}

- (NSInteger)rotation
{
    if (_imagePath){
        [self render];
        return _rotation;
    }else{
        return 1;
    }
}

@end
