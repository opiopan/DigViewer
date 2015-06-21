//
//  TransitionEffect.m
//  DigViewer
//
//  Created by opiopan on 2015/06/21.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TransitionEffect.h"

@implementation TransitionEffect

- (instancetype)init
{
    self = [super init];
    if (self){
        _dulation = 0;
    }
    return self;
}

- (void)performTransition
{
    [self invokeDeletgateWhenDidEnd];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)invokeDeletgateWhenDidEnd
{
    if (_delegate && _didEndSelector){
        [_delegate performSelector:_didEndSelector withObject:nil];
    }
}
#pragma clang diagnostic pop

@end
