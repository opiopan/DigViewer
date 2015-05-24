//
//  ClickableImageView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ClickableImageView.h"
#import "ImageFrameLayer.h"
#include "CoreFoundationHelper.h"

@implementation ClickableImageView{
    ECGImageRef _cgimage;
    NSInteger _rotation;
    NSColor* _backgroundColor;
    CGFloat _scale;
    
    ImageFrameLayer* _frameLayer;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

- (void)initialize
{
    self.isDrawingByLayer = NO;
    
    NSMagnificationGestureRecognizer* magnificationRecognizer = [NSMagnificationGestureRecognizer alloc];
    magnificationRecognizer = [magnificationRecognizer initWithTarget:self action:@selector(handleMagnifyGesture:)];
    [self addGestureRecognizer:magnificationRecognizer];
    
    
}

//-----------------------------------------------------------------------------------------
// 画像登録
//-----------------------------------------------------------------------------------------
- (void)setImage:(id)image withRotation:(NSInteger)rotation
{
    if ([image isKindOfClass:[NSImage class]]){
        [super setImage:image];
        _cgimage = nil;
    }else{
        _cgimage = (__bridge CGImageRef)image;
        [super setImage:nil];
    }
    _rotation = rotation;
    _scale = 1.0;
    [self displayIfNeeded];
    self.needsDisplay = true;
    if (_isDrawingByLayer){
        [_frameLayer setImage:image withRotation:rotation];
    }
}

//-----------------------------------------------------------------------------------------
// 描画方法指定
//-----------------------------------------------------------------------------------------
- (void)setIsDrawingByLayer:(BOOL)isDrawingByLayer
{
    _isDrawingByLayer = isDrawingByLayer;
    if (_isDrawingByLayer){
        _frameLayer = [ImageFrameLayer layer];
        _frameLayer.delegate = self;
        _frameLayer.bounds = [self bounds];
        _frameLayer.needsDisplayOnBoundsChange = NO; // リサイズ時に再描画する
        _frameLayer.backgroundColor = _backgroundColor.CGColor;
        _frameLayer.isFitFrame = self.imageScaling == NSImageScaleProportionallyDown;
        [_frameLayer setImage:_cgimage ? (__bridge id)(CGImageRef)_cgimage : self.image withRotation:_rotation];
        [_frameLayer setNeedsDisplay];
        [self setLayer:_frameLayer];
        [self setWantsLayer:YES];
    }else{
        [self setLayer:nil];
        [self setWantsLayer:NO];
        _frameLayer = nil;
    }
    [self display];
}

//-----------------------------------------------------------------------------------------
// 属性設定
//-----------------------------------------------------------------------------------------
- (void)setImageScaling:(NSImageScaling)imageScaling
{
    [super setImageScaling:imageScaling];
    if (_isDrawingByLayer){
        _frameLayer.isFitFrame = self.imageScaling == NSImageScaleProportionallyDown;
    }
}

- (void)setBackgroundColor:(NSColor *)value
{
    _backgroundColor = value;
    if (_isDrawingByLayer){
        _frameLayer.backgroundColor = _backgroundColor.CGColor;
    }
    [self display];
}

//-----------------------------------------------------------------------------------------
// イベント処理
//-----------------------------------------------------------------------------------------
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

//-----------------------------------------------------------------------------------------
// ジェスチャー処理
//-----------------------------------------------------------------------------------------
- (void)handleMagnifyGesture:(NSMagnificationGestureRecognizer*)gesture
{
    if (_isDrawingByLayer){
        NSPoint pointer = [gesture locationInView:self];
        pointer.x -= self.frame.size.width / 2;
        pointer.y -= self.frame.size.height / 2;
        CGPoint origin = _frameLayer.offset;
        origin.x -= pointer.x;
        origin.y -= pointer.y;
        origin.x /= (_frameLayer.scale * _frameLayer.transisionalScale);
        origin.y /= (_frameLayer.scale * _frameLayer.transisionalScale);
        
        CGFloat magnification = gesture.magnification * 2;
        CGFloat transisionalScale;
        if (magnification > 0){
            transisionalScale = (1.0 + magnification);
        }else{
            transisionalScale = 1.0 / (1  - magnification);
        }
        if (transisionalScale * _frameLayer.scale < 1.0){
            CGFloat compensatedScale = (transisionalScale * _frameLayer.scale - 1.0) * 0.25 + 1.0;
            transisionalScale = compensatedScale / _frameLayer.scale;
        }
        
        origin.x *= (_frameLayer.scale * transisionalScale);
        origin.y *= (_frameLayer.scale * transisionalScale);
        origin.x += pointer.x;
        origin.y += pointer.y;
        
        [_frameLayer setTransisionalScale:transisionalScale withOffset:origin];
        
        if (gesture.state == NSGestureRecognizerStateEnded ||
            gesture.state == NSGestureRecognizerStateCancelled ||
            gesture.state == NSGestureRecognizerStateFailed){
            [_frameLayer fixScale];
        }
    }
}

//-----------------------------------------------------------------------------------------
// 描画
//-----------------------------------------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect
{
    if (_isDrawingByLayer){
        return;
    }
    
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
        NSRect boundsRect = self.bounds;
        NSSize imageSize = self.image.size;
        CGFloat xRatio = boundsRect.size.width / imageSize.width;
        CGFloat yRatio = boundsRect.size.height / imageSize.height;
        CGFloat ratio;
        if (xRatio >= 1.0 && yRatio >= 1.0 && self.imageScaling == NSImageScaleProportionallyDown){
            ratio = 1.0;
        }else{
            ratio = xRatio > yRatio ? yRatio : xRatio;
        }
        NSRect imageRect;
        imageRect.size.width = imageSize.width * ratio;
        imageRect.size.height = imageSize.height * ratio;
        imageRect.origin.x = boundsRect.origin.x + (boundsRect.size.width - imageRect.size.width) / 2;
        imageRect.origin.y = boundsRect.origin.y + (boundsRect.size.height - imageRect.size.height) / 2;
        
        [self.image drawInRect:imageRect];
    }
}

@end
