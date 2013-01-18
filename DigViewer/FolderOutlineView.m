//
//  FolderOutlineView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "FolderOutlineView.h"
#import "MainViewController.h"
#import "Document.h"
#import "PathNode.h"

@implementation FolderOutlineView

@synthesize imageTableView;

- (id)init
{
    self = [super initWithNibName:@"FolderOutlineView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    [imageTableView setTarget:self];
    [imageTableView setDoubleAction:@selector(onDoubleClickImageTableView:)];
}

- (void)onDoubleClickImageTableView:(id)sender
{
    ObjectControllers* controllers = self.representedObject;
    PathNode* current = controllers.imageArrayController.selectedObjects[0];
    Document* document = controllers.documentController;
    if (current.isImage){
        document.presentationViewType = typeImageView;
    }else{
        [document moveToFolderNode:current];
    }    
}

- (void)updateRepresentationObject
{
    [imageTableView scrollRowToVisible:[imageTableView selectedRow]];
}

@end
