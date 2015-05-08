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

#include "CoreFoundationHelper.h"
#include <stdlib.h>
#include <sys/stat.h>

static ThumbnailConfigController* __weak thumbnailConfig;

@implementation PathNode{
    NSMutableArray* representationImage;
}

@synthesize name;
@synthesize parent;
@synthesize children;
@synthesize images;
@synthesize indexInParent;
@synthesize imagePath;
@synthesize originalPath;
@synthesize isRawImage;

//-----------------------------------------------------------------------------------------
// NSCopyingプロトコルの実装
//-----------------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

//-----------------------------------------------------------------------------------------
// イメージファイルが存在しない場合に表示するイメージ
//-----------------------------------------------------------------------------------------
+ (NSImage*) unavailableImage
{
    static NSImage* unavailableImage = nil;
    
    if (!unavailableImage){
        unavailableImage = [[NSBundle mainBundle] imageForResource:@"unavailable.png"];
    }
    
    return unavailableImage;
}

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self){
        if (!thumbnailConfig){
            thumbnailConfig = [ThumbnailConfigController sharedController];
        }
    }
    return self;
}

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
                NSString* rootpath = pinnedFile.path;
                root = [[PathNode alloc] initWithName:pathComponents[0] parent:nil indexInParent:0 path:nil originalPath:rootpath];
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


- (id) initWithName:(NSString*)n parent:(PathNode*)p indexInParent:(NSUInteger)ip
               path:(NSString*)path originalPath:(NSString*)op
{
    self = [self init];
    if (self){
        name = n;
        parent = p;
        indexInParent = ip;
        imagePath = path;
        isRawImage = path ? [NSImage isRawFileAtPath:path] : NO;
        originalPath = op;
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
        originalPath = path;
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
                    isRawImage = path ? [NSImage isRawFileAtPath:path] : NO;
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

+ (PathNode *)psudoPathNodeWithImagePath:(NSString *)path isFolder:(BOOL)isFolder
{
    PathNode* parent = nil;
    if (isFolder){
        parent = [[PathNode alloc] initWithName:@"image" parent:nil indexInParent:0 path:nil originalPath:path];
    }
    PathNode* child = [[PathNode alloc] initWithName:@"folder" parent:parent indexInParent:0 path:path originalPath:path];
    if (isFolder){
        parent->images = [NSMutableArray arrayWithArray:@[child]];
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
        if (!images){
            images = [[NSMutableArray alloc] init];
        }
        PathNode* newNode = [[PathNode alloc] initWithName:targetName parent:self indexInParent:images.count path:path
                                              originalPath:[originalPath stringByAppendingPathComponent:targetName]];
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
            child = [[PathNode alloc] initWithName:targetName parent:self indexInParent:children.count path:nil
                                      originalPath:[originalPath stringByAppendingPathComponent:targetName]];
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
    return stockedImage ? stockedImage : [PathNode unavailableImage];
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
        return [[NSWorkspace sharedWorkspace] iconForFileType:[name pathExtension].lowercaseString];
    }else{
        return [[NSWorkspace sharedWorkspace] iconForFile:@"/var"];
    }
}


//-----------------------------------------------------------------------------------------
// IKImageBrowserItem Protocolの実装
//-----------------------------------------------------------------------------------------
- (NSString*) imageUID
{
    if (self.isImage || !thumbnailConfig.isVisibleFolderIcon){
        return self.imagePath;
    }else{
        NSString* extention = [NSString stringWithFormat:@".folder:%@:%@", thumbnailConfig.folderIconSize,
                                                                           thumbnailConfig.folderIconOpacity];
        return [self.imagePath stringByAppendingString:extention];
    }
}

- (NSString*) imageRepresentationType
{
    return self.imageNode.isRawImage || !self.isImage ? IKImageBrowserCGImageRepresentationType :
                                                        IKImageBrowserNSImageRepresentationType;
}

static const CGFloat ThumbnailMaxSize = 384;

- (id) imageRepresentation
{
    PathNode* node = self.imageNode;
    
    if (node.isRawImage || !self.isImage){
        static NSDictionary* thumbnailOption = nil;
        if (!thumbnailOption){
            thumbnailOption = @{(__bridge NSString*)kCGImageSourceThumbnailMaxPixelSize:@(ThumbnailMaxSize)};
        }
        ECGImageRef thumbnail;
        if (node.isRawImage){
            NSURL* url = [NSURL fileURLWithPath:node.imagePath];
            ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
            if (!imageSource.isNULL()){
                thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)thumbnailOption);
                if (thumbnail.isNULL()){
                    thumbnail = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef)thumbnailOption);
                }
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* orientation = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                if (orientation && orientation.intValue != 1){
                    thumbnail = [self rotateImage:thumbnail to:orientation.intValue];
                }
            }else{
                thumbnail = [self CGImageFromNSImage:[PathNode unavailableImage]];
            }
        }else{
            thumbnail = [self CGImageFromNSImage:node.image];
        }
        
        if (!self.isImage && thumbnailConfig.isVisibleFolderIcon){
            thumbnail = [self compositFolderImage:thumbnail];
        }
        
        return (__bridge_transfer id)thumbnail.transferOwnership();
    }else{
        return node.image;
    }
}

- (CGImageRef) CGImageFromNSImage:(NSImage*)srcImage
{
    NSSize srcSize= srcImage.size;
    CGFloat gain = ThumbnailMaxSize / MAX(srcSize.width, srcSize.height);
    NSSize destSize;
    destSize.width = srcSize.width * gain;
    destSize.height = srcSize.height * gain;
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context(CGBitmapContextCreate(NULL, destSize.width, destSize.height, 8, 0,
                                                colorSpace, kCGImageAlphaPremultipliedLast));
    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:gc];
    NSRect targetRect = NSZeroRect;
    targetRect.size = destSize;
    [srcImage drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositeSourceOver
                fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
    return CGBitmapContextCreateImage(context);
}

- (CGImageRef) rotateImage:(CGImageRef)src to:(int)rotation
{
    // 回転後イメージを表すビットマップコンテキストを生成
    CGSize size = CGSizeMake(CGImageGetWidth(src), CGImageGetHeight(src));
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context;
    if (rotation >= 5 && rotation <= 8){
        context = CGBitmapContextCreate(NULL, size.height, size.width, 8, 0,colorSpace, kCGImageAlphaNoneSkipLast);
    }else{
        context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
    }

    // 変換行列設定
    switch (rotation){
        case 1:
        case 2:
            /* nothing to do */
            break;
        case 5:
        case 8:
            /* 90 degrees rotation */
            CGContextRotateCTM(context, M_PI / 2.);
            CGContextTranslateCTM (context, 0, -size.height);
            break;
        case 3:
        case 4:
            /* 180 degrees rotation */
            CGContextRotateCTM(context, -M_PI);
            CGContextTranslateCTM (context, size.width, size.height);
            break;
        case 6:
        case 7:
            /* 270 degrees rotation */
            CGContextRotateCTM(context, -M_PI / 2.);
            CGContextTranslateCTM (context, -size.width, 0);
            break;
    }
    
    //回転後イメージを描画
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), src);
    return CGBitmapContextCreateImage(context);
}

- (CGImageRef) compositFolderImage:(CGImageRef)src
{
    // コンポジット後のイメージを保持するビットマップコンテキストを作成
    CGFloat width = src ? CGImageGetWidth(src) : ThumbnailMaxSize;
    CGFloat height = src ? CGImageGetHeight(src) : ThumbnailMaxSize;
    CGFloat normalizedLength = MAX(width, height);
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context(CGBitmapContextCreate(NULL, normalizedLength, normalizedLength, 8, 0,
                                                colorSpace, kCGImageAlphaPremultipliedLast));
    
    // ソース画像を描画
    CGContextDrawImage(context, CGRectMake((normalizedLength - width) / 2, (normalizedLength - height) / 2, CGImageGetWidth(src), CGImageGetHeight(src)), src);
    
    // フォルダー画像を描画
    NSImage* folderImage = [NSImage imageNamed:NSImageNameFolder];
    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:gc];
    NSRect targetRect = NSZeroRect;
    targetRect.size.width = targetRect.size.height = normalizedLength * thumbnailConfig.folderIconSize.doubleValue;
    targetRect.origin.x = normalizedLength - targetRect.size.width * 1.11;
    [folderImage drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositeSourceOver
                   fraction:thumbnailConfig.folderIconOpacity.doubleValue
             respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
    
    return CGBitmapContextCreateImage(context);
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
    delete[] indexes;
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
    [parent appendNameToPortablePath:path];
    [path addObject:name];
}

- (PathNode*) nearestNodeAtPortablePath:(NSArray*)path
{
    if ([name isEqualToString:path[0]] && path.count > 1){
        return [self nearestNodeAtPortablePath:path indexAt:1];
    }else{
        return self;
    }
}

- (PathNode*) nearestNodeAtPortablePath:(NSArray*)path indexAt:(NSInteger)index
{
    NSString* searchingName = path[index];
    PathNode* candidate = nil;
    for (candidate in children){
        if ([candidate.name isEqualToString:searchingName]){
            if (path.count == index + 1){
                return candidate;
            }else{
                return [candidate nearestNodeAtPortablePath:path indexAt:index + 1];
            }
        }
    }
    for (candidate in images){
        if ([candidate.name isEqualToString:searchingName]){
            return candidate;
        }
    }
    
    if (children && children.count > 0){
        return children[0];
    }else if (images && images.count > 0){
        return images[0];
    }else{
        return self;
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
        rc = ([suffixes valueForKey:[[path pathExtension] lowercaseString]] != nil);
    }
    if (!rc && self.maxFileSize > 0){
        struct stat buf;
        if (stat(path.UTF8String, &buf) != -1 && buf.st_size > maxFileSize){
            rc = YES;
        }
    }
    return rc;
}

@end
