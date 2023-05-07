//
//  BasicBackgroundView.m
//  DigViewer
//
//  Created by opiopan on 2013/02/03.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "BasicBackgroundView.h"

@implementation BasicBackgroundView

-(void)drawRect:(NSRect)dirtyRect
{
    NSRect rect=[self bounds];
    //CGFloat brightness = 0.85;
    //[[NSColor colorWithCalibratedRed:brightness green:brightness blue:brightness alpha:1.0] set];
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:rect];
}

@end
