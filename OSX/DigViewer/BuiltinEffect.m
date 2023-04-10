//
//  BuiltinEffect.m
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "BuiltinEffect.h"

 enum _SlideshowTransition{
     SlideshowTransitionNone,
     SlideshowTransitionFade,
     SlideshowTransitionMoveIn,
     SlideshowTransitionPush,
     SlideshowTransitionReveal,
 };
 typedef enum _SlideshowTransition SlideshowTransition;

@implementation BuiltinEffect{
    SlideshowTransition _type;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithType:(NSString*)type
{
    self = [self init];
    if (self){
        self.duration = 0.5;
        if ([type isEqualToString:kSlideshowTransitionNone]){
            _type = SlideshowTransitionNone;
        }else if ([type isEqualToString:kSlideshowTransitionFade]){
            _type = SlideshowTransitionFade;
            self.duration = 1.0;
        }else if ([type isEqualToString:kSlideshowTransitionMoveIn]){
            _type = SlideshowTransitionMoveIn;
        }else if ([type isEqualToString:kSlideshowTransitionPush]){
            _type = SlideshowTransitionPush;
        }else if ([type isEqualToString:kSlideshowTransitionReveal]){
            _type = SlideshowTransitionReveal;
        }else{
            self = nil;
        }
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
    [self invokeDelegateWhenDidEnd];
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
