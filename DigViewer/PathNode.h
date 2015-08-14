//
//  PathNode.h
//  DigViewer
//
//  Created by opiopan on 2013/01/05.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PathfinderPinnedFile.h"

//-----------------------------------------------------------------------------------------
// PathNodeProgress: ノードツリー進捗管理オブジェクト
//-----------------------------------------------------------------------------------------
@interface PathNodeProgress : NSObject
@property double progress;
@property NSString* target;
@property BOOL isCanceled;
@end

//-----------------------------------------------------------------------------------------
// PathNodeOmmitingCondition: ノードツリー生成時の除外対象
//-----------------------------------------------------------------------------------------
@interface PathNodeOmmitingCondition : NSObject
@property BOOL          isOmmitingRawImage;
@property NSDictionary* suffixes;
@property long          maxFileSize;  // it means no limit if negative
- (BOOL) isOmmitingImagePath:(NSString*)path;
@end

//-----------------------------------------------------------------------------------------
// PathNodeSortType: ソート順
//-----------------------------------------------------------------------------------------
enum PathNodeSortType {
    SortTypeImageIsPrior = 0,
    SortTypeFolderIsPrior,
    SortTypeMix
};

//-----------------------------------------------------------------------------------------
// PathNodeCreateOption:ノードツリー生成オプション
//-----------------------------------------------------------------------------------------
struct _PathNodeCreateOption{
    BOOL isSortByCaseInsensitive;
    BOOL isSortAsNumeric;
};
typedef struct _PathNodeCreateOption PathNodeCreateOption;

//-----------------------------------------------------------------------------------------
// PathNode: ノードツリーの構成要素
//-----------------------------------------------------------------------------------------
@interface PathNode : NSObject <NSCopying>

// 属性
@property (nonatomic) enum PathNodeSortType sortType;
@property (nonatomic) BOOL isSortByCaseInsensitive;
@property (nonatomic) BOOL isSortAsNumeric;
@property (nonatomic) BOOL isSortByDateTime;

@property (readonly) NSString*       name;
@property (readonly) PathNode*       me;
@property (readonly, weak) PathNode* parent;
@property (readonly) NSArray*        children;
@property (readonly) BOOL            isLeaf;
@property (readonly) BOOL            isImage;
@property (readonly) BOOL            isRawImage;
@property (readonly) BOOL            isRasterImage;
@property (readonly) NSArray*        images;
@property (readonly) NSUInteger      indexInParent;
@property (readonly) PathNode*       imageNode;
@property (readonly) PathNode*       imageNodeReverse;
@property (readonly) NSString*       imagePath;
@property (readonly) NSString*       imageName;
@property (readonly) NSImage*        image;
@property (readonly) NSImage*        icon;
@property (readonly) NSString*       originalPath;

@property (nonatomic) NSString*      imageDateTime;

@property (readonly) NSString*       imageUID;
@property (readonly) NSString*       imageRepresentationType;
@property (readonly) id              imageRepresentation;

// オブジェクト初期化
+ (PathNode*) pathNodeWithPath:(NSString*)path
             ommitingCondition:(PathNodeOmmitingCondition*)cond
                        option:(PathNodeCreateOption*)option
                      progress:(PathNodeProgress*)progress;
+ (PathNode*) pathNodeWithPinnedFile:(PathfinderPinnedFile*)pinnedFile
                   ommitingCondition:(PathNodeOmmitingCondition*)cond
                              option:(PathNodeCreateOption*)option
                            progress:(PathNodeProgress*)progress;
+ (PathNode*) psudoPathNodeWithName:(NSString*)name imagePath:(NSString*)path isFolder:(BOOL)isFolder;

// イメージファイルが存在しない場合に表示するイメージ
+ (NSImage*) unavailableImage;

// ツリーウォーキング
- (PathNode*) nextImageNode;
- (PathNode*) previousImageNode;
- (PathNode*) nextFolderNode;
- (PathNode*) previousFolderNode;

// IndexPath作成
- (NSIndexPath*) indexPath;

// portabilityがあるパスに対する操作
- (NSArray*) portablePath;
- (PathNode*) nearestNodeAtPortablePath:(NSArray*)path;

// イメージ操作部品
- (CGImageRef) CGImageFromNSImage:(NSImage*)srcImage;

@end
