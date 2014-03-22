//
//  KeyUncapturedTabView.m
//  DigViewer
//
//  Created by opiopan on 2014/03/23.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "KeyUncapturedTabView.h"

@implementation KeyUncapturedTabView

- (void)moveRight:(id)sender
{
    [self.window.windowController moveRight:sender];
}

- (void)moveLeft:(id)sender
{
    [self.window.windowController moveLeft:sender];
}

@end
