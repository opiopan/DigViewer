//
//  RenderingPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/06/03.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "RenderingPreferences.h"

@implementation RenderingPreferences

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self){
        _thumbnailConfig = [ThumbnailConfigController sharedController];
        _imageViewConfig = [ImageViewConfigController sharedController];
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

- (NSImage *) imageForPreferenceNamed: (NSString *) prefName
{
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"photo" accessibilityDescription:nil];
    } else {
        return [[NSBundle mainBundle] imageForResource:@"RenderingPreferences.png"];
    }
}

@end
