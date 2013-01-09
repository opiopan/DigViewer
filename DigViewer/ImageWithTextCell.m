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
    NSImage* image = [node valueForKey:@"image"];
    NSString* name = [node valueForKey:@"name"];
    
	[controlView lockFocus];
    NSRect target = cellFrame;
	target.size.width = target.size.height;
    //[icon setFlipped:YES];
	[image drawInRect:target fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
	
	NSPoint p2 = cellFrame.origin;
	p2.x += cellFrame.size.height + 4.0;
	p2.y += 0.0;
	NSDictionary* attrs = [self.attributedStringValue attributesAtIndex:0 effectiveRange:nil];
	[name drawAtPoint:p2 withAttributes:attrs];
	[controlView unlockFocus];
}

@end
