//
//  NSWindow+TracingResponderChain.m
//  DigViewer
//
//  Created by opiopan on 2014/02/15.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "NSWindow+TracingResponderChain.h"

@implementation NSWindow (TracingResponderChain)

- (BOOL) isBelongToResponderChain:(NSResponder *)responder
{
    for (NSResponder* current = self.firstResponder; current; current = current.nextResponder){
        if (current == responder){
            return YES;
        }
    }
    return NO;
}

@end
