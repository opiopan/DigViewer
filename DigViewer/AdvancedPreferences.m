//
//  AdvancedPreferences.m
//  DigViewer
//
//  Created by opiopan on 4/12/15.
//  Copyright (c) 2015 opiopan. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "PathNode.h"

@implementation AdvancedPreferences{
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
        _thumbnailConfigUpdateCount = _thumbnailConfig.updateCount;
    }
    return self;
}

- (void)initializeFromDefaults
{
    _thumbnailSampleView.imageSize = _thumbnailConfig.defaultSize.doubleValue;
    self.thumbnailSampleType = @0;
}

//-----------------------------------------------------------------------------------------
// シートアピアランス指定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

- (NSImage *) imageForPreferenceNamed: (NSString *) prefName
{
    return [NSImage imageNamed:NSImageNameAdvanced];
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
    _sampleNodeForThumbnail = [PathNode psudoPathNodeWithImagePath:imagePath isFolder:YES];
    _thumbnailSampleView.image = (__bridge CGImageRef)([_sampleNodeForThumbnail imageRepresentation]);
}

@end
