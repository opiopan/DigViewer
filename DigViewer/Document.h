//
//  Document.h
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PathNode.h"
#import "ObjectControllers.h"

@interface Document : NSDocument

@property (strong) PathNode* root;
@property (strong) NSArray* selectionIndexePathForTree;
@property (strong) NSIndexSet* selectionIndexesForImages;
@property (assign) int presentationViewType;
@property (strong) IBOutlet ObjectControllers* objectControllers;
@property (weak) IBOutlet NSView *placeHolder;

- (void)moveToNextImage:(id)sender;
- (void)moveToPreviousImage:(id)sender;

@end
