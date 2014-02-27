//
//  NSImage+CapabilityDetermining.m
//  DigViewer
//
//  Created by opiopan on 2013/01/06.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "NSImage+CapabilityDetermining.h"

@implementation NSImage (CapabilityDetermining)

static NSMutableDictionary* capabilities = nil;

+ (BOOL) isSupportedFileAtPath:(NSString*)path
{
    if (!capabilities){
        [NSImage buildCapabilityList];
    }
    return [capabilities valueForKey:[path pathExtension]] != nil;
}

+ (void) buildCapabilityList
{
    NSArray* types = [NSImage imageFileTypes];
    capabilities = [NSMutableDictionary dictionaryWithCapacity:types.count];
    for (int i = 0; i < types.count; i++){
        if ([types[i] characterAtIndex:0] != '\''){
            [capabilities setValue:@"supported" forKey:types[i]];
        }
    }
}
+ (NSDictionary *)rawSuffixes
{
    static NSDictionary* _rawSuffixes = nil;
    if (!_rawSuffixes){
        _rawSuffixes = @{
                         @"cr2":@"raw",
                         @"dng":@"raw",
                         @"nef":@"raw",
                         @"orf":@"raw",
                         @"dcr":@"raw",
                         @"raf":@"raw",
                         @"mrw":@"raw",
                         @"mos":@"raw",
                         @"raw":@"raw",
                         @"pef":@"raw",
                         @"srf":@"raw",
                         @"x3f":@"raw",
                         @"erf":@"raw",
                         @"sr2":@"raw",
                         @"kdc":@"raw",
                         @"mfw":@"raw",
                         @"mef":@"raw",
                         @"are":@"raw",
                         @"rw2":@"raw",
                         @"rwl":@"raw",
                         @"psd":@"cpx",
                         };
    }
    return _rawSuffixes;
}

+ (BOOL) isRawFileAtPath:(NSString*)path
{
    return [[NSImage rawSuffixes] valueForKey:[[path pathExtension] lowercaseString]] != nil;
}

@end
