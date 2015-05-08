//
//  SlideshowConfigController.m
//  DigViewer
//
//  Created by opiopan on 2015/05/08.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SlideshowConfigController.h"

@implementation SlideshowConfigController{
    NSUserDefaultsController* _controller;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (id)sharedController
{
    static SlideshowConfigController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [[SlideshowConfigController alloc] init];
    }
    
    return sharedController;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _controller = [NSUserDefaultsController sharedUserDefaultsController];
        _updateCount = 0;
        _interval = [_controller.values valueForKey:@"slideshowInterval"];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setInterval:(NSNumber*)interval
{
    _interval = interval;
    [_controller.values setValue:_interval forKey:@"slideshowInterval"];
    if (!_interval){
        _interval = [_controller.values valueForKey:@"slideshowInterval"];
    }
    _updateCount++;
}

@end
