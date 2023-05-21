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
@property (readonly) NSUInteger fileSize;
@property (readonly) NSUInteger currentPoint;
@property (readonly) NSUInteger currentEntry;

+ (PathfinderPinnedFile*) pinnedFileWithPath:(NSString*) path;

- (BOOL) movePointerToNextEntry;
- (BOOL) isReachedEOF;
- (BOOL) isRegularFile;
- (NSString*) absolutePath;
- (NSString*) relativePath;

@end
