//
//  AdvancedPreferences.m
//  DigViewer
//
//  Created by opiopan on 4/12/15.
//  Copyright (c) 2015 opiopan. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "PathNode.h"

@implementation AdvancedPreferences

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
// 初期化
//-----------------------------------------------------------------------------------------
- (void)initializeFromDefaults
{
    // ユーザーデフォルトの読み込み
    [self willChangeValueForKey:@"sortType"];
    [self willChangeValueForKey:@"isCaseInsensitive"];
    [self willChangeValueForKey:@"isSortAsNumeric"];
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    _sortType = [[controller.values valueForKey:@"pathNodeSortType"] integerValue];
    _isCaseInsensitive = [[controller .values valueForKey:@"pathNodeSortCaseInsensitive"] boolValue];
    _isSortAsNumeric = [[controller .values valueForKey:@"pathNodeSortAsNumeric"] boolValue];
    [self didChangeValueForKey:@"sortType"];
    [self didChangeValueForKey:@"isCaseInsensitive"];
    [self didChangeValueForKey:@"isSortAsNumeric"];
    
    // ソート例配列の作成
    NSString* imagePath = [[NSBundle mainBundle] pathForImageResource:@"thumbnailSampleSquare"];
    _exampleList = @[[PathNode psudoPathNodeWithName:@"cat1_folder" imagePath:imagePath isFolder:YES],
                     [PathNode psudoPathNodeWithName:@"CAT02_folder" imagePath:imagePath isFolder:YES],
                     [PathNode psudoPathNodeWithName:@"CAT1_image2.jpg" imagePath:imagePath isFolder:NO],
                     [PathNode psudoPathNodeWithName:@"CAT1_image07.jpg" imagePath:imagePath isFolder:NO],
                     [PathNode psudoPathNodeWithName:@"cat1_image12.jpg" imagePath:imagePath isFolder:NO],
                     [PathNode psudoPathNodeWithName:@"CAT2_image5.jpg" imagePath:imagePath isFolder:NO]];
    [self sortExample];
}

//-----------------------------------------------------------------------------------------
// ソート例配列のソート
//-----------------------------------------------------------------------------------------
- (void)sortExample
{
    NSStringCompareOptions sortOption = _isCaseInsensitive ? NSCaseInsensitiveSearch : 0;
    sortOption |= _isSortAsNumeric ? NSNumericSearch : 0;
    NSComparisonResult (^comparator)(PathNode* o1, PathNode* o2) = ^(PathNode* o1, PathNode* o2){
        if (_sortType == 0){
            if (o1.isImage && !o2.isImage){
                return NSOrderedAscending;
            }else if (!o1.isImage && o2.isImage){
                return NSOrderedDescending;
            }else{
                return [o1.name compare:o2.name options:sortOption];
            }
        }else if (_sortType == 1){
            if (!o1.isImage && o2.isImage){
                return NSOrderedAscending;
            }else if (o1.isImage && !o2.isImage){
                return NSOrderedDescending;
            }else{
                return [o1.name compare:o2.name options:sortOption];
            }
        }else{
            return [o1.name compare:o2.name options:sortOption];
        }
    };
    self.exampleList = [_exampleList sortedArrayUsingComparator:comparator];
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setSortType:(NSInteger)sortType
{
    _sortType = sortType;
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller.values setValue:@(_sortType) forKey:@"pathNodeSortType"];
    [self sortExample];
}

- (void)setIsCaseInsensitive:(BOOL)isCaseInsensitive
{
    _isCaseInsensitive = isCaseInsensitive;
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller.values setValue:@(_isCaseInsensitive) forKey:@"pathNodeSortCaseInsensitive"];
    [self sortExample];
}

- (void)setIsSortAsNumeric:(BOOL)isSortAsNumeric
{
    _isSortAsNumeric = isSortAsNumeric;
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    [controller.values setValue:@(_isSortAsNumeric) forKey:@"pathNodeSortAsNumeric"];
    [self sortExample];
}

@end
