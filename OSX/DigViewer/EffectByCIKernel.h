//
//  EffectByCIKernel.h
//  DigViewer
//
//  Created by opiopan on 2015/06/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EffectByCIFilter.h"

@interface EffectByCIKernel : EffectByCIFilter

- (instancetype)initWithShaderPath:(NSString*)path duration:(CGFloat)duration;
- (instancetype)initWithMetalShaderName:(NSString*)name duration:(CGFloat)duration;
- (instancetype)initWithMetalShaderLibraryURL:(NSURL*)url duration:(CGFloat)duration;

@end
