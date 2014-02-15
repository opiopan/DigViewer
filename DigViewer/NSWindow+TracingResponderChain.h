//
//  NSWindow+TracingResponderChain.h
//  DigViewer
//
//  Created by opiopan on 2014/02/15.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (TracingResponderChain)

- (BOOL)isBelongToResponderChain:(NSResponder*)responder;

@end
