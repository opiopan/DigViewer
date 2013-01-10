//
//  PathfinderPinnedFile.h
//  DigViewer
//
//  Created by opiopan on 2013/01/06.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PathfinderPinnedFile : NSObject

@property (readonly) NSString* path;
@property (readonly) NSString* name;

+ (PathfinderPinnedFile*) pinnedFileWithPath:(NSString*) path;

- (NSUInteger) count;
- (BOOL) isFileAtIndex:(NSUInteger)index;
- (NSString*) absolutePathAtIndex:(NSUInteger)index;
- (NSString*) relativePathAtIndex:(NSUInteger)index;

@end
