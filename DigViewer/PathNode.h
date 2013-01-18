//
//  PathNode.h
//  DigViewer
//
//  Created by opiopan on 2013/01/05.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NodeID.h"
#import "PathfinderPinnedFile.h"

@interface PathNodeProgress : NSObject
@property double progress;
@end

@interface PathNode : NSObject

// 属性
@property (readonly) NSString*       name;
@property (readonly) PathNode*       me;
@property (readonly, weak) PathNode* parent;
@property (readonly) NSMutableArray* children;
@property (readonly) BOOL            isLeaf;
@property (readonly) BOOL            isImage;
@property (readonly) NSMutableArray* images;
@property (readonly) NSUInteger      indexInParent;
@property (readonly) PathNode*       imageNode;
@property (readonly) PathNode*       imageNodeReverse;
@property (readonly) NSString*       imagePath;
@property (readonly) NSString*       imageName;
@property (readonly) NSImage*        image;
@property (readonly) NSImage*        icon;
@property (readonly) NodeID*         nodeID;
@property (readonly) NodeID*         imageID;

@property (readonly) NSString*       imageUID;
@property (readonly) NSString*       imageRepresentationType;
@property (readonly) id              imageRepresentation;

// オブジェクト初期化
+ (PathNode*) pathNodeWithPath:(NSString*)path progress:(PathNodeProgress*)progress;
+ (PathNode*) pathNodeWithPinnedFile:(PathfinderPinnedFile*)pinnedFile progress:(PathNodeProgress*)progress;

// ツリーウォーキング
- (PathNode*) nextImageNode;
- (PathNode*) previousImageNode;
- (PathNode*) nextFolderNode;
- (PathNode*) previousFolderNode;

// IndexPath作成
- (NSIndexPath*) indexPath;

@end
