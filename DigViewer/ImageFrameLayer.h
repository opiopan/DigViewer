//
//  ImageFrameLayer.h
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RelationalImageAccessor.h"

@interface ImageFrameLayer : CALayer

@property (nonatomic) id relationalImage;
@property (nonatomic) RelationalImageAccessor* relationalImageAccessor;

@property (nonatomic) BOOL isFitFrame;
@property (nonatomic) CGFloat scale;
@property (readonly, nonatomic) CGFloat transisionalScale;
@property (nonatomic) CGPoint offset;
@property (nonatomic) CGPoint transisionalOffset;

- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset;
- (void)fixScale;
- (CGPoint)startPanning;
- (void)fixOffsetWithVelocity:(CGPoint)velocity;

@end
