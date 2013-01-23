//
//  BaseViewController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BaseViewController : NSViewController

- (NSView*) representationView;
- (void) updateRepresentationObject;

@end
