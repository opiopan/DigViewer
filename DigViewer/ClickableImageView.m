//
//  ClickableImageView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ClickableImageView.h"

@implementation ClickableImageView

@synthesize delegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (void)mouseUp:(NSEvent*)event
{
    if([event clickCount] == 2) {
        [delegate performSelector:@selector(onDoubleClickableImageView:) withObject:self afterDelay:0.0f];
    }
}

@end
