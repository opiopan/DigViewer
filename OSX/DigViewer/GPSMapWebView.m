//
//  GPSMapWebView.m
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/04/23.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import "GPSMapWebView.h"

@implementation GPSMapWebView

- (void)rightMouseDown:(NSEvent *)theEvent {
    NSView *parentView = self.superview;
    NSMenu *parentMenu = [parentView menuForEvent:theEvent];
    [NSMenu popUpContextMenu:parentMenu withEvent:theEvent forView:parentView];
}

@end
