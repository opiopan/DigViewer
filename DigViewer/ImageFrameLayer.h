//
//  ImageFrameLayer.h
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface ImageFrameLayer : CALayer

@property (nonatomic) BOOL isFitFrame;
@property (readonly, nonatomic) CGFloat scale;
@property (readonly, nonatomic) CGFloat transisionalScale;
@property (nonatomic) CGPoint offset;

- (void)setImage:(id)image withRotation:(NSInteger)rotation;
- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset;
- (void)fixScale;

@end
