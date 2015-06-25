//
//  BuiltinEffect.m
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "BuiltinEffect.h"
#import <Quartz/Quartz.h>

@implementation BuiltinEffect{
    SlideshowTransition _type;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithType:(SlideshowTransition)type
{
    if (type >= SlideshowTransitionFade && type <= SlideshowTransitionReveal){
        self = [self init];
        if (self){
            _type = type;
            self.duration = 0.5;
        }
    }else{
        self = nil;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 遷移処理
//-----------------------------------------------------------------------------------------
- (void)performTransition
{
    CATransition* transition = self.transition;
    self.fromLayer.hidden = YES;
    [self.fromLayer.superlayer addAnimation:transition forKey:@"sublayers"];
    self.toLayer.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self invokeDeletgateWhenDidEnd];
}

//-----------------------------------------------------------------------------------------
// CATransitionオブジェクト生成
//-----------------------------------------------------------------------------------------
- (CATransition*)transition
{
    CATransition* transition = [CATransition animation];
    transition.delegate = self;
    transition.startProgress = 0;
    transition.endProgress = 1.0;
    transition.duration = self.duration;
    transition.subtype = kCATransitionFromRight;
    
    switch (_type){
        case SlideshowTransitionFade:
            transition.type = kCATransitionFade;
            break;
        case SlideshowTransitionMoveIn:
            transition.type =kCATransitionMoveIn;
            break;
        case SlideshowTransitionPush:
            transition.type = kCATransitionPush;
            break;
        case SlideshowTransitionReveal:
            transition.type = kCATransitionReveal;
            break;
        default:
            break;
    }

    return transition;
}

@end
