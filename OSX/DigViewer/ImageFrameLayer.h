//
//  ImageFrameLayer.h
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RelationalImageAccessor.h"
#import "ImageLayer.h"
#import "TransitionEffect.h"

@interface ImageFrameLayer : CALayer

@property (nonatomic) id relationalImage;
@property (nonatomic) RelationalImageAccessor* relationalImageAccessor;

@property (nonatomic) BOOL isFitFrame;
@property (nonatomic) CGFloat scale;
@property (readonly, nonatomic) CGFloat transisionalScale;
@property (nonatomic) CGPoint offset;
@property (nonatomic) CGPoint transisionalOffset;
@property (readonly, nonatomic) int borderCondition;
@property (nonatomic) CGFloat swipeOffset;
@property (readonly, nonatomic)BOOL isInSwipeInertiaMode;
@property (nonatomic) SEL didEndSwipeSelector;

- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset;
- (void)fixScale;
- (CGPoint)startPanning;
- (void)fixOffsetWithVelocity:(CGPoint)velocity;

- (void)startSwipeForDirection:(RelationalImageDirection)direction;
- (void)fixSwipeOffsetWithVelocity:(CGFloat)velocity;

- (void)moveToDirection:(RelationalImageDirection)direction withTransition:(TransitionEffect*)effect inScreen:(NSScreen*)screen;

@end
