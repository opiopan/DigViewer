//
//  TouchGestureRecognizer.m
//  DigViewer
//
//  Created by opiopan on 2015/05/24.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TouchGestureRecognizer.h"

@implementation TouchGestureRecognizer

- (instancetype)init
{
    self = [super init];
    if (self){
        _isEnabled = YES;
        _state = TouchGestureStateNone;
    }
    return self;
}

- (void)setIsEnabled:(BOOL)isEnabled
{
    if (_isEnabled && !isEnabled){
        [self cancelGesture];
    }
    _isEnabled = isEnabled;
}

- (void)cancelGesture
{
}

@end
