//
//  TemporaryFileController.m
//  DigViewer
//
//  Created by opiopan on 2015/08/15.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TemporaryFileController.h"

@implementation TemporaryFileController{
    NSMutableDictionary* _categories;
    time_t _uniqueKey;
    NSInteger _counter;
}

static NSString* TMPDIR = @"/tmp/DigViewer-work";

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (TemporaryFileController*)sharedController
{
    static TemporaryFileController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [TemporaryFileController new];
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
        _categories = [NSMutableDictionary dictionary];
        [self cleanUpAllCategories];
        time(&_uniqueKey);
    }
    
    return self;
}

//-----------------------------------------------------------------------------------------
// オールクリア
//-----------------------------------------------------------------------------------------
- (void)cleanUpAllCategories
{
    NSFileManager* manager = [NSFileManager defaultManager];
    NSError* error;
    BOOL rc;
    rc = [manager removeItemAtPath:TMPDIR error:&error];
    rc = [manager createDirectoryAtPath:TMPDIR withIntermediateDirectories:YES attributes:nil error:&error];
}

//-----------------------------------------------------------------------------------------
// 一時ファイル名割り当て
//-----------------------------------------------------------------------------------------
- (NSString*) allocatePathWithSuffix:(NSString*)suffix forCategory:(NSString*)category
{
    _counter++;
    NSString* rc = [NSString stringWithFormat:@"%@/%@:%ld_%ld%@", TMPDIR, category, _uniqueKey, _counter, suffix];
    NSMutableArray* array = [_categories valueForKey:category];
    if (!array){
        array = [NSMutableArray array];
        [_categories setObject:array forKey:category];
    }
    [array addObject:rc];
    return rc;
}

//-----------------------------------------------------------------------------------------
// カテゴリ単位の一時ファイル削除
//-----------------------------------------------------------------------------------------
- (void) cleanUpForCategory:(NSString*)category
{
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* files = [_categories valueForKey:category];
    for (NSString* file in files){
        NSError* error;
        BOOL rc;
        rc = [manager removeItemAtPath:file error:&error];
    }
    [_categories removeObjectForKey:category];
}

@end
