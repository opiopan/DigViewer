//
//  DocumentConfigController.m
//  DigViewer
//
//     Model (PathNodeグラフ)の構造に影響するUser Defaultsを抽象化するクラス
//
//  Created by opiopan on 2015/05/02.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DocumentConfigController.h"

@implementation DocumentConfigController{
    NSUserDefaultsController* _controller;
}

static NSDictionary* rawSuffixes = nil;

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (id)sharedController
{
    static DocumentConfigController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [[DocumentConfigController alloc] initWithUserDefaults];
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
    }
    return self;
}

- (id)initWithUserDefaults
{
    if (!rawSuffixes){
        rawSuffixes = @{@"psd":@"cpx",
                        @"tif":@"cpx", @"tiff":@"cpx"};
    }
    self = [self init];
    if (self){
        _type = ((NSNumber*)[_controller.values valueForKey:@"imageSetType"]).intValue;
        _maxFileSize = [_controller.values valueForKey:@"imageSetMaxFileSize"];
        _omittingExtentions = (NSArray*)[_controller.values valueForKey:@"imageSetOmittingExt"];
        _isTypeSmall = _type == imageSetTypeSmall;
        _isTypeCustom = _type == imageSetTypeCustom;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// スナップショット作成
//-----------------------------------------------------------------------------------------
- (DocumentConfigController *)snapshot
{
    DocumentConfigController* snapshot = [[DocumentConfigController alloc] init];
    snapshot->_type = _type;
    snapshot->_maxFileSize = _maxFileSize;
    snapshot->_omittingExtentions = _omittingExtentions;
    return snapshot;
}

//-----------------------------------------------------------------------------------------
// オブジェクト同値比較
//-----------------------------------------------------------------------------------------
- (BOOL) isEqual:(id)object
{
    if (![[object class] isSubclassOfClass:[self class]]){
        return NO;
    }
    DocumentConfigController* o = object;
    if (_type != o->_type){
        return NO;
    }
    if (_type == imageSetTypeSmall && _maxFileSize != o->_maxFileSize){
        return NO;
    }
    if (_type == imageSetTypeCustom){
        if (_omittingExtentions.count != o->_omittingExtentions.count){
            return NO;
        }
        for (NSInteger i = 0; i < _omittingExtentions.count; i++){
            if (![_omittingExtentions[i] isEqual:o->_omittingExtentions[i]]){
                return NO;
            }
        }
    }
    return YES;
}

//-----------------------------------------------------------------------------------------
// プロパティ実装:永続化対象
//-----------------------------------------------------------------------------------------
- (void)setType:(enum ImageSetType)type
{
    _type = type;
    [_controller.values setValue:[NSNumber numberWithInt:_type] forKey:@"imageSetType"];

    self.updateCount = _updateCount + 1;
    
    [self willChangeValueForKey:@"isTypeSmall"];
    [self willChangeValueForKey:@"isTypeCustom"];
    _isTypeSmall = _type == imageSetTypeSmall;
    _isTypeCustom = _type == imageSetTypeCustom;
    [self didChangeValueForKey:@"isTypeSmall"];
    [self didChangeValueForKey:@"isTypeCustom"];
}

- (void)setMaxFileSize:(NSNumber*)maxFileSize
{
    _maxFileSize = maxFileSize;
    [_controller.values setValue:maxFileSize forKey:@"imageSetMaxFileSize"];
    self.updateCount = _updateCount + 1;
}

- (void)setOmittingExtentions:(NSArray *)omittingExtentions
{
    _omittingExtentions = omittingExtentions;
    [_controller.values setValue:_omittingExtentions forKey:@"imageSetOmittingExt"];
    self.updateCount = _updateCount + 1;
}

//-----------------------------------------------------------------------------------------
// プロパティ実装:非永続化
//-----------------------------------------------------------------------------------------
- (PathNodeOmmitingCondition *)condition
{
    PathNodeOmmitingCondition* condition = [[PathNodeOmmitingCondition alloc] init];
    if (_type == imageSetTypeExceptRaw){
        condition.suffixes = rawSuffixes;
        condition.isOmmitingRawImage = YES;
    }else if (_type == imageSetTypeSmall){
        condition.maxFileSize = _maxFileSize.longValue * 1024 * 1024;
    }else if (_type == imageSetTypeCustom){
        NSMutableDictionary* extentions = [NSMutableDictionary dictionaryWithCapacity:_omittingExtentions.count];
        for (NSString* ext in _omittingExtentions){
            [extentions setObject:@"custom" forKey:ext];
        }
        condition.suffixes = extentions;
    }
    return condition;
}

@end
