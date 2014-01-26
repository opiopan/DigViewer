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

@property (strong) PathNode* root;
@property (strong) NSArray* selectionIndexPathsForTree;
@property (strong) NSIndexSet* selectionIndexesForImages;
@property (assign) int presentationViewType;
@property (assign) BOOL isFitWindow;
@property (assign) int viewableImageSet;
@property (weak) IBOutlet NSView *placeHolder;
@property (strong) IBOutlet NSTreeController *imageTreeController;
@property (strong) IBOutlet NSArrayController *imageArrayController;

- (void)moveToNextImage:(id)sender;
- (void)moveToPreviousImage:(id)sender;
- (void)moveToFolderNode:(PathNode*)next;
- (void)moveUpFolder:(id)sender;
- (void)moveDownFolder:(id)sender;


@end
