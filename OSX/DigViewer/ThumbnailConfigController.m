//
//  ThumbnailConfigController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ThumbnailConfigController.h"
#import "PreferencesDefaultsController.h"
#import "ThumbnailPreferences.h"

#include <math.h>

@implementation ThumbnailConfigController{
    NSNumber* _deferredNotificationValue;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (id)sharedController
{
    static ThumbnailConfigController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [[ThumbnailConfigController alloc] init];
    }
    
    return sharedController;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self){
        [self loadDefaults];
    }
    
    return self;
}

//-----------------------------------------------------------------------------------------
// ユーザーデフォルトの読み込み
//-----------------------------------------------------------------------------------------
- (void)loadDefaults
{
    [self willChangeValueForKey:@"thumbDefaultSize"];
    [self willChangeValueForKey:@"thumbRepresentationType"];
    [self willChangeValueForKey:@"thumbIsVisibleFolder"];
    [self willChangeValueForKey:@"thumbFolderSize"];
    [self willChangeValueForKey:@"thumbFolderSizeRepresentation"];
    [self willChangeValueForKey:@"thumbFolderOpacity"];
    [self willChangeValueForKey:@"thumbFolderOpacityRepresentation"];
    [self willChangeValueForKey:@"thumbUseEmbeddedThumbnail"];
    [self willChangeValueForKey:@"thumbUseEmbeddedThumbnailRAW"];
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    _defaultSize = [defaults.values valueForKey:@"thumbDefaultSize"];
    _representationType = [[defaults.values valueForKey:@"thumbRepresentationType"] intValue];
    _folderIconSize = [defaults.values valueForKey:@"thumbFolderSize"];
    _folderIconSizeRepresentation = @(((int)(_folderIconSize.doubleValue * 10000)) / 100.0);
    _folderIconOpacity = [defaults.values valueForKey:@"thumbFolderOpacity"];
    _folderIconOpacityRepresentation = @(((int)(_folderIconOpacity.doubleValue * 10000)) / 100.0);
    _useEmbeddedThumbnail = [[defaults.values valueForKey:@"thumbUseEmbeddedThumbnail"] boolValue];
    _useEmbeddedThumbnailForRAW = [[defaults.values valueForKey:@"thumbUseEmbeddedThumbnailRAW"] boolValue];
    [self didChangeValueForKey:@"thumbDefaultSize"];
    [self didChangeValueForKey:@"thumbRepresentationType"];
    [self didChangeValueForKey:@"thumbIsVisibleFolder"];
    [self didChangeValueForKey:@"thumbFolderSize"];
    [self didChangeValueForKey:@"thumbFolderSizeRepresentation"];
    [self didChangeValueForKey:@"thumbFolderOpacity"];
    [self didChangeValueForKey:@"thumbFolderOpacityRepresentation"];
    [self didChangeValueForKey:@"thumbUseEmbeddedThumbnail"];
    [self didChangeValueForKey:@"thumbUseEmbeddedThumbnailRAW"];
}

//-----------------------------------------------------------------------------------------
// ユーザーデフォルトを初期値にリセット
//-----------------------------------------------------------------------------------------
- (void)resetDefaults
{
    NSDictionary* defaults = [PreferencesDefaultsController defaultValues];
    
    self.defaultSize = [defaults valueForKey:@"thumbDefaultSize"];
    self.representationType = [[defaults valueForKey:@"thumbRepresentationType"] intValue];
    self.folderIconSize = [defaults valueForKey:@"thumbFolderSize"];
    self.folderIconOpacity = [defaults valueForKey:@"thumbFolderOpacity"];
}

//-----------------------------------------------------------------------------------------
// 更新カウンター操作
//-----------------------------------------------------------------------------------------
- (void)incrementUpdateCount
{
    _updateCount = @(_updateCount.longValue + 1);
    if (_delegate){
        [_delegate performSelector:@selector(notifyUpdateCount:) withObject:_updateCount];
    }
    if (!_deferredNotificationValue){
        _deferredNotificationValue = _updateCount;
        [self performSelector:@selector(deferredNotifyUpdate:) withObject:self afterDelay:0.3];
    }
}

- (void)deferredNotifyUpdate:(id)sender
{
    if (_deferredNotificationValue.doubleValue == _updateCount.doubleValue){
        self.updateCount = _deferredNotificationValue;
        _deferredNotificationValue = nil;
    }else{
        _deferredNotificationValue = _updateCount;
        [self performSelector:@selector(deferredNotifyUpdate:) withObject:self afterDelay:0.3];
    }
}

//-----------------------------------------------------------------------------------------
// プロパティの実装(永続化対象)
//-----------------------------------------------------------------------------------------
- (void)setDefaultSize:(NSNumber *)defaultSize
{
    _defaultSize = @(round(defaultSize.doubleValue * 10.) / 10.);
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:_defaultSize forKey:@"thumbDefaultSize"];
    [_delegate performSelector:@selector(notifyUpdateCount:) withObject:_updateCount];
}

- (void)setRepresentationType:(enum FolderThumbnailRepresentationType)representationType
{
    _representationType = representationType;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:@(_representationType) forKey:@"thumbRepresentationType"];
    [self willChangeValueForKey:@"isVisibleFolderIcon"];
    [self didChangeValueForKey:@"isVisibleFolderIcon"];
    [self incrementUpdateCount];
}

- (void)setFolderIconSize:(NSNumber *)folderIconSize
{
    _folderIconSize = folderIconSize;
    self.folderIconSizeRepresentation = @(((int)(_folderIconSize.doubleValue * 10000)) / 100.0);
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:_folderIconSize forKey:@"thumbFolderSize"];
    [self incrementUpdateCount];
}

- (void)setFolderIconOpacity:(NSNumber *)folderIconOpacity
{
    _folderIconOpacity = folderIconOpacity;
    self.folderIconOpacityRepresentation = @(((int)(_folderIconOpacity.doubleValue * 10000)) / 100.0);
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:_folderIconOpacity forKey:@"thumbFolderOpacity"];
    [self incrementUpdateCount];
}

- (void)setUseEmbeddedThumbnail:(BOOL)useEmbeddedThumbnail
{
    _useEmbeddedThumbnail = useEmbeddedThumbnail;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:@(useEmbeddedThumbnail) forKey:@"thumbUseEmbeddedThumbnail"];
    [self incrementUpdateCount];
}

- (void)setUseEmbeddedThumbnailForRAW:(BOOL)useEmbeddedThumbnailForRAW
{
    _useEmbeddedThumbnailForRAW = useEmbeddedThumbnailForRAW;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:@(useEmbeddedThumbnailForRAW) forKey:@"thumbUseEmbeddedThumbnailRAW"];
    [self incrementUpdateCount];
}

//-----------------------------------------------------------------------------------------
// プロパティの実装(非永続化)
//-----------------------------------------------------------------------------------------
- (BOOL)isVisibleFolderIcon
{
    return _representationType == FolderThumbnailIconOnImage;
}

@end
