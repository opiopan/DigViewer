//
//  DocumentConfigController.h
//  DigViewer
//
//     Model (PathNodeグラフ)の構造に影響するUser Defaultsを抽象化するクラス
//
//  Created by opiopan on 2015/05/02.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PathNode.h"

enum ImageSetType {imageSetTypeALL = 0, imageSetTypeExceptRaw, imageSetTypeSmall, imageSetTypeCustom};

@interface DocumentConfigController : NSObject

@property (assign, nonatomic) enum ImageSetType type;
@property (strong, nonatomic) NSNumber* maxFileSize;
@property (strong, nonatomic) NSArray* omittingExtentions;

@property (assign, nonatomic) NSInteger updateCount;

@property (readonly, nonatomic) BOOL isTypeSmall;
@property (readonly, nonatomic) BOOL isTypeCustom;

@property (readonly, nonatomic) PathNodeOmmitingCondition* condition;

+ (DocumentConfigController*)sharedController;
- (DocumentConfigController*)snapshot;

@end
