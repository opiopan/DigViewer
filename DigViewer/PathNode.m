//
//  PathNode.m
//  DigViewer
//
//  Created by opiopan on 2013/01/05.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <quartz/Quartz.h>

#import "PathNode.h"
#import "PathfinderPinnedFile.h"
#import "NSImage+CapabilityDetermining.h"

#include <stdlib.h>

@implementation PathNode{
    NSMutableArray* representationImage;
}

@synthesize name;
@synthesize parent;
@synthesize children;
@synthesize images;
@synthesize indexInParent;
@synthesize imagePath;

//-----------------------------------------------------------------------------------------
// NSCopyingプロトコルの実装
//-----------------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
+ (PathNode*) pathNodeWithPinnedFile:(PathfinderPinnedFile*)pinnedFile
                   ommitingCondition:(PathNodeOmmitingCondition*)cond
                            progress:(PathNodeProgress*)progress
{
    PathNode* root = nil;
    NSArray* last = nil;
    NSMutableArray* context = [NSMutableArray array];
    NSUInteger lines = [pinnedFile count];
    progress.progress = 0.0;
    for (int i = 0; i < lines; i++){
        if (progress.isCanceled){
            return nil;
        }
        if ([pinnedFile isFileAtIndex:i] && [NSImage isSupportedFileAtPath:[pinnedFile relativePathAtIndex:i]] &&
            ! [cond isOmmitingImagePath:[pinnedFile relativePathAtIndex:i]]){
            NSArray* pathComponents = [[pinnedFile relativePathAtIndex:i] pathComponents];
            NSString* filePath = [pinnedFile absolutePathAtIndex:i];
            if (!root){
                root = [[PathNode alloc] initWithName:pathComponents[0] parent:nil indexInParent:0 path:nil];
                [context addObject:root];
            }
            int j;
            for (j = 1;
                 last && j < last.count - 1 && j < pathComponents.count - 1 && [last[j] isEqualToString:pathComponents[j]];
                 j++);
            [context[j - 1] mergePathComponents:pathComponents atIndex:j withPath:filePath context:context];
            last = pathComponents;
        }
        progress.progress = i * 100.0 / lines;
    }
    
    return root;
}


- (id) initWithName:(NSString*)n parent:(PathNode*)p indexInParent:(NSUInteger)ip path:(NSString*)path
{
    self = [self init];
    if (self){
        name = n;
        parent = p;
        indexInParent = ip;
        imagePath = path;
    }
    return self;
}

+ (PathNode*) pathNodeWithPath:(NSString*)path ommitingCondition:(PathNodeOmmitingCondition*)cond progress:(PathNodeProgress*)progress
{
    return [[PathNode alloc] initRecursWithPath:path parent:nil indexInParent:0 ommitingCondition:cond progress:progress];
}

- (id) initRecursWithPath:(NSString*)path parent:(PathNode*)p indexInParent:(NSUInteger)ip
        ommitingCondition:(PathNodeOmmitingCondition*)cond progress:(PathNodeProgress*)progress
{
    self = [self init];
    if (self){
        name = [path lastPathComponent];
        parent = p;
        indexInParent = ip;
        
        NSFileManager* fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]){
            if (isDirectory){
                progress.target = path;
                NSArray* childNames = [fileManager contentsOfDirectoryAtPath:path error:nil];
                for (NSString* childName in childNames){
                    if (progress.isCanceled){
                        return nil;
                    }
                    if ([childName characterAtIndex:0] == '.'){
                        continue;
                    }
                    NSString* childPath = [path stringByAppendingFormat:@"/%@", childName];
                    PathNode* child = [[PathNode alloc] initRecursWithPath:childPath
                                                                    parent:self indexInParent:0
                                                         ommitingCondition:cond
                                                                  progress:progress];
                    if (child){
                        if (child.isImage){
                            if (!images){
                                images = [[NSMutableArray alloc] init];
                            }
                            child->indexInParent = images.count;
                            [images addObject:child];
                        }else{
                            if (!children){
                                children = [[NSMutableArray alloc] init];
                            }
                            child->indexInParent = children.count;
                            [children addObject:child];
                        }
                    }
                }
                if (images.count == 0 && children.count == 0){
                    self = nil;
                }
            }else{
                if ([NSImage isSupportedFileAtPath:path] && ![cond isOmmitingImagePath:path]){
                    imagePath = path;
                }else{
                    self = nil;
                }
            }
        }else{
            self = nil;
        }
    }
    if (progress.isCanceled){
        return nil;
    }else{
        return self;
    }
}

//-----------------------------------------------------------------------------------------
// ファイルをツリーにマージ
//-----------------------------------------------------------------------------------------
- (void) mergePathComponents:(NSArray*)components atIndex:(NSUInteger)index withPath:(NSString*)path
                     context:(NSMutableArray*)context;
{
    if (index > context.count){
        [context addObject:self];
    }else{
        [context replaceObjectAtIndex:index - 1 withObject:self];
    }
    
    NSString* targetName = components[index];
    if (index == components.count - 1){
        if (!images){
            images = [[NSMutableArray alloc] init];
        }
        PathNode* newNode = [[PathNode alloc] initWithName:targetName parent:self indexInParent:images.count path:path];
        [images addObject:newNode];
    }else{
        if (!children){
            children = [[NSMutableArray alloc] init];
        }
        PathNode* child = nil;
        for (int i = 0; i < children.count; i++){
            PathNode* node = children[i];
            if ([node.name isEqualToString:targetName]){
                child = node;
                break;
            }
        }
        if (!child){
            child = [[PathNode alloc] initWithName:targetName parent:self indexInParent:children.count path:nil];
            [children addObject:child];
        }
        [child mergePathComponents:components atIndex:index + 1 withPath:path context:context];
    }
}

//-----------------------------------------------------------------------------------------
// 属性へのアクセサ
//-----------------------------------------------------------------------------------------
- (BOOL) isLeaf
{
    return children == nil;
}

- (BOOL) isImage
{
    return imagePath != nil;
}

- (PathNode*) me
{
    return self;
}

- (NSMutableArray*) images
{
    if (!representationImage){
        if (images){
            representationImage = [NSMutableArray arrayWithArray:images];
            [representationImage addObjectsFromArray:children];
        }else{
            representationImage = [NSMutableArray arrayWithArray:children];
        }
    }
    return representationImage;
}

- (PathNode*) imageNode
{
    if (imagePath){
        return self;
    }else if (images){
        return [[images objectAtIndex:0] imageNode];
    }else{
        return [[children objectAtIndex:0] imageNode];
    }
}

- (PathNode*) imageNodeReverse
{
    if (imagePath){
        return self;
    }else if (children){
        return [[children lastObject] imageNodeReverse];
    }else{
        return [[images lastObject] imageNodeReverse];
    }
}

- (NSString*) imagePath
{
    return [self imageNode]->imagePath;
}

- (NSString*) imageName
{
    return [[self imagePath] lastPathComponent];
}

- (NSImage*) image
{
    static NSImage* stockedImage = nil;
    static NSString* stockedImagePath = nil;
    NSString* path = [self imagePath];
    if (!stockedImage || ![stockedImagePath isEqualToString:path]){
        stockedImage = [[NSImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
    }
    return stockedImage;
}

- (NSUInteger) indexInParent
{
    if (imagePath){
        return indexInParent;
    }else{
        return (parent && parent->images ? parent->images.count : 0) + indexInParent;
    }
}

- (NSImage*) icon
{
    if (imagePath){
        return [[NSWorkspace sharedWorkspace] iconForFileType:[name pathExtension]];
    }else{
        return [[NSWorkspace sharedWorkspace] iconForFile:@"/var"];
    }
}

// IKImageBrowserItem Protocol
- (NSString*) imageUID
{
    return [self imagePath];
}

- (NSString*) imageRepresentationType
{
    return IKImageBrowserNSImageRepresentationType;
}

- (id) imageRepresentation
{
    return [self image];
}

- (NSString *) imageTitle
{
    return [self name];
}

//-----------------------------------------------------------------------------------------
// ツリー・ウォーキング
//-----------------------------------------------------------------------------------------
- (PathNode*) nextImageNode
{
    PathNode* currentImage = [self imageNode];
    return [currentImage->parent nextImageNodeOfImageAtIndex:[currentImage indexInParent]];
}

- (PathNode*) nextImageNodeOfImageAtIndex:(NSUInteger)index
{
    NSArray* nodes = [self images];
    if (index + 1 ==  nodes.count){
        return [parent nextImageNodeOfImageAtIndex:[self indexInParent]];
    }else{
        return [nodes[index + 1] imageNode];
    }
}

- (PathNode*) previousImageNode
{
    PathNode* currentImage = [self imageNode];
    return [currentImage->parent previousImageNodeOfImageAtIndex:[currentImage indexInParent]];
}

- (PathNode*) previousImageNodeOfImageAtIndex:(NSUInteger)index
{
    NSArray* nodes = [self images];
    if (index == 0){
        return [parent previousImageNodeOfImageAtIndex:[self indexInParent]];
    }else{
        return [nodes[index - 1] imageNodeReverse];
    }
}

- (PathNode*) nextFolderNode
{
    if (imagePath){
        return [parent nextFolderNode];
    }else{
        return [parent nextFolderNodeOfNodeAtIndex:indexInParent];
    }
}

- (PathNode*) nextFolderNodeOfNodeAtIndex:(NSUInteger)index
{
    if (index + 1 < children.count){
        return children[index + 1];
    }else{
        return [parent nextFolderNodeOfNodeAtIndex:indexInParent];
    }
}

- (PathNode*) previousFolderNode
{
    if (imagePath){
        return [parent previousFolderNode];
    }else{
        return [parent previousFolderNodeOfNodeAtIndex:indexInParent];
    }
}

- (PathNode*) previousFolderNodeOfNodeAtIndex:(NSUInteger)index
{
    if (index > 0){
        return children[index - 1];
    }else{
        return self;
    }
}


//-----------------------------------------------------------------------------------------
// IndexPath生成
//-----------------------------------------------------------------------------------------
- (NSIndexPath*) indexPath
{
    NSUInteger* indexes = nil;
    NSUInteger size = [self generateIndexesInArray:&indexes withContext:1];
    NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:indexes length:size];
    free(indexes);
    return indexPath;
}

- (NSUInteger) generateIndexesInArray:(NSUInteger**)array withContext:(NSUInteger)count
{
    if (parent){
        NSUInteger position = [parent generateIndexesInArray:array withContext:count + 1];
        if (*array){
            (*array)[position] = indexInParent;
        }
        return position + 1;
    }else{
        *array = malloc(sizeof(NSUInteger) * count);
        if (*array){
            (*array)[0] = 0;
        }
        return 1;
    }
}

@end


//-----------------------------------------------------------------------------------------
// ツリー生成進捗オブジェクト
//-----------------------------------------------------------------------------------------
@implementation PathNodeProgress{
    NSLock* lock;
}

@synthesize progress;
@synthesize target;
@synthesize isCanceled;

- (id) init
{
    self = [super init];
    if (self){
        lock = [[NSLock alloc] init];
        isCanceled = NO;
    }
    return self;
}

- (double) progress
{
    [lock lock];
    double value = progress;
    [lock unlock];
    return value;
}

- (void) setProgress:(double)value
{
    [lock lock];
    progress = value;
    [lock unlock];
}

- (NSString*) target
{
    [lock lock];
    NSString* value = target;
    [lock unlock];
    return value;
}

- (void) setTarget:(NSString *)value
{
    [lock lock];
    target = value;
    [lock unlock];
}

- (BOOL) isCanceled
{
    [lock lock];
    BOOL value = isCanceled;
    [lock unlock];
    return value;
}

- (void) setIsCanceled:(BOOL)value
{
    [lock lock];
    isCanceled = value;
    [lock unlock];
}

@end

//-----------------------------------------------------------------------------------------
// PathNodeOmmitingCondition: ノードツリー生成時の除外対象
//-----------------------------------------------------------------------------------------
@implementation PathNodeOmmitingCondition

@synthesize suffixes;
@synthesize maxFileSize;

- (BOOL) isOmmitingImagePath:(NSString*)path
{
    return [suffixes valueForKey:[[path pathExtension] lowercaseString]];
}

@end
