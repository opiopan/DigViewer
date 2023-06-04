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
#import "ThumbnailConfigController.h"
#import "ImageMetadata.h"
#import "ThumbnailCache.h"
#import "Document.h"

#include "CoreFoundationHelper.h"
#include <stdlib.h>
#include <sys/stat.h>

//-----------------------------------------------------------------------------------------
// Cache manager holder
//-----------------------------------------------------------------------------------------
@interface CacheManager: NSObject
@property ThumbnailCache* thumbnailCache;
@property __weak Document* document;
@end

@implementation CacheManager
@end

//-----------------------------------------------------------------------------------------
// imprementation of PathNode
//-----------------------------------------------------------------------------------------
static ThumbnailConfigController* __weak _thumbnailConfig;

@implementation PathNode{
    PathNode* __weak _rootNode;
    struct {
        NSInteger           updateCountForType;
        NSInteger           updateCountForSort;
        PathNodeSortType    sortType;
        BOOL                sortByCaseInsensitive;
        BOOL                sortAsNumeric;
    }_graphConfig;
    NSUInteger      _indexInParentForAllNodes;
    NSUInteger      _indexInParentForSameKind;
    NSArray*        _allChildren;
    NSArray*        _folderChildren;
    NSArray*        _imageChildren;
    NSArray*        _representationImages;
    NSInteger       _updateCountForRepresentationImages;
    NSInteger       _updateCountForSort;
    BOOL            _isSortByDateTimeForRepresentationImages;
    CacheManager*   _caches;
    NSUInteger      _thumbnailUpdateCounter;
    BOOL            _isPendingThumbnailViewUpdating;
}

@synthesize name = _name;
@synthesize parent = _parent;
@synthesize imagePath = _imagePath;
@synthesize originalPath = _originalPath;
@synthesize isRawImage = _isRawImage;

//-----------------------------------------------------------------------------------------
// stock images
//-----------------------------------------------------------------------------------------
+ (NSImage*) unavailableImage
{
    static NSImage* _unavailableImage = nil;
    
    if (!_unavailableImage){
        _unavailableImage = [[NSBundle mainBundle] imageForResource:@"unavailable.png"];
    }
    
    return _unavailableImage;
}

+ (NSImage*) processingImage
{
    static NSImage* _processingImage = nil;
    
    if (!_processingImage){
        _processingImage = [[NSBundle mainBundle] imageForResource:@"processing.png"];
    }
    
    return _processingImage;
}

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self){
        if (!_thumbnailConfig){
            _thumbnailConfig = [ThumbnailConfigController sharedController];
        }
        _indexInParentForAllNodes = -1;
        _indexInParentForSameKind = -1;
        _updateCountForRepresentationImages = -1;
        _updateCountForSort = -1;
        _isSortByDateTime = NO;
        _isSortByDateTimeForRepresentationImages = NO;
        _graphConfig.updateCountForType = 0;
        _graphConfig.updateCountForSort = 0;
        _graphConfig.sortType = SortTypeImageIsPrior;
        _graphConfig.sortByCaseInsensitive = YES;
        _graphConfig.sortAsNumeric = YES;
        _thumbnailUpdateCounter = 0;
        _isPendingThumbnailViewUpdating = NO;
    }
    return self;
}

+ (PathNode*) pathNodeWithPinnedFile:(PathfinderPinnedFile*)pinnedFile
                   ommitingCondition:(PathNodeOmmitingCondition*)cond
                              option:(PathNodeCreateOption*)option
                            progress:(PathNodeProgress*)progress
{
    PathNode* root = nil;
    NSArray* last = nil;
    NSMutableArray* context = [NSMutableArray array];
    NSUInteger fileSize = [pinnedFile fileSize];
    progress.progress = 0.0;
    for (; !pinnedFile.isReachedEOF; [pinnedFile movePointerToNextEntry]){
        if (progress.isCanceled){
            return nil;
        }
        if (pinnedFile.isRegularFile && [NSImage isSupportedFileAtPath:pinnedFile.relativePath] &&
            ! [cond isOmmitingImagePath:pinnedFile.relativePath]){
            NSArray* pathComponents = [pinnedFile.relativePath pathComponents];
            NSString* filePath = pinnedFile.absolutePath;
            if (!root){
                NSString* rootpath = pinnedFile.path;
                root = [[PathNode alloc] initWithName:pathComponents[0] parent:nil path:nil originalPath:rootpath];
                [context addObject:root];
            }
            int j;
            for (j = 1;
                 last && j < last.count - 1 && j < pathComponents.count - 1 && [last[j] isEqualToString:pathComponents[j]];
                 j++);
            [context[j - 1] mergePathComponents:pathComponents atIndex:j withPath:filePath context:context];
            last = pathComponents;
        }
        progress.progress = pinnedFile.currentPoint * 100.0 / fileSize;
    }
    
    return root;
}


- (id) initWithName:(NSString*)n parent:(PathNode*)p path:(NSString*)path originalPath:(NSString*)op
{
    self = [self init];
    if (self){
        _name = n;
        _parent = p;
        _imagePath = path;
        _isRawImage = path ? [NSImage isRawFileAtPath:path] : NO;
        _isRasterImage = path ? [NSImage isRasterImageAtPath:path] : NO;
        _originalPath = op;
        _rootNode = _parent ? _parent->_rootNode : self;
        _caches = _parent? _parent->_caches : [CacheManager new];
        if (!_parent){
            _indexInParentForSameKind = 0;
            _indexInParentForAllNodes = 0;
        }
    }
    return self;
}

+ (PathNode*) pathNodeWithPath:(NSString*)path ommitingCondition:(PathNodeOmmitingCondition*)cond
                        option:(PathNodeCreateOption*)option
                      progress:(PathNodeProgress*)progress
{
    return [[PathNode alloc] initRecursWithPath:path parent:nil ommitingCondition:cond option:option progress:progress];
}

- (id) initRecursWithPath:(NSString*)path parent:(PathNode*)p
        ommitingCondition:(PathNodeOmmitingCondition*)cond
                   option:(PathNodeCreateOption*)option
                 progress:(PathNodeProgress*)progress
{
    self = [self init];
    if (self){
        _name = [path lastPathComponent];
        _originalPath = path;
        _parent = p;
        _rootNode = _parent ? _parent->_rootNode : self;
        _caches = _parent ? _parent->_caches : [CacheManager new];
        if (!_parent){
            _indexInParentForSameKind = 0;
            _indexInParentForAllNodes = 0;
            _graphConfig.sortByCaseInsensitive = option->isSortByCaseInsensitive;
            _graphConfig.sortAsNumeric = option->isSortAsNumeric;
        }
        _updateCountForSort = _rootNode->_graphConfig.updateCountForSort;
        
        NSFileManager* fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]){
            if (isDirectory){
                progress.target = path;
                NSArray* childNames = [fileManager contentsOfDirectoryAtPath:path error:nil];
                NSStringCompareOptions sortOption = option->isSortByCaseInsensitive ? NSCaseInsensitiveSearch : 0;
                sortOption |= option->isSortAsNumeric ? NSNumericSearch : 0;
                childNames = [childNames sortedArrayUsingComparator:^(NSString* o1, NSString* o2){
                    return [o1 compare:o2 options:sortOption];
                }];
                for (NSInteger i = 0; i < childNames.count; i++){
                    NSString* childName = childNames[i];
                    if (progress.isCanceled){
                        return nil;
                    }
                    if ([childName characterAtIndex:0] == '.'){
                        continue;
                    }
                    NSString* childPath = [path stringByAppendingFormat:@"/%@", childName];
                    PathNode* child = [[PathNode alloc] initRecursWithPath:childPath
                                                                    parent:self
                                                         ommitingCondition:cond
                                                                    option:option
                                                                  progress:progress];
                    if (child){
                        if (!_allChildren){
                            _allChildren = [[NSMutableArray alloc] init];
                        }
                        child->_indexInParentForAllNodes = _allChildren.count;
                        [(NSMutableArray*)_allChildren addObject:child];
                        if (child.isImage){
                            if (!_imageChildren){
                                _imageChildren = [[NSMutableArray alloc] init];
                            }
                            child->_indexInParentForSameKind = _imageChildren.count;
                            [(NSMutableArray*)_imageChildren addObject:child];
                        }else{
                            if (!_folderChildren){
                                _folderChildren = [[NSMutableArray alloc] init];
                            }
                            child->_indexInParentForSameKind = _folderChildren.count;
                            [(NSMutableArray*)_folderChildren addObject:child];
                        }
                    }
                }
                if (_imageChildren.count == 0 && _folderChildren.count == 0){
                    self = nil;
                }
            }else{
                if ([NSImage isSupportedFileAtPath:path] && ![cond isOmmitingImagePath:path]){
                    _imagePath = path;
                    _isRawImage = path ? [NSImage isRawFileAtPath:path] : NO;
                    _isRasterImage = path ? [NSImage isRasterImageAtPath:path] : NO;
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

+ (PathNode *)psudoPathNodeWithName:(NSString *)name imagePath:(NSString *)path isFolder:(BOOL)isFolder
{
    PathNode* parent = nil;
    if (isFolder){
        parent = [[PathNode alloc] initWithName:name parent:nil path:nil originalPath:path];
    }
    PathNode* child = [[PathNode alloc] initWithName:name parent:parent path:path originalPath:path];
    if (isFolder){
        parent->_imageChildren = [NSMutableArray arrayWithArray:@[child]];
        return parent;
    }else{
        return child;
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
        if (!_imageChildren){
            _imageChildren = [[NSMutableArray alloc] init];
        }
        if (!_allChildren){
            _allChildren = [[NSMutableArray alloc] init];
        }
        PathNode* newNode = [[PathNode alloc] initWithName:targetName parent:self path:path
                                              originalPath:[_originalPath stringByAppendingPathComponent:targetName]];
        [(NSMutableArray*)_imageChildren addObject:newNode];
        [(NSMutableArray*)_allChildren addObject:newNode];
    }else{
        if (!_folderChildren){
            _folderChildren = [[NSMutableArray alloc] init];
        }
        if (!_allChildren){
            _allChildren = [[NSMutableArray alloc] init];
        }
        PathNode* child = nil;
        for (int i = 0; i < _folderChildren.count; i++){
            PathNode* node = _folderChildren[i];
            if ([node.name isEqualToString:targetName]){
                child = node;
                break;
            }
        }
        if (!child){
            child = [[PathNode alloc] initWithName:targetName parent:self path:nil
                                      originalPath:[_originalPath stringByAppendingPathComponent:targetName]];
            [(NSMutableArray*)_folderChildren addObject:child];
            [(NSMutableArray*)_allChildren addObject:child];
        }
        [child mergePathComponents:components atIndex:index + 1 withPath:path context:context];
    }
}

//-----------------------------------------------------------------------------------------
// 子ノードのソート
//-----------------------------------------------------------------------------------------
- (void)sortChildren
{
    if (_updateCountForSort != _rootNode->_graphConfig.updateCountForSort ||
        _isSortByDateTime != _isSortByDateTimeForRepresentationImages){
        NSStringCompareOptions sortOption = _rootNode->_graphConfig.sortByCaseInsensitive ? NSCaseInsensitiveSearch : 0;
        sortOption |= _rootNode->_graphConfig.sortAsNumeric ? NSNumericSearch : 0;
        NSComparisonResult (^comparator)(PathNode* o1, PathNode* o2) = ^(PathNode* o1, PathNode* o2){
            return [o1.name compare:o2.name options:sortOption];
        };
        BOOL needSortByDateTime = _isSortByDateTime;
        NSComparisonResult (^comparatorForImage)(PathNode* o1, PathNode* o2) = ^(PathNode* o1, PathNode* o2){
            if(needSortByDateTime){
                NSComparisonResult rc = [o1.imageDateTime compare:o2.imageDateTime];
                if (rc != NSOrderedSame){
                    return rc;
                }
            }
            return [o1.name compare:o2.name options:sortOption];
        };
        _allChildren = [_allChildren sortedArrayUsingComparator:comparator];
        _folderChildren = [_folderChildren sortedArrayUsingComparator:comparator];
        _imageChildren = [_imageChildren sortedArrayUsingComparator:comparatorForImage];
        for (NSInteger i = 0; i < _allChildren.count; i++){
            PathNode* node = _allChildren[i];
            node->_indexInParentForAllNodes = i;
        }
        for (NSInteger i = 0; i < _folderChildren.count; i++){
            PathNode* node = _folderChildren[i];
            node->_indexInParentForSameKind = i;
        }
        for (NSInteger i = 0; i < _imageChildren.count; i++){
            PathNode* node = _imageChildren[i];
            node->_indexInParentForSameKind = i;
        }
        _updateCountForSort = _rootNode->_graphConfig.updateCountForSort;
    }
}

//-----------------------------------------------------------------------------------------
// ソート設定属性へのアクセサ
//-----------------------------------------------------------------------------------------
- (void)setSortType:(enum PathNodeSortType)sortType
{
    if (_rootNode){
        _rootNode->_graphConfig.sortType = sortType;
        _rootNode->_graphConfig.updateCountForType++;
    }
}

- (enum PathNodeSortType)sortType
{
    return _rootNode ? _rootNode->_graphConfig.sortType : SortTypeImageIsPrior;
}

- (void)setIsSortByCaseInsensitive:(BOOL)isSortByCaseInsensitive
{
    if (_rootNode){
        _rootNode->_graphConfig.sortByCaseInsensitive = isSortByCaseInsensitive;
        _rootNode->_graphConfig.updateCountForType++;
        _rootNode->_graphConfig.updateCountForSort++;
    }
}

- (BOOL)isSortByCaseInsensitive
{
    return _rootNode ? _graphConfig.sortByCaseInsensitive : YES;
}

- (void)setIsSortAsNumeric:(BOOL)isSortAsNumeric
{
    if (_rootNode){
        _rootNode->_graphConfig.sortAsNumeric = isSortAsNumeric;
        _rootNode->_graphConfig.updateCountForType++;
        _rootNode->_graphConfig.updateCountForSort++;
    }
}

- (BOOL)isSortAsNumeric
{
    return _rootNode ? _graphConfig.sortAsNumeric : YES;
}

//-----------------------------------------------------------------------------------------
// 属性へのアクセサ
//-----------------------------------------------------------------------------------------
- (BOOL) isLeaf
{
    return _folderChildren == nil;
}

- (BOOL) isImage
{
    return _imagePath != nil;
}

- (PathNode*) me
{
    return self;
}

- (NSArray*) children
{
    [self sortChildren];
    return _folderChildren;
}

- (NSArray*) images
{
    if (!_representationImages || _rootNode->_graphConfig.updateCountForType != _updateCountForRepresentationImages ||
        _isSortByDateTime != _isSortByDateTimeForRepresentationImages){
        [self sortChildren];
        _updateCountForRepresentationImages = _rootNode->_graphConfig.updateCountForType;
        _isSortByDateTimeForRepresentationImages = _isSortByDateTime;
        if (_rootNode->_graphConfig.sortType == SortTypeImageIsPrior){
            _representationImages = _imageChildren ? [_imageChildren arrayByAddingObjectsFromArray:_folderChildren] :
                                                     _folderChildren;
        }else if (_rootNode->_graphConfig.sortType == SortTypeFolderIsPrior){
            _representationImages = _folderChildren ? [_folderChildren arrayByAddingObjectsFromArray:_imageChildren] :
                                                     _imageChildren;
        }else{
            _representationImages = _allChildren;
        }
    }
    return _representationImages;
}

- (PathNode*) imageNode
{
    if (_imagePath){
        return self;
    }else{
        PathNode* firstChild = self.images.firstObject;
        return firstChild.imageNode;
    }
}

- (PathNode*) imageNodeReverse
{
    if (_imagePath){
        return self;
    }else{
        PathNode* lastChild = self.images.lastObject;
        return lastChild.imageNodeReverse;
    }
}

- (NSString*) imagePath
{
    return [self imageNode]->_imagePath;
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
    return stockedImage ? stockedImage : [PathNode unavailableImage];
}

- (NSUInteger) indexInParent
{
    [_parent sortChildren];
    if (_rootNode->_graphConfig.sortType == SortTypeImageIsPrior){
        if (_imagePath){
            return _indexInParentForSameKind;
        }else{
            return (_parent && _parent->_imageChildren ? _parent->_imageChildren.count : 0) + _indexInParentForSameKind;
        }
    }else if (_rootNode->_graphConfig.sortType == SortTypeFolderIsPrior){
        if (_imagePath){
            return (_parent && _parent->_folderChildren ? _parent->_folderChildren.count : 0) + _indexInParentForSameKind;
        }else{
            return _indexInParentForSameKind;
        }
    }else{
        return _indexInParentForAllNodes;
    }
}

- (NSImage*) icon
{
    if (_imagePath){
        return [[NSWorkspace sharedWorkspace] iconForFileType:[_name pathExtension].lowercaseString];
    }else{
        return [[NSWorkspace sharedWorkspace] iconForFile:@"/var/log"];
    }
}

- (id)iconAndName
{
    return @{@"icon": self.icon, @"name": self.name};
}

- (NSString *)imageDateTime
{
    if (!_imageDateTime){
        _imageDateTime = dateTimeOfImage(self);
    }
    return _imageDateTime;
}

//-----------------------------------------------------------------------------------------
// IKImageBrowserItem Protocolの実装
//-----------------------------------------------------------------------------------------
- (NSString*) imageUID
{
    BOOL useEmbeddedThumbs = (self.imageNode.isRawImage && _thumbnailConfig.useEmbeddedThumbnailForRAW) ||
                             (!self.imageNode.isRawImage && self.imageNode.isRasterImage && _thumbnailConfig.useEmbeddedThumbnail);
    if (self.isImage || _thumbnailConfig.representationType == FolderThumbnailOnlyImage){
        NSString* extention = [NSString stringWithFormat:@".file:%d:%lu", useEmbeddedThumbs, (unsigned long)_thumbnailUpdateCounter];
        return [self.imagePath stringByAppendingString:extention];
    }else if (_thumbnailConfig.representationType == FolderThumbnailImageInIcon){
        NSString* extention = [NSString stringWithFormat:@".folder:%d:%lu", useEmbeddedThumbs, (unsigned long)_thumbnailUpdateCounter];
        return [self.imagePath stringByAppendingString:extention];
    }else{
        NSString* extention = [NSString stringWithFormat:@".folder:%d:%@:%@:%lu", useEmbeddedThumbs,
                                                                                  _thumbnailConfig.folderIconSize,
                                                                                  _thumbnailConfig.folderIconOpacity,
                                                                                  _thumbnailUpdateCounter];
        return [self.imagePath stringByAppendingString:extention];
    }
}

- (NSString*) imageRepresentationType
{
    return IKImageBrowserCGImageRepresentationType;
}

- (id) imageRepresentation
{
    return [self thumbnailImage:0 waitUntilDone:NO];
}

- (void)setThumbnailCache:(id)thumbnailCache withDocument:(id)document
{
    _caches.thumbnailCache = thumbnailCache;
    _caches.document = document;
}

static const CGFloat ThumbnailMaxSizeDefault = 384;

- (id) thumbnailImage:(CGFloat)thumbnailSize
{
    return [self thumbnailImage:thumbnailSize waitUntilDone:YES];
}

- (id) thumbnailImage:(CGFloat)thumbnailSize waitUntilDone:(BOOL)sync
{
    CGFloat ThumbnailMaxSize = thumbnailSize == 0 ? ThumbnailMaxSizeDefault : thumbnailSize;
    
    ECGImageRef thumbnail;
    if (!sync && _caches.thumbnailCache){
        thumbnail = [_caches.thumbnailCache getThumbnailImageOf:self completion:^(PathNode* node){
            [node performSelectorOnMainThread:@selector(notifyUpdatedThumnailImage) withObject:nil waitUntilDone:NO];
        }];
    }else{
        thumbnail = [ThumbnailCache getThumbnailImageOf:self size:ThumbnailMaxSize];
    }
    
    return (__bridge_transfer id)thumbnail.transferOwnership();
}

- (void) updateThumbnailCounter
{
    _thumbnailUpdateCounter++;
}

- (void) notifyUpdatedThumnailImage
{
    _thumbnailUpdateCounter++;
    if (!_isPendingThumbnailViewUpdating){
        [self performSelector:@selector(updateThumbnailView) withObject:nil afterDelay:0.4];
        _isPendingThumbnailViewUpdating = YES;
    }
}

- (void) updateThumbnailView
{
    _isPendingThumbnailViewUpdating = NO;
    [_caches.document updateThumbnailCacheCounter];
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
    return [currentImage->_parent nextImageNodeOfImageAtIndex:[currentImage indexInParent]];
}

- (PathNode*) nextImageNodeOfImageAtIndex:(NSUInteger)index
{
    NSArray* nodes = [self images];
    if (index + 1 ==  nodes.count){
        return [_parent nextImageNodeOfImageAtIndex:[self indexInParent]];
    }else{
        return [nodes[index + 1] imageNode];
    }
}

- (PathNode*) previousImageNode
{
    PathNode* currentImage = [self imageNode];
    return [currentImage->_parent previousImageNodeOfImageAtIndex:[currentImage indexInParent]];
}

- (PathNode*) previousImageNodeOfImageAtIndex:(NSUInteger)index
{
    NSArray* nodes = [self images];
    if (index == 0){
        return [_parent previousImageNodeOfImageAtIndex:[self indexInParent]];
    }else{
        return [nodes[index - 1] imageNodeReverse];
    }
}

- (PathNode*) nextFolderNode
{
    if (_imagePath){
        return [_parent nextFolderNode];
    }else{
        return [_parent nextFolderNodeOfNodeAtIndex:_indexInParentForSameKind];
    }
}

- (PathNode*) nextFolderNodeOfNodeAtIndex:(NSUInteger)index
{
    if (index + 1 < _folderChildren.count){
        return _folderChildren[index + 1];
    }else{
        return [_parent nextFolderNodeOfNodeAtIndex:_indexInParentForSameKind];
    }
}

- (PathNode*) previousFolderNode
{
    if (_imagePath){
        return [_parent previousFolderNode];
    }else{
        return [_parent previousFolderNodeOfNodeAtIndex:_indexInParentForSameKind];
    }
}

- (PathNode*) previousFolderNodeOfNodeAtIndex:(NSUInteger)index
{
    if (index > 0){
        return _folderChildren[index - 1];
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
    delete[] indexes;
    return indexPath;
}

- (NSUInteger) generateIndexesInArray:(NSUInteger**)array withContext:(NSUInteger)count
{
    if (_parent){
        NSUInteger position = [_parent generateIndexesInArray:array withContext:count + 1];
        if (*array){
            (*array)[position] = _indexInParentForSameKind;
        }
        return position + 1;
    }else{
        *array = new NSUInteger[count];
        if (*array){
            (*array)[0] = 0;
        }
        return 1;
    }
}

//-----------------------------------------------------------------------------------------
// portabilityがあるパスに対する操作
//-----------------------------------------------------------------------------------------
- (NSArray*) portablePath
{
    NSMutableArray* path = [[NSMutableArray alloc] init];
    [self appendNameToPortablePath:path];
    return path;
}

- (void) appendNameToPortablePath:(NSMutableArray*)path
{
    [_parent appendNameToPortablePath:path];
    [path addObject:_name];
}

- (PathNode*) nearestNodeAtPortablePath:(NSArray*)path
{
    if ([_name isEqualToString:path[0]] && path.count > 1){
        return [self nearestNodeAtPortablePath:path indexAt:1];
    }else{
        return self;
    }
}

- (PathNode*) nearestNodeAtPortablePath:(NSArray*)path indexAt:(NSInteger)index
{
    NSString* searchingName = path[index];
    PathNode* candidate = nil;
    for (candidate in self.images){
        if ([candidate.name isEqualToString:searchingName]){
            if (candidate.isImage || path.count == index + 1){
                return candidate;
            }else{
                return [candidate nearestNodeAtPortablePath:path indexAt:index + 1];
            }
        }
    }

    return self.images.count > 0 ? self.images.firstObject : self;
}

@end


//-----------------------------------------------------------------------------------------
// ツリー生成進捗オブジェクト
//-----------------------------------------------------------------------------------------
@implementation PathNodeProgress{
    NSLock* _lock;
}

@synthesize progress = _progress;
@synthesize target = _target;
@synthesize isCanceled = _isCanceled;

- (id) init
{
    self = [super init];
    if (self){
        _lock = [[NSLock alloc] init];
        _isCanceled = NO;
    }
    return self;
}

- (double) progress
{
    [_lock lock];
    double value = _progress;
    [_lock unlock];
    return value;
}

- (void) setProgress:(double)value
{
    [_lock lock];
    _progress = value;
    [_lock unlock];
}

- (NSString*) target
{
    [_lock lock];
    NSString* value = _target;
    [_lock unlock];
    return value;
}

- (void) setTarget:(NSString *)value
{
    [_lock lock];
    _target = value;
    [_lock unlock];
}

- (BOOL) isCanceled
{
    [_lock lock];
    BOOL value = _isCanceled;
    [_lock unlock];
    return value;
}

- (void) setIsCanceled:(BOOL)value
{
    [_lock lock];
    _isCanceled = value;
    [_lock unlock];
}

@end

//-----------------------------------------------------------------------------------------
// PathNodeOmmitingCondition: ノードツリー生成時の除外対象
//-----------------------------------------------------------------------------------------
@implementation PathNodeOmmitingCondition

@synthesize suffixes = _suffixes;
@synthesize maxFileSize = _maxFileSize;

- (id) init
{

    self = [super init];
    if (self){
        self.isOmmitingRawImage = NO;
        self.maxFileSize = -1;
    }
    return self;
}

- (BOOL) isOmmitingImagePath:(NSString*)path
{
    BOOL rc = NO;
    if (self.isOmmitingRawImage){
        rc = [NSImage isRawFileAtPath:path];
    }
    if (!rc){
        rc = ([_suffixes valueForKey:[[path pathExtension] lowercaseString]] != nil);
    }
    if (!rc && self.maxFileSize > 0){
        struct stat buf;
        if (stat(path.UTF8String, &buf) != -1 && buf.st_size > _maxFileSize){
            rc = YES;
        }
    }
    return rc;
}

@end
