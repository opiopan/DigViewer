//
//  BlurTransition.m
//  DigViewer
//
//  Created by opiopan on 2015/07/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "BlurTransition.h"
#import <Quartz/Quartz.h>

@implementation BlurTransition{
    CIFilter* _fromBlur;
    CIFilter* _toBlur;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        self.duration = 2.0;
        _fromBlur = [CIFilter filterWithName:@"CIGaussianBlur"];
        _fromBlur.name = @"blur";
        [_fromBlur setValue:@0.0 forKey:@"inputRadius"];
        _toBlur = [CIFilter filterWithName:@"CIGaussianBlur"];
        _toBlur.name = @"blur";
        [_toBlur setValue:@0.0 forKey:@"inputRadius"];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 遷移開始
//-----------------------------------------------------------------------------------------
static const CGFloat MAX_RADIUS = 50;
- (void)performTransition
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.toLayer.hidden = NO;
    [CATransaction commit];

    CGFloat maxRadius = self.fromLayer.frame.size.height / 10.0 < MAX_RADIUS ? self.fromLayer.frame.size.height / 10.0 :
                                                                               MAX_RADIUS;
    
    [CATransaction begin];
    BlurTransition* __weak weakSelf = self;
    [CATransaction setCompletionBlock:^(){
        [weakSelf performSelector:@selector(didEndTransition) withObject:nil afterDelay:0];
    }];
    
    //遷移元画像のアニメーション設定
    self.fromLayer.filters = @[_fromBlur];
    CABasicAnimation* blurAnimation = [CABasicAnimation animation];
    blurAnimation.keyPath = @"filters.blur.inputRadius";
    blurAnimation.fromValue = @0.0;
    blurAnimation.toValue = @(maxRadius);
    CABasicAnimation* alphaAnimation = [CABasicAnimation animation];
    alphaAnimation.keyPath = @"opacity";
    alphaAnimation.fromValue = @1.0;
    alphaAnimation.toValue = @0.0;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = self.duration;
    group.repeatCount = 1;
    group.removedOnCompletion = NO;
    group.fillMode = kCAFillModeForwards;
    group.animations = @[blurAnimation, alphaAnimation];
    [self.fromLayer addAnimation:group forKey:@"group-animation"];

    //遷移先画像のアニメーション設定
    self.toLayer.filters = @[_toBlur];
    blurAnimation = [CABasicAnimation animation];
    blurAnimation.keyPath = @"filters.blur.inputRadius";
    blurAnimation.fromValue = @(maxRadius);
    blurAnimation.toValue = @0.0;
    blurAnimation.duration = self.duration;
    blurAnimation.repeatCount = 1;
    blurAnimation.removedOnCompletion = NO;
    blurAnimation.fillMode = kCAFillModeForwards;
    [self.toLayer addAnimation:blurAnimation forKey:@"blur-animation"];
    
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// 遷移終了
//-----------------------------------------------------------------------------------------
- (void)didEndTransition
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.fromLayer.hidden = YES;
    self.fromLayer.opacity = 1.0;
    self.fromLayer.filters = nil;
    [self.fromLayer removeAllAnimations];
    self.toLayer.filters = nil;
    [self.toLayer removeAllAnimations];
    [CATransaction commit];
    
    [self invokeDelegateWhenDidEnd];
}

@end
