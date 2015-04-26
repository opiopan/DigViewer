//
//  ThumbnailConfigController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ThumbnailConfigController.h"
#import "PreferencesDefaultsController.h"

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
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    self.defaultSize = [defaults.values valueForKey:@"thumbDefaultSize"];
    self.isVisibleFolderIcon = [[defaults.values valueForKey:@"thumbIsVisibleFolder"] boolValue];
    self.folderIconSize = [defaults.values valueForKey:@"thumbFolderSize"];
    self.folderIconOpacity = [defaults.values valueForKey:@"thumbFolderOpacity"];
}

//-----------------------------------------------------------------------------------------
// ユーザーデフォルトを初期値にリセット
//-----------------------------------------------------------------------------------------
- (void)resetDefaults
{
    NSDictionary* defaults = [PreferencesDefaultsController defaultValues];
    
    self.defaultSize = [defaults valueForKey:@"thumbDefaultSize"];
    self.isVisibleFolderIcon = [[defaults valueForKey:@"thumbIsVisibleFolder"] boolValue];
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
// プロパティの実装
//-----------------------------------------------------------------------------------------
- (void)setUpdateCount:(NSNumber *)updateCount
{
    _updateCount = updateCount;
}

- (void)setDefaultSize:(NSNumber *)defaultSize
{
    _defaultSize = defaultSize;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:_defaultSize forKey:@"thumbDefaultSize"];
    [_delegate performSelector:@selector(notifyUpdateCount:) withObject:_updateCount];
}

- (void)setIsVisibleFolderIcon:(BOOL)isVisibleFolderIcon
{
    _isVisibleFolderIcon = isVisibleFolderIcon;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:@(_isVisibleFolderIcon) forKey:@"thumbIsVisibleFolder"];
    [self incrementUpdateCount];
}

- (void)setFolderIconSize:(NSNumber *)folderIconSize
{
    _folderIconSize = folderIconSize;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:_folderIconSize forKey:@"thumbFolderSize"];
    [self incrementUpdateCount];
}

- (void)setFolderIconOpacity:(NSNumber *)folderIconOpacity
{
    _folderIconOpacity = folderIconOpacity;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [[defaults values] setValue:_folderIconOpacity forKey:@"thumbFolderOpacity"];
    [self incrementUpdateCount];
}

@end
