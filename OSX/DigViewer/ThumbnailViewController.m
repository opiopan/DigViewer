//
//  ThumbnailViewController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ThumbnailViewController.h"
#import "NSViewController+Nested.h"
#import "MainViewController.h"
#import "DocumentWindowController.h"
#import "PathNode.h"
#import "DraggingSourceTreeController.h"
#import "DraggingSourceArrayController.h"
#import "ThumbnailConfigController.h"
#import "ThumbnailCache.h"

@implementation ThumbnailViewController{
    __weak ThumbnailCache* _thumnailCache;
}

@synthesize zoomRethio;
@synthesize thumbnailView;
@synthesize imageArrayController;

- (id)init
{
    self = [super initWithNibName:@"ThumbnailView" bundle:nil];
    return self;
}

- (void)awakeFromNib
{
    [self performSelector:@selector(onDefaultSize:) withObject:self afterDelay:0.0f];
    [imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:nil];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    thumbnailView.menu = controller.contextMenu;
    Document* document = [self.representedObject valueForKey:@"document"];
    _thumnailCache = document.thumnailCache;
    [controller addObserver:self forKeyPath:@"presentationViewType" options:0 context:nil];
    [controller addObserver:self forKeyPath:@"isCollapsedInspectorView" options:0 context:nil];
    [controller addObserver:self forKeyPath:@"isCollapsedOutlineView" options:0 context:nil];
    [document addObserver:self forKeyPath:@"thumbnailCacheCounter" options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndEnable"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndMultiple"
                                                                 options:0 context:nil];
    [[ThumbnailConfigController sharedController] addObserver:self forKeyPath:@"updateCount" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollViewDidScroll)
                                                 name:NSScrollViewDidEndLiveScrollNotification
                                               object:nil];
    
    [self reflectDnDSettings];
}

- (void)prepareForClose
{
    [imageArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    Document* document = [self.representedObject valueForKey:@"document"];
    [controller removeObserver:self forKeyPath:@"presentationViewType"];
    [controller removeObserver:self forKeyPath:@"isCollapsedInspectorView"];
    [controller removeObserver:self forKeyPath:@"isCollapsedOutlineView"];
    [document removeObserver:self forKeyPath:@"thumbnailCacheCounter"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.dndEnable"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.dndMultiple"];
    [[ThumbnailConfigController sharedController] removeObserver:self forKeyPath:@"updateCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSScrollViewDidEndLiveScrollNotification object:nil];
}

- (NSView*)representationView;
{
    return thumbnailView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"values.dndMultiple"] || [keyPath isEqualToString:@"values.dndEnable"]){
        [self reflectDnDSettings];
    }else if (object == [self.representedObject valueForKey:@"document"]){
        [thumbnailView reloadData];
    }else if (object == [ThumbnailConfigController sharedController]){
        [thumbnailView reloadData];
    }else{
        [thumbnailView scrollIndexToVisible:[[thumbnailView selectionIndexes] firstIndex]];
    }
}

- (void)scrollViewDidScroll
{
    NSIndexSet* indexSet = self.thumbnailView.visibleItemIndexes;
    if (indexSet.count > 0){
        Document* document = [self.representedObject valueForKey:@"document"];
        [document.thumnailCache rescheduleWaitingQueueWithArrayController:self.imageArrayController indexes:indexSet];
    }
}

- (void)reflectDnDSettings
{
    NSNumber* enable = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"dndEnable"];
    NSNumber* multiple = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"dndMultiple"];
    thumbnailView.allowsMultipleSelection = enable.boolValue && multiple.boolValue;
    [DraggingSourceArrayController setEnableDragging:enable.boolValue];
    [DraggingSourceTreeController setEnableDragging:enable.boolValue];
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index
{
    [self performSelector:@selector(moveToSelectedNode) withObject:nil afterDelay:0.0f];
}

- (void) moveToSelectedNode
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    PathNode* current = controller.imageArrayController.selectedObjects[0];
    if (current.isImage){
        controller.presentationViewType = typeImageView;
    }else{
        [controller moveToFolderNode:current];
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
    self.zoomRethio = [[[ThumbnailConfigController sharedController] defaultSize] doubleValue];
}

- (IBAction)onUpFolder:(id)sender
{
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller moveUpFolder:sender];
}

- (IBAction)onDownFolder:(id)sender {
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller moveDownFolder:sender];
}

//-----------------------------------------------------------------------------------------
// View状態属性の実装
//-----------------------------------------------------------------------------------------
static NSString* kZoomRatio = @"zoomRatio";

- (NSDictionary *)preferences
{
    NSDictionary* rc = @{kZoomRatio: @(zoomRethio)};
    return rc;
}

- (void)setPreferences:(NSDictionary *)preferences
{
    [self performSelector:@selector(reflectPreferences:) withObject:preferences afterDelay:0];
}

- (void)reflectPreferences:(NSDictionary *)preferences
{
    self.zoomRethio = [[preferences valueForKey:kZoomRatio] doubleValue];

}

@end
