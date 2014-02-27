//
//  ClickableImageView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ClickableImageView.h"
#include "CoreFoundationHelper.h"

@implementation ClickableImageView{
    ECGImageRef _cgimage;
    NSInteger _rotation;
    NSColor* _backgroundColor;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (void)setCGImage:(CGImageRef)cgimage withRotation:(NSInteger)rotation
{
    _cgimage = cgimage;
    _rotation = rotation;
    [self display];
}


- (void)mouseDown:(NSEvent *)theEvent
{
    // editable = YESの場合、NSImageViewはmouseDownでマウスをキャプチャしてしまい
    // mouseUpイベントが到達しないため、オーバライドする
}

- (void)mouseUp:(NSEvent*)event
{
    if([event clickCount] == 2) {
        [self.delegate performSelector:@selector(onDoubleClickableImageView:) withObject:self afterDelay:0.0f];
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    // editable = YES時のドロップインを抑止
    return NSDragOperationNone;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    if (_cgimage){
        NSRect boundsRect = self.bounds;
        CGSize orgSize = CGSizeMake(CGImageGetWidth(_cgimage), CGImageGetHeight(_cgimage));
        CGSize imageSize;
        if (_rotation >= 5 && _rotation <=8){
            imageSize = CGSizeMake(CGImageGetHeight(_cgimage), CGImageGetWidth(_cgimage));
        }else{
            imageSize = CGSizeMake(CGImageGetWidth(_cgimage), CGImageGetHeight(_cgimage));
        }
        CGFloat xRatio = boundsRect.size.width / imageSize.width;
        CGFloat yRatio = boundsRect.size.height / imageSize.height;
        CGFloat ratio;
        if (xRatio >= 1.0 && yRatio >= 1.0 && self.imageScaling == NSImageScaleProportionallyDown){
            ratio = 1.0;
        }else{
            ratio = xRatio > yRatio ? yRatio : xRatio;
        }
        CGFloat xOffset = (boundsRect.size.width - imageSize.width * ratio) / 2;
        CGFloat yOffset = (boundsRect.size.height - imageSize.height * ratio) / 2;
        CGContextRef context = reinterpret_cast<CGContext*>([[NSGraphicsContext currentContext] graphicsPort]);
        switch (_rotation){
            case 1:
            case 2:
                /* no rotation */
                CGContextTranslateCTM (context, xOffset, yOffset);
                break;
            case 5:
            case 8:
                /* 90 degrees rotation */
                CGContextRotateCTM(context, M_PI / 2.);
                CGContextTranslateCTM (context, yOffset, -xOffset - orgSize.height * ratio);
                break;
            case 3:
            case 4:
                /* 180 degrees rotation */
                CGContextRotateCTM(context, -M_PI);
                CGContextTranslateCTM (context, -xOffset - orgSize.width * ratio, -yOffset - orgSize.height * ratio);
                break;
            case 6:
            case 7:
                /* 270 degrees rotation */
                CGContextRotateCTM(context, -M_PI / 2.);
                CGContextTranslateCTM (context,  -yOffset - orgSize.width * ratio, xOffset);
                break;
        }
        CGContextScaleCTM(context, ratio, ratio);
        CGContextDrawImage(context, CGRectMake(0, 0, orgSize.width, orgSize.height), _cgimage);
    }else{
        [super drawRect:dirtyRect];
    }
}

- (NSColor*)backgroundColor
{
    return _backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)value
{
    _backgroundColor = value;
    [self display];
}

@end
