//
//  ClickableImageView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ClickableImageView.h"

@implementation ClickableImageView{
    NSColor* _backgroundColor;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (void)mouseUp:(NSEvent*)event
{
    if([event clickCount] == 2) {
        [self.delegate performSelector:@selector(onDoubleClickableImageView:) withObject:self afterDelay:0.0f];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
	[super drawRect:dirtyRect];
}

- (NSColor*)backgroundColor
{
    return _backgroundColor;
}

- (void)setBackgroundColor:(NSColor *)value
{
    _backgroundColor = value;
    [self display];
}

@end
