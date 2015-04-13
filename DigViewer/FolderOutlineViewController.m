//
//  FolderOutlineView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "FolderOutlineViewController.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "Document.h"
#import "DocumentWindowController.h"
#import "PathNode.h"

@implementation FolderOutlineViewController

@synthesize imageTableView;
@synthesize imageArrayController;

- (id)init
{
    self = [super initWithNibName:@"FolderOutlineView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    [imageTableView setTarget:self];
    [imageTableView setDoubleAction:@selector(onDoubleClickImageTableView:)];
    [imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:nil context:nil];
    
    // Dragging sourceの登録
    [imageTableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
}

- (void)prepareForClose
{
    [imageArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
}

- (void)onDoubleClickImageTableView:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    PathNode* current = controller.imageArrayController.selectedObjects[0];
    if (current.isImage){
        controller.presentationViewType = typeImageView;
    }else{
        [controller moveToFolderNode:current];
    }    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == imageArrayController && [keyPath isEqualToString:@"selectionIndexes"]){
        [imageTableView scrollRowToVisible:[imageTableView selectedRow]];
    }
}

@end
