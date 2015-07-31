//
//  ImageWithTextCell.m
//  DigViewer
//
//  Created by opiopan on 2013/01/08.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ImageWithTextCell.h"

@implementation ImageWithTextCell

- (NSImage*)iconValue
{
    id node = [self objectValue];
    NSImage* image = nil;
    if ([[node class] isSubclassOfClass:[NSString class]]){
    }else if ([[node class] isSubclassOfClass:[NSImage class]]){
        image = node;
    }else{
        NSString* keyForIcon = _keyForIcon ? _keyForIcon : @"icon";
        image = [node valueForKey:keyForIcon];
    }
    return image;
}

- (NSString*)nameValue
{
    id node = [self objectValue];
    NSString* name = nil;
    if ([[node class] isSubclassOfClass:[NSString class]]){
        name = node;
    }else if ([[node class] isSubclassOfClass:[NSImage class]]){
    }else{
        NSString* keyForName = _keyForName ? _keyForName : @"name";
        name = [node valueForKey:keyForName];
    }
    return name;
}

- (NSPoint) namePositionWithIcon:(NSImage*)icon cellFrame:(NSRect)cellFrame
                            name:(NSString*)name attributes:(NSDictionary*)attributes
{
    NSPoint position = cellFrame.origin;
    if (icon){
        position.x += cellFrame.size.height + 4.0;
    }
    NSFont* font = [attributes valueForKey:NSFontAttributeName];
    if (!font){
        font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    }
    position.y += ((cellFrame.size.height - font.pointSize) / 2.0 + font.descender);
    return position;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSImage* image = [self iconValue];
    NSString* name = [self nameValue];
    
    NSRect target = cellFrame;
    target.size.width = target.size.height;
    [image drawInRect:target fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
    NSDictionary* attrs = [self.attributedStringValue attributesAtIndex:0 effectiveRange:nil];
    NSPoint p2 = [self namePositionWithIcon:image cellFrame:cellFrame name:name attributes:attrs];
    
    [name drawAtPoint:p2 withAttributes:attrs];
}

- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
    NSImage* image = [self iconValue];
    NSString* name = [self nameValue];
    NSDictionary* attrs = [self.attributedStringValue attributesAtIndex:0 effectiveRange:nil];
    NSPoint p2 = [self namePositionWithIcon:image cellFrame:cellFrame name:name attributes:attrs];
    cellFrame.size.width = p2.x - cellFrame.origin.x;
    cellFrame.size.width += [name sizeWithAttributes:attrs].width;
    if (image){
        cellFrame.size.width += 4.0;
    }
    if(view.frame.size.width < cellFrame.origin.x + cellFrame.size.width){
        return cellFrame;
    }else{
        return NSZeroRect;
    }
}

@end
