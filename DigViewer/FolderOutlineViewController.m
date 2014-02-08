//
//  FolderOutlineView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "FolderOutlineViewController.h"
#import "MainViewController.h"
#import "Document.h"
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
}

- (void)onDoubleClickImageTableView:(id)sender
{
    Document* document = [self.representedObject valueForKey:@"document"];
    PathNode* current = document.imageArrayController.selectedObjects[0];
    if (current.isImage){
        document.presentationViewType = typeImageView;
    }else{
        [document moveToFolderNode:current];
    }    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == imageArrayController && [keyPath isEqualToString:@"selectionIndexes"]){
        [imageTableView scrollRowToVisible:[imageTableView selectedRow]];
    }
}

@end
