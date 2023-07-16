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
@interface PathNode : NSObject

// 属性
@property (nonatomic) enum PathNodeSortType sortType;
@property (nonatomic) BOOL isSortByCaseInsensitive;
@property (nonatomic) BOOL isSortAsNumeric;
@property (nonatomic) BOOL isSortByDateTime;

@property (nonatomic, readonly) NSString*       name;
@property (nonatomic, readonly) PathNode*       me;
@property (nonatomic, readonly, weak) PathNode* parent;
@property (nonatomic, readonly) NSArray*        children;
@property (nonatomic, readonly) BOOL            isLeaf;
@property (nonatomic, readonly) BOOL            isImage;
@property (nonatomic, readonly) BOOL            isRawImage;
@property (nonatomic, readonly) BOOL            isRasterImage;
@property (nonatomic, readonly) BOOL            isPhotosLibraryImage;
@property (nonatomic, readonly) NSArray*        images;
@property (nonatomic, readonly) NSUInteger      indexInParent;
@property (nonatomic, readonly) PathNode*       imageNode;
@property (nonatomic, readonly) PathNode*       imageNodeReverse;
@property (nonatomic, readonly) NSString*       imagePath;
@property (nonatomic, readonly) NSString*       imageName;
@property (nonatomic, readonly) NSImage*        image;
@property (nonatomic, readonly) NSImage*        icon;
@property (nonatomic, readonly) id              iconAndName;
@property (nonatomic, readonly) NSString*       originalPath;

@property (nonatomic) NSString*                 imageDateTime;

@property (nonatomic, readonly) NSString*       imageUID;
@property (nonatomic, readonly) NSString*       imageRepresentationType;
@property (nonatomic, readonly) id              imageRepresentation;

// オブジェクト初期化
+ (PathNode*) pathNodeWithPath:(NSString*)path
             ommitingCondition:(PathNodeOmmitingCondition*)cond
                        option:(PathNodeCreateOption*)option
                      progress:(PathNodeProgress*)progress;
+ (PathNode*) pathNodeWithPinnedFile:(PathfinderPinnedFile*)pinnedFile
                   ommitingCondition:(PathNodeOmmitingCondition*)cond
                              option:(PathNodeCreateOption*)option
                            progress:(PathNodeProgress*)progress;
+ (PathNode*) pathNodeForPhotosLibraryWithName:(NSString*)name
                              omitingCondition:(PathNodeOmmitingCondition*)cond
                                        option:(PathNodeCreateOption*)option
                                      progress:(PathNodeProgress*)progress;
+ (PathNode*) psudoPathNodeWithName:(NSString*)name imagePath:(NSString*)path isFolder:(BOOL)isFolder;

// stock image accesser
+ (NSImage*) unavailableImage;
+ (NSImage*) processingImage;
+ (NSImage*) corruptedImage;

// ツリーウォーキング
- (PathNode*) nextImageNode;
- (PathNode*) previousImageNode;
- (PathNode*) nextFolderNode;
- (PathNode*) previousFolderNode;

// サムネール生成
- (void)setThumbnailCache:(id)thumbnailCache withDocument:(id)document;
- (id) thumbnailImage:(CGFloat)thumbnailSize;
- (void) updateThumbnailCounter;

// asynchronous operation
- (void) instanciateImageDataWithCompletion: (void (^)(NSData* data, NSString* uti))completion;

// IndexPath作成
- (NSIndexPath*) indexPath;

// portabilityがあるパスに対する操作
- (NSArray*) portablePath;
- (PathNode*) nearestNodeAtPortablePath:(NSArray*)path;

@end
