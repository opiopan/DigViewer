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
    __weak Document* _document;
    __weak ThumbnailCache* _thumnailCache;
    BOOL _isRescheduling;
}

@synthesize zoomRethio;
@synthesize thumbnailView;
@synthesize imageArrayController;

- (id)init
{
    self = [super initWithNibName:@"ThumbnailView" bundle:nil];
    _isRescheduling = NO;
    return self;
}

- (void)awakeFromNib
{
    [self performSelector:@selector(onDefaultSize:) withObject:self afterDelay:0.0f];
    [imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:nil];
    [imageArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    thumbnailView.menu = controller.contextMenu;
    _document = [self.representedObject valueForKey:@"document"];
    _thumnailCache = _document.thumnailCache;
    [controller addObserver:self forKeyPath:@"presentationViewType" options:0 context:nil];
    [controller addObserver:self forKeyPath:@"isCollapsedInspectorView" options:0 context:nil];
    [controller addObserver:self forKeyPath:@"isCollapsedOutlineView" options:0 context:nil];
    [_document addObserver:self forKeyPath:@"thumbnailCacheCounter" options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndEnable"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.dndMultiple"
                                                                 options:0 context:nil];
    [[ThumbnailConfigController sharedController] addObserver:self forKeyPath:@"updateCount" options:0 context:nil];
    [_scrollView.contentView setPostsBoundsChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentViewBoundsChange)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:nil];

    [self reflectDnDSettings];
}

- (void)prepareForClose
{
    [imageArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
    [imageArrayController removeObserver:self forKeyPath:@"arrangedObjects"];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    [controller removeObserver:self forKeyPath:@"presentationViewType"];
    [controller removeObserver:self forKeyPath:@"isCollapsedInspectorView"];
    [controller removeObserver:self forKeyPath:@"isCollapsedOutlineView"];
    [_document removeObserver:self forKeyPath:@"thumbnailCacheCounter"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.dndEnable"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.dndMultiple"];
    [[ThumbnailConfigController sharedController] removeObserver:self forKeyPath:@"updateCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:nil];
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
    }else if ([keyPath isEqualToString:@"arrangedObjects"]){
        [_document.thumnailCache clearWaitingQueue];
    }else{
        [thumbnailView scrollIndexToVisible:[[thumbnailView selectionIndexes] firstIndex]];
    }
}

- (void)contentViewBoundsChange
{
    if (!_isRescheduling){
        _isRescheduling = YES;
        [self performSelector:@selector(rescheduleThumbnailRendering) withObject:nil afterDelay:0.5];
    }
}

- (void)rescheduleThumbnailRendering
{
    NSIndexSet* indexSet = self.thumbnailView.visibleItemIndexes;
    if (indexSet.count > 0){
        [_document.thumnailCache rescheduleWaitingQueueWithArrayController:self.imageArrayController indexes:indexSet];
    }
    _isRescheduling = NO;
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
