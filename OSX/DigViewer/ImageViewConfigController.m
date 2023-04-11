//
//  ImageViewConfigController.m
//  DigViewer
//
//  Created by opiopan on 2015/06/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageViewConfigController.h"

@implementation ImageViewConfigController{
    NSInteger _deferredNotificationValue;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (id)sharedController
{
    static ImageViewConfigController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [[ImageViewConfigController alloc] init];
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
    [self willChangeValueForKey:@"imageBackgroundColor"];
    [self willChangeValueForKey:@"imageMagnificationFilter"];
    [self willChangeValueForKey:@"imageMinificationFilter"];
    [self willChangeValueForKey:@"imageUseEmbeddedThumbnailRAW"];
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    _backgroundColor = (NSColor *)[NSKeyedUnarchiver unarchiveObjectWithData:[defaults.values valueForKey:@"imageBackgroundColor2"]];
    _magnificationFilter = [[defaults.values valueForKey:@"imageMagnificationFilter"] intValue];
    _minificationFilter = [[defaults.values valueForKey:@"imageMinificationFilter"] intValue];
    _useEmbeddedThumbnailRAW = [[defaults.values valueForKey:@"imageUseEmbeddedThumbnailRAW"] boolValue];
    [self didChangeValueForKey:@"imageBackgroundColor"];
    [self didChangeValueForKey:@"imageMagnificationFilter"];
    [self didChangeValueForKey:@"imageMinificationFilter"];
    [self didChangeValueForKey:@"imageUseEmbeddedThumbnailRAW"];
}

//-----------------------------------------------------------------------------------------
// 更新カウンター操作
//-----------------------------------------------------------------------------------------
- (void)incrementUpdateCount
{
    _updateCount = _updateCount + 1;
    if (!_deferredNotificationValue){
        _deferredNotificationValue = _updateCount;
        [self performSelector:@selector(deferredNotifyUpdate:) withObject:self afterDelay:0.3];
    }
}

- (void)deferredNotifyUpdate:(id)sender
{
    if (_deferredNotificationValue == _updateCount){
        self.updateCount = _deferredNotificationValue;
        _deferredNotificationValue = 0;
    }else{
        _deferredNotificationValue = _updateCount;
        [self performSelector:@selector(deferredNotifyUpdate:) withObject:self afterDelay:0.3];
    }
}

//-----------------------------------------------------------------------------------------
// プロパティの実装
//-----------------------------------------------------------------------------------------
- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [defaults.values setValue:[NSKeyedArchiver archivedDataWithRootObject:_backgroundColor] forKey:@"imageBackgroundColor2"];
    [self incrementUpdateCount];
}

- (void)setMagnificationFilter:(ImageViewFilterType)magnificationFilter
{
    _magnificationFilter = magnificationFilter;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [defaults.values setValue:@(_magnificationFilter) forKey:@"imageMagnificationFilter"];
    [self incrementUpdateCount];
}

- (void)setMinificationFilter:(ImageViewFilterType)minificationFilter
{
    _minificationFilter = minificationFilter;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [defaults.values setValue:@(_minificationFilter) forKey:@"imageMinificationFilter"];
    [self incrementUpdateCount];
}

- (void)setUseEmbeddedThumbnailRAW:(BOOL)useEmbeddedThumbnailRAW
{
    _useEmbeddedThumbnailRAW = useEmbeddedThumbnailRAW;
    NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
    [defaults.values setValue:@(_useEmbeddedThumbnailRAW) forKey:@"imageUseEmbeddedThumbnailRAW"];
    [self incrementUpdateCount];
}

@end
