//
//  PortableSystemImages.m
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/12.
//  Copyright © 2023 opiopan. All rights reserved.
//

#import "PortableSystemImages.h"

static NSDictionary* fallback;

@implementation PortableSystemImages
+ (NSImage*)portableImageWithName:(NSString*)name
{
    if (!fallback){
        fallback = @{
            @"photo": NSImageNameQuickLookTemplate,
            @"rectangle.rightthird.inset.filled": NSImageNameRevealFreestandingTemplate,
            @"rectangle.leftthird.inset.filled": NSImageNamePathTemplate,
        };
    }
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:name accessibilityDescription:nil];
    } else {
        return [NSImage imageNamed:fallback[name]];
    }

}

+ (NSImage*)iconView
{
    return [[self class] portableImageWithName:@"photo"];
}

+ (NSImage*)iconLeftPane
{
    return [[self class] portableImageWithName:@"rectangle.leftthird.inset.filled"];
}

+ (NSImage*)iconRightPane
{
    return [[self class] portableImageWithName:@"rectangle.rightthird.inset.filled"];
}
@end
