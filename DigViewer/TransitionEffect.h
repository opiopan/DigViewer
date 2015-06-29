//
//  TransitionEffect.h
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransitionEffect : NSObject

@property (weak, nonatomic) id delegate;
@property (assign, nonatomic) SEL didEndSelector;

@property (assign, nonatomic) CGFloat duration;

@property (nonatomic) CALayer* fromLayer;
@property (nonatomic) CALayer* toLayer;
@property (nonatomic) id fromImage;
@property (nonatomic) id toImage;

- (void)performTransition;
- (void)invokeDelegateWhenDidEnd;

@end
