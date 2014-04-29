//
//  NSColor+JavascriptColorSpace.m
//  DigViewer
//
//  Created by 荒滝新菜 on 2014/04/29.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "NSColor+JavascriptColorSpace.h"

@implementation NSColor (JavascriptColorSpace)
- (NSString*) javascriptColor
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"\"#%.2X%.2X%.2X\"", (int)(red * 255), (int)(green * 255), (int)(blue * 255)];
}

@end
