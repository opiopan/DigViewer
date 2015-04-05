//
//  NSString+escaping.m
//  DigViewer
//
//  Created by Hiroshi Murayama on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "NSString+escaping.h"

@implementation NSString (escaping)

+ (NSString*) escapedStringForJavascript:(NSString*)string
{
    string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    string = [string stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    string = [string stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    
    return string;
}

@end
