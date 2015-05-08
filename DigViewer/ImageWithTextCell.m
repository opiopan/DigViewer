//
//  ImageWithTextCell.m
//  DigViewer
//
//  Created by opiopan on 2013/01/08.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ImageWithTextCell.h"

@implementation ImageWithTextCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    id node = [self objectValue];
    NSImage* image = nil;
    NSString* name = nil;
    if ([[node class] isSubclassOfClass:[NSString class]]){
        name = node;
    }else if ([[node class] isSubclassOfClass:[NSImage class]]){
        image = node;
    }else{
        image = [node valueForKey:@"icon"];
        name = [node valueForKey:@"name"];
    }
    
    NSRect target = cellFrame;
    target.size.width = target.size.height;
    [image drawInRect:target fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
    NSPoint p2 = cellFrame.origin;
    if (image){
        p2.x += cellFrame.size.height + 4.0;
    }
    NSDictionary* attrs = [self.attributedStringValue attributesAtIndex:0 effectiveRange:nil];
    NSFont* font = [attrs valueForKey:NSFontAttributeName];
    if (!font){
        font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    }
    p2.y += ((cellFrame.size.height - font.pointSize) / 2.0 + font.descender);
    
    [name drawAtPoint:p2 withAttributes:attrs];
}

@end
