//
//  SlideshowPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/06/03.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SlideshowPreferences.h"

@implementation SlideshowPreferences

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self){
        _slideshowConfig = [SlideshowConfigController sharedController];
    }
    return self;
}

- (void)initializeFromDefaults
{
}

//-----------------------------------------------------------------------------------------
// シートのアピアランス設定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

@end
