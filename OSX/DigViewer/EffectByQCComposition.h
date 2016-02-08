//
//  EffectByQCComposition.h
//  DigViewer
//
//  Created by opiopan on 2015/07/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TransitionEffect.h"

@interface EffectByQCComposition : TransitionEffect

+ (BOOL)validateFile:(NSString*)path;
- (instancetype)initWithShaderPath:(NSString*)path duration:(CGFloat)duration;

@end
