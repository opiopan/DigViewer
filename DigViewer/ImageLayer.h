//
//  ImageLayer.h
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

enum _ImageLayerBorder{
    ImageLayerBorderTop = 1,
    ImageLayerBorderBottom = 2,
    ImageLayerBorderLeft = 4,
    ImageLayerBorderRight = 8
};
typedef enum _ImageLayerBorder ImageLayerBorder;

@interface ImageLayer : CALayer

@property (nonatomic) BOOL isFitFrame;
@property (nonatomic) CGFloat scale;
@property (readonly, nonatomic) CGFloat transisionalScale;
@property (nonatomic) CGPoint offset;
@property (nonatomic) CGPoint transisionalOffset;
@property (readonly, nonatomic) int borderCondition;

- (void)setImage:(id)image withRotation:(NSInteger)rotation;
- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset;
- (void)fixScale;
- (CGPoint)startPanning;
- (void)fixOffsetWithVelocity:(CGPoint)velocity;

@end
