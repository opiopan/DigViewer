//
//  NSViewController+Nested.h
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSViewController (Nested)

- (NSView*) representationView;
- (void) updateRepresentationObject;

@end
