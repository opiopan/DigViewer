//
//  ImageLayer.m
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageLayer.h"
#include <sys/time.h>

//-----------------------------------------------------------------------------------------
// μs精度通算秒
//-----------------------------------------------------------------------------------------
static inline NSTimeInterval nowInEpocTime(){
    struct timeval timeval;
    gettimeofday(&timeval, NULL);
    return (double)timeval.tv_sec + (double)timeval.tv_usec / 1000000.0;
}

//-----------------------------------------------------------------------------------------
// ImageLayerクラスの実装
//-----------------------------------------------------------------------------------------
enum _InertiaState{InertiaInrange, InertiaOutrange, InertiaCompensate, InertiaEnd};
typedef enum _InertiaState InertiaState;
struct _InertiaParameter{
    InertiaState state;
    NSTimeInterval phaseTime;
    CGFloat velocity;
};
typedef struct _InertiaParameter InertiaParameter;

@implementation ImageLayer{
    CALayer* _imageLayer;
    CGSize _imageSize;
    NSInteger _rotation;
    CGAffineTransform _transform;
    CGFloat _imageRatio;
    CGSize _normalizedImageSize;

    NSTimer* _timerForPanning;
    NSTimeInterval _lastTimeForPanning;
    InertiaParameter _inertiaX;
    InertiaParameter _inertiaY;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _imageLayer = [CALayer layer];
        [self addSublayer:_imageLayer];
        _imageSize = CGSizeZero;
        _rotation = 1;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// フレームサイズ変更
//-----------------------------------------------------------------------------------------
- (void)setFrame:(CGRect)frame
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [super setFrame:frame];
    [self computeGeometry];
    [self compensateOffsetWithWeight:1.0];
    [self adjustImage];
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// 画像登録
//-----------------------------------------------------------------------------------------
- (void)setImage:(id)image withRotation:(NSInteger)rotation
{
    [_timerForPanning invalidate];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _imageLayer.contents = image;
    _rotation = rotation;
    CGSize size;
    if ([image isKindOfClass:[NSImage class]]){
        NSImage* img = image;
        size.width = img.size.width;
        size.height = img.size.height;
    }else{
        CGImageRef img = (__bridge CGImageRef)image;
        size.width = CGImageGetWidth(img);
        size.height = CGImageGetHeight(img);
    }
    _transform = CGAffineTransformIdentity;
    switch (_rotation){
        case 1:
        case 2:
            /* no rotation */
            _imageSize = size;
            break;
        case 5:
        case 8:
            /* 90 degrees rotation */
            _imageSize.width = size.height;
            _imageSize.height = size.width;
            _transform = CGAffineTransformRotate(_transform, M_PI_2);
            break;
        case 3:
        case 4:
            /* 180 degrees rotation */
            _imageSize = size;
            _transform = CGAffineTransformRotate(_transform, M_PI);
            break;
        case 6:
        case 7:
            /* 270 degrees rotation */
            _imageSize.width = size.height;
            _imageSize.height = size.width;
            _transform = CGAffineTransformRotate(_transform, M_PI_2 * 3);
            break;
    }
    _scale = 1.0;
    _transisionalScale = 1.0;
    _offset = CGPointZero;
    _transisionalOffset = CGPointZero;
    [self computeGeometry];
    [self adjustImage];
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// フィッティング設定
//-----------------------------------------------------------------------------------------
- (void)setIsFitFrame:(BOOL)isFitFrame
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _isFitFrame = isFitFrame;
    _scale = 1.0;
    _transisionalScale = 1.0;
    _offset = CGPointZero;
    [self computeGeometry];
    [self adjustImage];
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// 拡大・縮小制御
//-----------------------------------------------------------------------------------------
- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _transisionalScale = transisionalScale;
    _offset = offset;
    [self adjustImage];
    [CATransaction commit];
}

- (void)fixScale
{
    _scale *= _transisionalScale;
    _transisionalScale = 1.0;
    if (_scale < 1.0){
        _scale = 1.0;
        _offset = CGPointZero;
        [self adjustImage];
    }else{
        CGPoint delta = [self compensateOffsetWithWeight:1.0];
        if (delta.x != 0 || delta.y != 0){
            [self fixOffsetWithVelocity:CGPointZero];
        }
    }
}

//-----------------------------------------------------------------------------------------
// パンニング
//-----------------------------------------------------------------------------------------
static const CGFloat PANNING_FRICTION = 0.90;
static const CGFloat PANNING_FRICTION_AT_END = 0.75;
static const CGFloat PANNING_ATTENUATE_LAG = 0.25;
static const CGFloat PANNING_ATTENUATE_SCALE = 6;
static const CGFloat PANNING_STOP_THRESHOLD = 10;
static const CGFloat PANNING_OUTRANGE_SPRING = 800;
static const CGFloat PANNING_COMPENSATE_VISCOSITY = 110;
static const CGFloat PANNING_COMPENSATE_STOP_THRESHOLD = 1;

- (CGPoint)startPanning
{
    [_timerForPanning invalidate];
    _offset.x += _transisionalOffset.x;
    _offset.y += _transisionalOffset.y;
    _transisionalOffset = CGPointZero;
    
    CGPoint delta = [self compensateOffsetWithWeight:1.0];
    _offset.x += delta.x;
    _offset.y += delta.y;
    
    delta.x /= -(1.0 - PANNING_FRICTION);
    delta.y /= -(1.0 - PANNING_FRICTION);
    
    return delta;
}

- (void)setTransisionalOffset:(CGPoint)offset
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    _transisionalOffset = offset;
    
    CGPoint delta = [self compensateOffsetWithWeight:PANNING_FRICTION];
    _transisionalOffset.x += delta.x;
    _transisionalOffset.y += delta.y;
    [self adjustImage];
    
    [CATransaction commit];
}

- (void)fixOffsetWithVelocity:(CGPoint)velocity
{
    _offset.x += _transisionalOffset.x;
    _offset.y += _transisionalOffset.y;
    _transisionalOffset = CGPointZero;
    CGPoint delta = [self compensateOffsetWithWeight:1.0];

    [_timerForPanning invalidate];
    _lastTimeForPanning = nowInEpocTime();
    _inertiaX.phaseTime = _inertiaY.phaseTime = _lastTimeForPanning;
    if (delta.x == 0){
        _inertiaX.state = InertiaInrange;
        _inertiaX.velocity = velocity.x;
    }else{
        _inertiaX.state = InertiaOutrange;
        _inertiaX.velocity = velocity.x * (1.0 - PANNING_FRICTION_AT_END);
    }
    if (delta.y == 0){
        _inertiaY.state = InertiaInrange;
        _inertiaY.velocity = velocity.y;
    }else{
        _inertiaY.state = InertiaOutrange;
        _inertiaY.velocity = velocity.y * (1.0 - PANNING_FRICTION_AT_END);
    }
    _timerForPanning = [NSTimer scheduledTimerWithTimeInterval:0.002 target:self
                                                      selector:@selector(proceedPanningInertia:)
                                                      userInfo:nil repeats:YES];
}

- (void)proceedPanningInertia:(NSTimer*)timer
{
    NSTimeInterval now = nowInEpocTime();
    NSTimeInterval interval = now - _lastTimeForPanning;
    CGPoint delta = [self compensateOffsetWithWeight:1.0];

    _transisionalOffset.x += [self computeDeltaOfInertia:&_inertiaX atNow:now withInterval:interval delta:delta.x];
    _transisionalOffset.y += [self computeDeltaOfInertia:&_inertiaY atNow:now withInterval:interval delta:delta.y];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [self adjustImage];
    [CATransaction commit];

    _lastTimeForPanning = now;
    
    if (_inertiaX.state == InertiaEnd && _inertiaY.state == InertiaEnd){
        //NSLog(@"inertia end");
        [timer invalidate];
    }
}

- (CGFloat)computeDeltaOfInertia:(InertiaParameter*)inertia atNow:(NSTimeInterval)now
                    withInterval:(NSTimeInterval)interval delta:(CGFloat)delta
{
    NSTimeInterval elapsed = now - inertia->phaseTime;
    double power;
    CGFloat rc = 0;

    switch (inertia->state){
        case InertiaInrange:
            if (elapsed > PANNING_ATTENUATE_LAG){
                power = pow(2, (elapsed - PANNING_ATTENUATE_LAG) * PANNING_ATTENUATE_SCALE);
            }else{
                power = 1.0;
            }
            rc = inertia->velocity * interval / power;
            if (delta != 0){
                inertia->state = InertiaOutrange;
                inertia->phaseTime = now;
                inertia->velocity = rc / interval;
            }else if (fabs(rc / interval) < PANNING_STOP_THRESHOLD){
                rc = 0;
                inertia->state = InertiaEnd;
            }
            break;
        case InertiaOutrange:
            inertia->velocity += delta * PANNING_OUTRANGE_SPRING * interval;
            rc = inertia->velocity * interval;
            if (rc * delta >= 0){
                rc = 0;
                inertia->state = InertiaCompensate;
                inertia->phaseTime = now;
            }
            break;
        case InertiaCompensate:
            inertia->velocity += (delta * PANNING_OUTRANGE_SPRING - inertia->velocity * PANNING_COMPENSATE_VISCOSITY) * interval;
            rc = inertia->velocity * interval;
            if ((delta > 0 && rc > delta) || (delta < 0 && rc < delta) ||
                fabs(delta) < PANNING_COMPENSATE_STOP_THRESHOLD){
                rc = delta;
                inertia->state = InertiaEnd;
            }
            break;
        case InertiaEnd:
            break;
    }
    
    return rc;
}

//-----------------------------------------------------------------------------------------
// 補助ジオメトリ計算
//-----------------------------------------------------------------------------------------
- (void)computeGeometry
{
    if ([_imageLayer contents]){
        CGRect frame = self.frame;
        CGFloat widthRatio = frame.size.width / _imageSize.width;
        CGFloat heightRatio = frame.size.height / _imageSize.height;
        _imageRatio = widthRatio < heightRatio ? widthRatio : heightRatio;
        if (_imageRatio > 1.0 && _isFitFrame){
            _imageRatio = 1.0;
        }
        _normalizedImageSize.width = _imageSize.width * _imageRatio;
        _normalizedImageSize.height = _imageSize.height * _imageRatio;
    }
}

//-----------------------------------------------------------------------------------------
// オフセット位置補正
//-----------------------------------------------------------------------------------------
- (CGPoint)compensateOffsetWithWeight:(CGFloat)weight
{
    if ([_imageLayer contents]){
        CGFloat halfFrameWidth = self.frame.size.width / 2;
        CGFloat halfFrameHeight = self.frame.size.height / 2;
        CGFloat imageWidth = _normalizedImageSize.width;
        CGFloat imageHeight = _normalizedImageSize.height;
        CGFloat limitX = imageWidth * _scale * _transisionalScale > self.frame.size.width ?
                         imageWidth / 2 * _scale * _transisionalScale : halfFrameWidth;
        CGFloat limitY = imageHeight * _scale * _transisionalScale > self.frame.size.height ?
                         imageHeight / 2 * _scale * _transisionalScale : halfFrameHeight;
        CGFloat offsetX = _offset.x + _transisionalOffset.x;
        CGFloat offsetY = _offset.y + _transisionalOffset.y;
        CGFloat deltaX = 0;
        CGFloat deltaY = 0;
        if (offsetX > 0 && offsetX - limitX > -halfFrameWidth){
            deltaX = (limitX - halfFrameWidth - offsetX) * weight;
        }else if (offsetX < 0 && offsetX + limitX < halfFrameWidth){
            deltaX = (halfFrameWidth - limitX - offsetX) * weight;
        }
        if (offsetY > 0 && offsetY - limitY > -halfFrameHeight){
            deltaY = (limitY - halfFrameHeight - offsetY) * weight;
        }else if (offsetY < 0 && offsetY + limitY < halfFrameHeight){
            deltaY = (halfFrameHeight - limitY - offsetY) * weight;
        }

        return CGPointMake(deltaX, deltaY);
    }
    
    return CGPointZero;
}

//-----------------------------------------------------------------------------------------
// イメージレイヤ位置・サイズ & アフィン変換マトリクスの決定
//-----------------------------------------------------------------------------------------
- (void)adjustImage
{
    if ([_imageLayer contents]){

        CGRect imageRect = self.frame;
        CGFloat ratio = _imageRatio * _scale * _transisionalScale;
        imageRect.size.width = _imageSize.width * ratio;
        imageRect.size.height = _imageSize.height * ratio;
        imageRect.origin.x += (self.frame.size.width - imageRect.size.width) / 2 + _offset.x + _transisionalOffset.x;
        imageRect.origin.y += (self.frame.size.height - imageRect.size.height) / 2 + _offset.y + _transisionalOffset.y;
        _imageLayer.affineTransform = _transform;
        _imageLayer.frame = imageRect;
    }
}

@end
