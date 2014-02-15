//
//  DocumentWindowController.h
//  DigViewer
//
//  Created by opiopan on 2014/02/08.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

@interface DocumentWindowController : NSWindowController

@property (strong) NSArray* selectionIndexPathsForTree;
@property (strong) NSIndexSet* selectionIndexesForImages;
@property (weak) IBOutlet NSView *placeHolder;
@property (strong) IBOutlet NSTreeController *imageTreeController;
@property (strong) IBOutlet NSArrayController *imageArrayController;

@property (assign) int presentationViewType;
@property (assign) BOOL isFitWindow;
@property (assign) BOOL isCollapsedOutlineView;

- (void)moveToNextImage:(id)sender;
- (void)moveToPreviousImage:(id)sender;
- (void)moveToFolderNode:(PathNode*)next;
- (void)moveUpFolder:(id)sender;
- (void)moveDownFolder:(id)sender;

@end

