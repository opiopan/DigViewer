//
//  ChildProcess.m
//  Pathfinder
//
//  Created by opiopan on 2012/12/05.
//
//

#include <stdlib.h>
#include <stdio.h>

#import "ChildProcess.h"

@implementation ChildProcess
{
    FILE* in;
}

@synthesize command;

//-----------------------------------------------------------------------------------------
// シェル向け文字列エスケープ
//-----------------------------------------------------------------------------------------
+ (NSString*)escapedString:(NSString*)str
{
    const char* src = [str UTF8String];
    char        dest[1024];
    int         i = 0;
    
    for (; *src && i < sizeof(dest) - 1; i++, src++){
        if (*src == ' ' || *src == '(' || *src == ')' || *src == '&' ||
            *src == '\\' || *src == '|' || *src == '<' || *src == '>'||
            *src == '*' || *src == '[' || *src == ']'){
            if (i + 1 >= sizeof(dest) - 1){
                break;
            }
            dest[i++] = '\\';
        }
        dest[i] = *src;
    }
    dest[i] = 0;

    return [NSString stringWithUTF8String:dest];
}

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self){
        command = [NSMutableString stringWithCapacity:512];
        in = NULL;
    }
    return self;
}

- (id)initWithFormat:(NSString*)fmt, ...
{
    self = [self init];
    if (self){
        va_list argList;
        va_start(argList, fmt);
        [self appendCommandWithFormat:fmt arguments:argList];
        va_end(argList);
    }
    return self;
}

+ (ChildProcess*)childProcessWithFormat:(NSString*)fmt, ...
{
    ChildProcess* object = [[ChildProcess alloc] init];
    if (object){
        va_list argList;
        va_start(argList, fmt);
        [object appendCommandWithFormat:fmt arguments:argList];
        va_end(argList);
    }
    return object;
}

//-----------------------------------------------------------------------------------------
//  コマンド文字列追加
//-----------------------------------------------------------------------------------------
- (void)appendCommandWithString:(NSString*)str
{
    [command appendString:str];
}

- (void)appendCommandWithFormat:(NSString*)fmt arguments:(va_list)argList
{
    [command appendString:[[NSString alloc] initWithFormat:fmt arguments:argList]];
}

- (void)appendCommandWithFormat:(NSString*)fmt, ...
{
    va_list argList;
    va_start(argList, fmt);
    [self appendCommandWithFormat:fmt arguments:argList];
    va_end(argList);
}

//-----------------------------------------------------------------------------------------
//  単純実行
//-----------------------------------------------------------------------------------------
- (int) execute
{
    return system([command UTF8String]);
}

//-----------------------------------------------------------------------------------------
//  子プロセスの標準出力を読み出すために実行
//-----------------------------------------------------------------------------------------
- (BOOL) executeForInput
{
    in = popen([command UTF8String], "r");
    return in != NULL;
}

- (NSString*)nextLine
{
    char line[2048];
    if (fgets(line, sizeof(line), in)){
        size_t length = strlen(line);
        if (line[length - 1] == '\n'){
            line[length - 1] = 0;
        }
        return [NSString stringWithUTF8String:line];
    }else{
        return nil;
    }
}

- (int) result
{
    int rc = pclose(in);
    in = NULL;
    return rc;
}

@end
