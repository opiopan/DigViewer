//
//  ImageLayer.m
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageLayer.h"

@implementation ImageLayer{
    CALayer* _imageLayer;
    CGSize _imageSize;
    NSInteger _rotation;
    CGFloat _imageRatio;
    CGSize _normalizedImageSize;
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
    [self compensateOffset];
    [self adjustImage];
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// 画像登録
//-----------------------------------------------------------------------------------------
- (void)setImage:(id)image withRotation:(NSInteger)rotation
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if ([image isKindOfClass:[NSImage class]]){
        NSImage* img = image;
        _imageSize.width = img.size.width;
        _imageSize.height = img.size.height;
    }else{
        CGImageRef img = (__bridge CGImageRef)image;
        _imageSize.width = CGImageGetWidth(img);
        _imageSize.height = CGImageGetHeight(img);
    }
    _imageLayer.contents = image;
    _rotation = rotation;
    _scale = 1.0;
    _transisionalScale = 1.0;
    _offset = CGPointZero;
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
    }else{
        [self compensateOffset];
    }
    [self adjustImage];
}

//-----------------------------------------------------------------------------------------
// 補助ジオメトリ計算
//-----------------------------------------------------------------------------------------
- (void)computeGeometry
{
    if ([_imageLayer contents]){
        CGRect frame = self.frame;
        CGFloat widthRatio;
        CGFloat heightRatio;
        if (_rotation >= 5 && _rotation <= 8){
            widthRatio = frame.size.width / _imageSize.height;
            heightRatio = frame.size.height / _imageSize.width;
        }else{
            widthRatio = frame.size.width / _imageSize.width;
            heightRatio = frame.size.height / _imageSize.height;
        }
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
- (void)compensateOffset
{
    if ([_imageLayer contents]){
        CGFloat halfFrameWidth = self.frame.size.width / 2;
        CGFloat halfFrameHeight = self.frame.size.height / 2;
        CGFloat limitX = _normalizedImageSize.width * _scale * _transisionalScale > self.frame.size.width ?
                         _normalizedImageSize.width / 2 * _scale * _transisionalScale : halfFrameWidth;
        CGFloat limitY = _normalizedImageSize.height * _scale * _transisionalScale > self.frame.size.height ?
                         _normalizedImageSize.height / 2 * _scale * _transisionalScale : halfFrameHeight;
        if (_offset.x > 0 && _offset.x - limitX > -halfFrameWidth){
            _offset.x = limitX - halfFrameWidth;
        }else if (_offset.x < 0 && _offset.x + limitX < halfFrameWidth){
            _offset.x = halfFrameWidth - limitX;
        }
        if (_offset.y > 0 && _offset.y - limitY > -halfFrameHeight){
            _offset.y = limitY - halfFrameHeight;
        }else if (_offset.y < 0 && _offset.y + limitY < halfFrameHeight){
            _offset.y = halfFrameHeight - limitY;
        }
    }
}

//-----------------------------------------------------------------------------------------
// イメージレイヤ位置・サイズ & アフィン変換マトリクスの決定
//-----------------------------------------------------------------------------------------
- (void)adjustImage
{
    if ([_imageLayer contents]){

        CGRect imageRect = self.frame;
        CGFloat ratio = _imageRatio * _scale * _transisionalScale;
        CGAffineTransform transform = CGAffineTransformIdentity;
        switch (_rotation){
            case 1:
            case 2:
                /* no rotation */
                imageRect.size.width = _imageSize.width * ratio;
                imageRect.size.height = _imageSize.height * ratio;
                break;
            case 5:
            case 8:
                /* 90 degrees rotation */
                imageRect.size.width = _imageSize.height * ratio;
                imageRect.size.height = _imageSize.width * ratio;
                transform = CGAffineTransformRotate(transform, M_PI_2);
                break;
            case 3:
            case 4:
                /* 180 degrees rotation */
                imageRect.size.width = _imageSize.width * ratio;
                imageRect.size.height = _imageSize.height * ratio;
                transform = CGAffineTransformRotate(transform, M_PI);
                break;
            case 6:
            case 7:
                /* 270 degrees rotation */
                imageRect.size.width = _imageSize.height * ratio;
                imageRect.size.height = _imageSize.width * ratio;
                transform = CGAffineTransformRotate(transform, M_PI_2 * 3);
                break;
        }

        imageRect.origin.x += (self.frame.size.width - imageRect.size.width) / 2 + _offset.x;
        imageRect.origin.y += (self.frame.size.height - imageRect.size.height) / 2 + _offset.y;
        _imageLayer.affineTransform = transform;
        _imageLayer.frame = imageRect;
    }
}

@end
