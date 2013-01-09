//
//  PathfinderPinnedFile.m
//  DigViewer
//
//  Created by opiopan on 2013/01/06.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "PathfinderPinnedFile.h"

@implementation PathfinderPinnedFile {
    NSString*  path;
    NSArray*   contents;
    NSUInteger lastIndex;
    NSString*  lastAbsolutePath;
    NSString*  lastRelativePath;
}

+ (PathfinderPinnedFile*) pinnedFileWithPath:(NSString*) path
{
    NSString* pinnedFilePath = [path stringByAppendingPathComponent:@".Pathfinder.pflist"];
    NSFileManager* fm = [NSFileManager defaultManager];
    PathfinderPinnedFile* pinnedFile = nil;
    
    if ([fm isReadableFileAtPath:pinnedFilePath]){
        NSArray* contents = [[NSString stringWithContentsOfFile:pinnedFilePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil] componentsSeparatedByString:@"\n"];
        pinnedFile = [[PathfinderPinnedFile alloc] initWithPath:path contents:contents];
    }
    
    return pinnedFile;
}

- (id) initWithPath:(NSString*)p contents:(NSArray*)c
{
    self = [self init];
    if (self){
        path = p;
        contents = c;
        lastIndex = NSNotFound;
    }
    return self;
}

- (NSUInteger) count
{
    return contents.count - 1;
}

- (BOOL) isFileAtIndex:(NSUInteger)index
{
    return [contents[index] characterAtIndex:0] == 'F';
}

- (NSString*) absolutePathAtIndex:(NSUInteger)index
{
    if (lastIndex != index){
        [self reflectPathAtIndex:index];
    }
    return lastAbsolutePath;
}

- (NSString*) relativePathAtIndex:(NSUInteger)index
{
    if (lastIndex != index){
        [self reflectPathAtIndex:index];
    }
    return lastRelativePath;
}

- (void) reflectPathAtIndex:(NSUInteger) index
{
    lastIndex = index;
    lastRelativePath = nil;
    lastAbsolutePath = nil;
    
    NSString* pathCompornent = [contents[index] substringFromIndex:2];
    if (pathCompornent){
        if ([pathCompornent characterAtIndex:0] == '/'){
            lastAbsolutePath = pathCompornent;
            lastRelativePath = [pathCompornent substringFromIndex:[[path stringByDeletingLastPathComponent] length] + 1];
        }else{
            lastRelativePath = pathCompornent;
            lastAbsolutePath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:pathCompornent];
        }
    }
}

@end
