//
//  BuiltinEffect.h
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TransitionEffect.h"
#import "SlideshowConfigController.h"
#import <QuartzCore/QuartzCore.h>


@interface BuiltinEffect : TransitionEffect <CAAnimationDelegate>

- (instancetype)initWithType:(NSString*)type;

@end
