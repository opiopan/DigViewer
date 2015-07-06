//
//  TransitionEffect.m
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TransitionEffect.h"

@implementation TransitionEffect

- (instancetype)init
{
    self = [super init];
    if (self){
        _duration = 0;
    }
    return self;
}

- (void)prepareTransitionOnLayer:(CALayer *)layer
{
}

- (void)performTransition
{
    [self invokeDelegateWhenDidEnd];
}

- (void)cleanUpTransition
{
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)invokeDelegateWhenDidEnd
{
    if (_delegate && _didEndSelector){
        [_delegate performSelector:_didEndSelector withObject:nil];
    }
}
#pragma clang diagnostic pop

- (CGImageRef)CGImageFromLayer:(CALayer *)layer
{
    CGSize imageSize = layer.frame.size;
    imageSize.width *= layer.contentsScale;
    imageSize.height *= layer.contentsScale;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    CGContextRef context = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height,
                                                 8, 4 * imageSize.width, colorSpace,kCGImageAlphaPremultipliedLast);
    if (context){
        CGContextScaleCTM(context, layer.contentsScale, layer.contentsScale);
        [layer renderInContext:context];
        return CGBitmapContextCreateImage(context);
    }else{
        return nil;
    }
}

@end
