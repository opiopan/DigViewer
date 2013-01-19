//
//  ThumbnailViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ThumbnailViewController.h"
#import "MainViewController.h"
#import "Document.h"
#import "PathNode.h"

@implementation ThumbnailViewController

@synthesize zoomRethio;
@synthesize thumbnailView;

const static double defaultZoomRatio = 100;

- (id)init
{
    self = [super initWithNibName:@"ThumbnailView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    [self performSelector:@selector(onDefaultSize:) withObject:self afterDelay:0.0f];
}

- (void)updateRepresentationObject
{
    [thumbnailView scrollIndexToVisible:[[thumbnailView selectionIndexes] firstIndex]];
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index
{
    [self performSelector:@selector(moveToSelectedNode) withObject:nil afterDelay:0.0f];
}

- (void) moveToSelectedNode
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

- (void)setZoomRethio:(double)value
{
    zoomRethio = value;
    NSSize size = {zoomRethio, zoomRethio};
    thumbnailView.cellSize = size;
}

- (double)zoomRethio
{
    return zoomRethio;
}

- (IBAction)onDefaultSize:(id)sender {
    self.zoomRethio = defaultZoomRatio;
}

- (IBAction)onUpFolder:(id)sender {
    ObjectControllers* controllers = self.representedObject;
    PathNode* selected = controllers.imageArrayController.selectedObjects[0];
    PathNode* current = selected.parent;
    PathNode* up = current.parent;
    if (up){
        NSUInteger index = current.indexInParent;
        [controllers.imageTreeController setSelectionIndexPath:up.indexPath];
        [controllers.imageArrayController setSelectionIndex:index];
    }
}
@end
