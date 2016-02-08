//
//  NSImage+CapabilityDetermining.h
//  DigViewer
//
//  Created by opiopan on 2013/01/06.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (CapabilityDetermining)

+ (BOOL) isSupportedFileAtPath:(NSString*)path;
+ (NSDictionary *)supportedSuffixes;
+ (NSDictionary *)rawSuffixes;
+ (BOOL) isRawFileAtPath:(NSString*)path;
+ (BOOL) isRasterImageAtPath:(NSString*)path;

@end
