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

- (NSView*)representationView;
{
    return thumbnailView;
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
    Document* document = self.representedObject;
    PathNode* current = document.imageArrayController.selectedObjects[0];
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

- (IBAction)onDefaultSize:(id)sender
{
    self.zoomRethio = defaultZoomRatio;
}

- (IBAction)onUpFolder:(id)sender
{
    Document* document = self.representedObject;
    [document moveUpFolder:sender];
}

- (IBAction)onDownFolder:(id)sender {
    Document* document = self.representedObject;
    [document moveDownFolder:sender];
}

@end
