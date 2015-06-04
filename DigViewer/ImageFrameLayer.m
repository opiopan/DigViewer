//
//  ImageFrameLayer.m
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageFrameLayer.h"
#import "ImageLayer.h"

@implementation ImageFrameLayer{
    ImageLayer* _currentImage;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _currentImage = [ImageLayer layer];
        [self addSublayer:_currentImage];
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
    [_currentImage setFrame:frame];
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// カレントイメージレイヤへのルーティング
//-----------------------------------------------------------------------------------------
- (void)setImage:(id)image withRotation:(NSInteger)rotation
{
    [_currentImage setImage:image withRotation:rotation];
}

- (void)setIsFitFrame:(BOOL)isFitFrame
{
    _isFitFrame = isFitFrame;
    _currentImage.isFitFrame = _isFitFrame;
}

- (void)setBackgroundColor:(CGColorRef)backgroundColor
{
    _currentImage.backgroundColor = backgroundColor;
}

- (CGFloat)scale
{
    return _currentImage.scale;
}

- (CGFloat)transisionalScale
{
    return _currentImage.transisionalScale;
}

- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset
{
    [_currentImage setTransisionalScale:transisionalScale withOffset:offset];
}

- (void)fixScale
{
    [_currentImage fixScale];
}

- (CGPoint)startPanning
{
    return [_currentImage startPanning];
}

- (CGPoint)transisionalOffset
{
    return [_currentImage transisionalOffset];
}

- (void)setTransisionalOffset:(CGPoint)offset
{
    [_currentImage setTransisionalOffset:offset];
}

- (void)fixOffsetWithVelocity:(CGPoint)velocity
{
    [_currentImage fixOffsetWithVelocity:velocity];
}

- (CGPoint)offset
{
    return _currentImage.offset;
}

- (void)setOffset:(CGPoint)offset
{
    _currentImage.offset = offset;
}

//-----------------------------------------------------------------------------------------
// 拡大・縮小フィルター
//-----------------------------------------------------------------------------------------
- (void)setMagnificationFilter:(NSString *)magnificationFilter
{
    _currentImage.magnificationFilter = magnificationFilter;
}

- (void)setMinificationFilter:(NSString *)minificationFilter
{
    _currentImage.minificationFilter = minificationFilter;
}

@end
