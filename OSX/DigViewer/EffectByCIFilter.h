//
//  EffectByCIFilter.h
//  DigViewer
//
//  Created by opiopan on 2015/06/24.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TransitionEffect.h"
#import <Quartz/Quartz.h>

@interface EffectByCIFilter : TransitionEffect <CAAnimationDelegate>
@property (readonly, nonatomic) CIFilter* filter;
@end
