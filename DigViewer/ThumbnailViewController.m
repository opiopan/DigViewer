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

const static double defaultZoomRatio = 0.4f;

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

- (IBAction)onDefaultSize:(id)sender {
    self.zoomRethio = defaultZoomRatio;
}
@end
