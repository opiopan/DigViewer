//
//  ClickableImageView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ClickableImageView.h"
#import "ImageRenderer.h"
#import "ImageFrameLayer.h"
#import "TwoFingerGestureRecognizer.h"
#include "CoreFoundationHelper.h"

enum PanningMode{
    PanningNone, PanningScroll, PanningSwipe
};

@implementation ClickableImageView{
    ImageRenderer* _renderer;
    NSColor* _backgroundColor;
    CGFloat _scale;
    
    ImageFrameLayer* _frameLayer;
    NSMutableArray* _touchGestureRecognizers;
    enum PanningMode _panningMode;
    NSPoint _panningBaias;
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
    _relationalImageAccessor = [RelationalImageAccessor new];
    
    _panningMode = PanningNone;
    self.isDrawingByLayer = NO;
    
    _touchGestureRecognizers = [NSMutableArray array];
    TwoFingerGestureRecognizer* twoFIngerGestureRecognizer = [TwoFingerGestureRecognizer new];
    twoFIngerGestureRecognizer.view = self;
    twoFIngerGestureRecognizer.magnifyGestureHandler = @selector(handleMagnifyGesture:);
    twoFIngerGestureRecognizer.panGestureHandler = @selector(handleTwoFingerPanGesture:);
    [_touchGestureRecognizers addObject:twoFIngerGestureRecognizer];
    
    _enableGesture = YES;
    
    [self setAcceptsTouchEvents:YES];
}

//-----------------------------------------------------------------------------------------
// レスポンダーチェイン制御
//-----------------------------------------------------------------------------------------
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

//-----------------------------------------------------------------------------------------
// 画像登録
//-----------------------------------------------------------------------------------------
- (void)setRelationalImage:(id)relationalImage
{
    [self cancelGesture];
    if (_isDrawingByLayer || _relationalImage != relationalImage){
        _relationalImage = relationalImage;
        if (_relationalImage){
            _renderer = [ImageRenderer imageRendererWithPath:[_relationalImageAccessor imagePathOfObject:_relationalImage]];
        }else{
            _renderer = [ImageRenderer imageRendererWithPath:nil];
        }
        _scale = 1.0;
        [self displayIfNeeded];
        self.needsDisplay = true;
        if (_isDrawingByLayer){
            _frameLayer.relationalImage = _relationalImage;
        }
    }else{
        self.zoomRatio = 1.0;
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
        _frameLayer.didEndSwipeSelector = @selector(didEndSwipeWithDirection:);
        _frameLayer.bounds = [self bounds];
        _frameLayer.needsDisplayOnBoundsChange = NO;
        _frameLayer.backgroundColor = _backgroundColor.CGColor;
        _frameLayer.isFitFrame = self.imageScaling == NSImageScaleProportionallyDown;
        _frameLayer.magnificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_magnificationFilter];
        _frameLayer.minificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_minificationFilter];
        _frameLayer.relationalImage = _relationalImage;
        [_frameLayer setNeedsDisplay];
        [self setLayer:_frameLayer];
        [self setWantsLayer:YES];
        self.layerUsesCoreImageFilters = YES;
    }else{
        [self setLayer:nil];
        [self setWantsLayer:NO];
        self.layerUsesCoreImageFilters = NO;
        _frameLayer = nil;
    }
    [self display];
}

//-----------------------------------------------------------------------------------------
// 属性設定
//-----------------------------------------------------------------------------------------
- (void)setImageScaling:(NSImageScaling)imageScaling
{
    _imageScaling = imageScaling;
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

- (void)setMagnificationFilter:(ImageViewFilterType)magnificationFilter
{
    _magnificationFilter = magnificationFilter;
    if (_isDrawingByLayer){
        _frameLayer.magnificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_magnificationFilter];
    }
}

- (void)setMinificationFilter:(ImageViewFilterType)minificationFilter
{
    _minificationFilter = minificationFilter;
    if (_isDrawingByLayer){
        _frameLayer.minificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_minificationFilter];
    }
}

- (CGFloat)zoomRatio
{
    return _isDrawingByLayer ? _frameLayer.scale : 1.0;
}

- (void)setZoomRatio:(CGFloat)zoomRatio
{
    if (_isDrawingByLayer){
        _frameLayer.scale = zoomRatio;
    }
}

//-----------------------------------------------------------------------------------------
// ImageViewFilterTypeからCALayerのフィルタータイプへの変換
//-----------------------------------------------------------------------------------------
- (NSString*)CALayerFilterTypeFromImageViewFilterType:(ImageViewFilterType)type
{
    return type == ImageViewFilterBilinear  ? kCAFilterLinear :
           type == ImageViewFilterTrilinear ? kCAFilterTrilinear :
                                              kCAFilterNearest;
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
    if([event clickCount] == 2 && [self.delegate respondsToSelector:@selector(onDoubleClickableImageView:)]) {
        [self.delegate performSelector:@selector(onDoubleClickableImageView:) withObject:self afterDelay:0.0f];
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    // editable = YES時のドロップインを抑止
    return NSDragOperationNone;
}

//-----------------------------------------------------------------------------------------
// タッチイベントをジェスチャーリコグナイザーに回送
//-----------------------------------------------------------------------------------------
- (void)touchesBeganWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesEndedWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

//-----------------------------------------------------------------------------------------
// ジェスチャー処理
//-----------------------------------------------------------------------------------------
static const CGFloat MagnificationGestureScale = 5.0;
static const CGFloat PanningGestureScale = 4.0;
static const CGFloat SwipeGestureScale = 2.5;

- (void)handleMagnifyGesture:(TwoFingerGestureRecognizer*)gesture
{
    if (_isDrawingByLayer && _enableGesture){
        NSPoint pointer = gesture.initialPoint;
        pointer.x -= self.frame.size.width / 2;
        pointer.y -= self.frame.size.height / 2;
        CGPoint origin = _frameLayer.offset;
        origin.x -= pointer.x;
        origin.y -= pointer.y;
        origin.x /= (_frameLayer.scale * _frameLayer.transisionalScale);
        origin.y /= (_frameLayer.scale * _frameLayer.transisionalScale);
        
        CGFloat magnification = gesture.magnification * MagnificationGestureScale;
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
        
        if (gesture.state == TouchGestureStateEnded ||
            gesture.state == TouchGestureStateCanceled ||
            gesture.state == TouchGestureStateFailed){
            [_frameLayer fixScale];
        }
    }
}

- (void)handleTwoFingerPanGesture:(TwoFingerGestureRecognizer*)gesture
{
    if (_isDrawingByLayer && _enableGesture){
        // 二本指ジェスチャー開始時はバイアス値を取得
        if (gesture.state == TouchGestureStateBegan){
            if (_frameLayer.isInSwipeInertiaMode){
                [self cancelGesture];
                return;
            }else{
                _panningBaias = [_frameLayer startPanning];
                if (_panningBaias.x != 0 || _panningBaias.y != 0){
                    _panningMode = PanningScroll;
                }
            }
        }

        // スクロールモード or スワイプモードの決定
        if (_panningMode == PanningNone && (gesture.panningDelta.x != 0 || gesture.panningDelta.y != 0)){
            _panningMode = PanningScroll;
            CGFloat deltaX = gesture.panningDelta.x;
            CGFloat deltaY = gesture.panningDelta.y;
            int borderCondition = _frameLayer.borderCondition;
            if (deltaX < 0 && fabs(deltaX) > fabs(deltaY) && borderCondition & ImageLayerBorderRight){
                _panningMode = PanningSwipe;
                [_frameLayer startSwipeForDirection:RelationalImageNext];
            }else if (deltaX > 0 && fabs(deltaX) > fabs(deltaY) && borderCondition & ImageLayerBorderLeft){
                _panningMode = PanningSwipe;
                [_frameLayer startSwipeForDirection:RelationalImagePrevious];
            }
        }

        // スクロールモード or スワイプモードでの処理
        if (_panningMode == PanningScroll){
            CGPoint offset = gesture.panningDelta;
            offset.x = offset.x * PanningGestureScale + _panningBaias.x;
            offset.y = offset.y * PanningGestureScale + _panningBaias.y;
            
            _frameLayer.transisionalOffset = offset;
        }else if (_panningMode == PanningSwipe){
            _frameLayer.swipeOffset = gesture.normalizedPanningDelta.x * SwipeGestureScale;
        }
        
        // ジェスチャー終了時のクロージング処理
        if (gesture.state == TouchGestureStateEnded ||
            gesture.state == TouchGestureStateCanceled ||
            gesture.state == TouchGestureStateFailed){
            if (_panningMode == PanningScroll){
                CGPoint velocity = gesture.panningVelocity;
                velocity.x *= PanningGestureScale;
                velocity.y *= PanningGestureScale;
                [_frameLayer fixOffsetWithVelocity:velocity];
            }else if (_panningMode == PanningSwipe){
                CGPoint velocity = gesture.normalizedPanningVelocity;
                velocity.x *= SwipeGestureScale;
                [_frameLayer fixSwipeOffsetWithVelocity:velocity.x];
            }
            _panningMode = PanningNone;
        }
    }
}

- (void)cancelGesture
{
    for (TouchGestureRecognizer* recognizer in _touchGestureRecognizers){
        [recognizer cancelGesture];
    }
}

//-----------------------------------------------------------------------------------------
// 次/前画像へのトランジションエフェクト実行
//-----------------------------------------------------------------------------------------
- (void)moveToDirection:(RelationalImageDirection)direction withTransition:(id)transition
{
    if (_isDrawingByLayer){
        [_frameLayer moveToDirection:direction withTransition:transition inScreen:_window.screen];
    }
}

//-----------------------------------------------------------------------------------------
// スワイプによる画像切り替え通知
//-----------------------------------------------------------------------------------------
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)didEndSwipeWithDirection:(NSNumber*)direction
{
    if (_delegate && _notifySwipeSelector){
        [_delegate performSelector:_notifySwipeSelector withObject:@(direction.intValue == RelationalImageNext)];
    }
}
#pragma clang diagnostic pop

//-----------------------------------------------------------------------------------------
// 描画 (Layerモードの場合は本メソッドは呼び出されない)
//-----------------------------------------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect
{
    if (_isDrawingByLayer){
        return;
    }
    
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    if (!_renderer.image){
        return;
    }
    
    if (![[_renderer.image class] isSubclassOfClass:NSImage.class]){
        CGImageRef cgimage = (__bridge CGImageRef)_renderer.image;
        NSInteger rotation = _renderer.rotation;
        NSRect boundsRect = self.bounds;
        CGSize orgSize = CGSizeMake(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
        CGSize imageSize;
        if (rotation >= 5 && rotation <=8){
            imageSize = CGSizeMake(CGImageGetHeight(cgimage), CGImageGetWidth(cgimage));
        }else{
            imageSize = CGSizeMake(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
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
        switch (rotation){
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
        CGContextDrawImage(context, CGRectMake(0, 0, orgSize.width, orgSize.height), cgimage);
    }else{
        NSImage* image = _renderer.image;
        NSRect boundsRect = self.bounds;
        NSSize imageSize = image.size;
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
        
        [image drawInRect:imageRect];
    }
}

@end
