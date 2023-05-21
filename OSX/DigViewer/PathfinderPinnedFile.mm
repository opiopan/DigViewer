//
//  PathfinderPinnedFile.mm
//  DigViewer
//
//  Created by opiopan on 2013/01/06.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "PathfinderPinnedFile.h"

#include <memory>
#include <string>
#include <fstream>

struct cpp_context{
    std::ifstream is;
    std::string current_line;
    uint64_t current_entry_num {0};
    std::ifstream::pos_type file_size {0};
    bool reachedEOF {false};
    
    cpp_context(const char* path): is(path){}
};

@implementation PathfinderPinnedFile {
    std::unique_ptr<cpp_context> cpp;
    NSString* absolute_path;
    NSString* relative_path;
}

+ (PathfinderPinnedFile*) pinnedFileWithPath:(NSString*) path
{
    NSString* pinnedFilePath = [path stringByAppendingPathComponent:@".Pathfinder.pflist"];
    NSFileManager* fm = [NSFileManager defaultManager];
    PathfinderPinnedFile* pinnedFile = nil;
    
    if ([fm isReadableFileAtPath:pinnedFilePath]){
        pinnedFile = [[PathfinderPinnedFile alloc] initWithPath:path pinnedFilePath:pinnedFilePath];
    }
    
    return pinnedFile;
}

- (id) initWithPath:(NSString*)p pinnedFilePath:(NSString*)pp
{
    self = [self init];
    if (self){
        _path = p;
        cpp = std::make_unique<cpp_context>([pp UTF8String]);
        cpp->is.seekg(0, std::ios_base::end);
        cpp->file_size = cpp->is.tellg();
        cpp->is.seekg(0, std::ios_base::beg);
        [self movePointerToNextEntry];
    }
    return self;
}

- (NSUInteger) fileSize
{
    return cpp->file_size;
}

- (NSUInteger) currentPoint
{
    return cpp->reachedEOF ? cpp->file_size : cpp->is.tellg();
}

- (NSUInteger) currentEntry
{
    return cpp->current_entry_num;
}

- (BOOL) movePointerToNextEntry
{
    if (!cpp->reachedEOF){
        do{
            if (std::getline(cpp->is, cpp->current_line, '\n')){
                cpp->current_entry_num++;
                if (cpp->current_line.data()[2] == '/'){
                    absolute_path = [NSString stringWithUTF8String:cpp->current_line.c_str() + 2];
                    relative_path = [absolute_path substringFromIndex:[[_path stringByDeletingLastPathComponent] length] + 1];
                }else{
                    relative_path = [NSString stringWithUTF8String:cpp->current_line.c_str() + 2];
                    absolute_path = [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:relative_path];
                }
            }else{
                cpp->reachedEOF = true;
                cpp->is.close();
            }
        }while (!cpp->reachedEOF && cpp->current_line.size() == 0);
    }
    return !cpp->reachedEOF;
}

- (BOOL) isReachedEOF
{
    return cpp->reachedEOF;
}

- (BOOL) isRegularFile
{
    return cpp->reachedEOF ? FALSE : cpp->current_line.data()[0] == 'F';
}

- (NSString*) absolutePath
{
    return cpp->reachedEOF ? nil : absolute_path;
}

- (NSString*) relativePath
{
    return cpp->reachedEOF ? nil : relative_path;
}

@end
