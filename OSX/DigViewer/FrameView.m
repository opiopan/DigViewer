//
//  FrameView.m
//  DigViewer
//
//  Created by opiopan on 2013/02/03.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "FrameView.h"

@implementation FrameView

-(void)drawRect:(NSRect)dirtyRect
{
    CGFloat headerHeight = 34.5;
    [NSBezierPath setDefaultLineWidth:1];
    
    NSRect rect=[self bounds];

    [[NSColor whiteColor] set];
    NSRect clientRect = rect;
    clientRect.size.height -= headerHeight;
    [NSBezierPath fillRect:clientRect];

    
    [[NSColor darkGrayColor] set];
    CGFloat pos = rect.origin.y + rect.size.height - headerHeight;
    [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, pos)
                              toPoint:NSMakePoint(rect.origin.x + rect.size.width, pos)];
}

@end
