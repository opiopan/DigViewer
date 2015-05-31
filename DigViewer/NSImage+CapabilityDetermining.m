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
    NSString* extention = [[path pathExtension] lowercaseString];
    return [capabilities valueForKey:extention] != nil;
}

+ (void) buildCapabilityList
{
    NSArray* types = [NSImage imageFileTypes];
    capabilities = [NSMutableDictionary dictionaryWithCapacity:types.count];
    for (int i = 0; i < types.count; i++){
        NSString* type = [types[i] lowercaseString];
        if ([type characterAtIndex:0] != '\'' && ![capabilities valueForKey:type]){
            NSString* tmpFileName = [NSString stringWithFormat:@"/tmp/DigViewerTmp.%@", type];
            NSFileManager* manager = [NSFileManager defaultManager];
            [manager createFileAtPath:tmpFileName contents:nil attributes:nil];
            NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
            NSError* error;
            NSString* remarks = [workspace localizedDescriptionForType:[workspace typeOfFile:tmpFileName error:&error]];
            [capabilities setValue:remarks forKey:type];
            [manager removeItemAtPath:tmpFileName error:&error];
        }
    }
}

+ (NSDictionary *)supportedSuffixes
{
    if (!capabilities){
        [NSImage buildCapabilityList];
    }
    return capabilities;
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

+ (NSDictionary*)rasterImageSuffixes
{
    static NSMutableDictionary* _rasterImageSuffixes;
    if (!_rasterImageSuffixes){
        _rasterImageSuffixes = [NSMutableDictionary dictionaryWithDictionary:[NSImage rawSuffixes]];
        [_rasterImageSuffixes addEntriesFromDictionary:@{
                                                         @"jpg":@"jpeg",
                                                         @"jpeg":@"jpeg"
                                                         }];
    }
    return _rasterImageSuffixes;
}

+ (BOOL) isRawFileAtPath:(NSString*)path
{
    return [[NSImage rawSuffixes] valueForKey:[[path pathExtension] lowercaseString]] != nil;
}

+ (BOOL)isRasterImageAtPath:(NSString *)path
{
    return [[NSImage rasterImageSuffixes] valueForKey:[[path pathExtension] lowercaseString]] != nil;
}

@end
