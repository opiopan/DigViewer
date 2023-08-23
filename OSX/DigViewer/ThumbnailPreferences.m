//
//  ThumbnailPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/05/09.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ThumbnailPreferences.h"
#import "PathNode.h"

@implementation ThumbnailPreferences{
    long        _thumbnailConfigUpdateCount;
    PathNode*   _sampleNodeForThumbnail;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self){
        _thumbnailConfig = [ThumbnailConfigController sharedController];
        _thumbnailConfig.delegate = self;
        _thumbnailConfigUpdateCount = _thumbnailConfig.updateCount.longValue;
    }
    return self;
}

- (void)initializeFromDefaults
{
    _thumbnailSampleView.imageSize = _thumbnailConfig.defaultSize.doubleValue;
    self.thumbnailSampleType = @0;
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
        return [NSImage imageWithSystemSymbolName:@"square.grid.3x3" accessibilityDescription:nil];
    } else {
        return [[NSBundle mainBundle] imageForResource:@"ThumbnailPreferences.png"];
    }
}

//-----------------------------------------------------------------------------------------
// サムネイル設定のリセット
//-----------------------------------------------------------------------------------------
- (IBAction)onResetThumbnailSettings:(id)sender {
    [[ThumbnailConfigController sharedController] resetDefaults];
}

//-----------------------------------------------------------------------------------------
// サムネイル設定変更通知の受付
//-----------------------------------------------------------------------------------------
- (void)notifyUpdateCount:(NSNumber*)updateCount
{
    if (updateCount.longValue != _thumbnailConfigUpdateCount){
        _thumbnailConfigUpdateCount = updateCount.longValue;
        _thumbnailSampleView.image = (__bridge CGImageRef)([_sampleNodeForThumbnail imageRepresentation]);
    }
    if (_thumbnailConfig.defaultSize.doubleValue != _thumbnailSampleView.imageSize){
        _thumbnailSampleView.imageSize = _thumbnailConfig.defaultSize.doubleValue;
    }
}

//-----------------------------------------------------------------------------------------
// サムネールサンプルタイプの変更
//-----------------------------------------------------------------------------------------
- (void)setThumbnailSampleType:(NSNumber*)thumbnailSampleType
{
    _thumbnailSampleType = thumbnailSampleType;
    
    NSString* resourceName = _thumbnailSampleType.longValue == 0 ? @"thumbnailSampleSquare" :
    _thumbnailSampleType.longValue == 1 ? @"thumbnailSampleHorizontal" :
    @"thumbnailSampleVertical";
    NSString* imagePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"jpg"];
    _sampleNodeForThumbnail = [PathNode psudoPathNodeWithName:@"dummy" imagePath:imagePath isFolder:YES];
    _thumbnailSampleView.image = (__bridge CGImageRef)([_sampleNodeForThumbnail imageRepresentation]);
}

@end
