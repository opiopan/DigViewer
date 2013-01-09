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

@end
