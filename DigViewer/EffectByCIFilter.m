//
//  EffectByCIFilter.m
//  DigViewer
//
//  Created by opiopan on 2015/06/24.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EffectByCIFilter.h"

@implementation EffectByCIFilter

//-----------------------------------------------------------------------------------------
// フィルター返却：派生クラス側で実装が必須なメソッド
//-----------------------------------------------------------------------------------------
- (CIFilter *)filter
{
    return nil;
}

//-----------------------------------------------------------------------------------------
// 遷移処理
//-----------------------------------------------------------------------------------------
- (void)performTransition
{
    CATransition* transition = [CATransition animation];
    transition.delegate = self;
    transition.startProgress = 0;
    transition.endProgress = 1.0;
    transition.duration = self.duration;
    transition.filter = self.filter;
    
    self.fromLayer.hidden = YES;
    [self.fromLayer.superlayer addAnimation:transition forKey:@"sublayers"];
    self.toLayer.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self invokeDeletgateWhenDidEnd];
    
}


@end
