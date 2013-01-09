//
//  Document.h
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PathNode.h"

@interface Document : NSDocument

@property (readonly) PathNode* root;
@property (strong) IBOutlet NSTreeController *imageTreeController;
@property (strong) IBOutlet NSArrayController *imageArrayController;

- (void)moveToNextImage:(id)sender;
- (void)moveToPreviousImage:(id)sender;

@end
