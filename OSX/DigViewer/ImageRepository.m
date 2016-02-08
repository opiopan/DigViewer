//
//  ImageRepository.m
//  DigViewer
//
//  Created by opiopan on 2015/08/14.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageRepository.h"

@implementation ImageRepository{
    
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (ImageRepository*)sharedImageRepository
{
    static ImageRepository* sharedImageRepository = nil;
    
    if (!sharedImageRepository){
        sharedImageRepository = [ImageRepository new];
    }
    
    return sharedImageRepository;
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
static int iconSize = 18;
- (NSImage *)iconBrowser
{
    return [self iconForType:@"com.apple.Safari"];
}

- (NSImage *)iconMaps
{
    return [self iconForType:@"com.apple.Maps"];
}

- (NSImage *)iconGoogleEarth
{
    return [self iconForType:@"com.Google.GoogleEarthPlus"];
}

//-----------------------------------------------------------------------------------------
// アイコン抽出
//-----------------------------------------------------------------------------------------
- (NSImage*)iconForType:(NSString*)identifire
{
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
    NSString* path = [workspace absolutePathForAppBundleWithIdentifier:identifire];
    NSImage* rc = nil;
    if (path){
        rc = [[NSWorkspace sharedWorkspace] iconForFile:path];
        [rc setSize:NSMakeSize(iconSize, iconSize)];
    }
    return rc;
}

@end
