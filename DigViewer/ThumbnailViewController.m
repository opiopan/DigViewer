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
@synthesize imageArrayController;

const static double defaultZoomRatio = 100;

- (id)init
{
    self = [super initWithNibName:@"ThumbnailView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    [self performSelector:@selector(onDefaultSize:) withObject:self afterDelay:0.0f];
    [imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:nil context:nil];
}

- (NSView*)representationView;
{
    return thumbnailView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == imageArrayController && [keyPath isEqualToString:@"selectionIndexes"]){
        [thumbnailView scrollIndexToVisible:[[thumbnailView selectionIndexes] firstIndex]];
    }
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index
{
    [self performSelector:@selector(moveToSelectedNode) withObject:nil afterDelay:0.0f];
}

- (void) moveToSelectedNode
{
    Document* document = [self.representedObject valueForKey:@"document"];
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
    Document* document = [self.representedObject valueForKey:@"document"];
    [document moveUpFolder:sender];
}

- (IBAction)onDownFolder:(id)sender {
    Document* document = [self.representedObject valueForKey:@"document"];
    [document moveDownFolder:sender];
}

@end
