//
//  NSView+ViewControllerAssociation_.h
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (ViewControllerAssociation)

- (void) associateSubViewWithController:(NSViewController*)controller;

@end
