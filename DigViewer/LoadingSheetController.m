//
//  LoadingSheetController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/09.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "LoadingSheetController.h"
#import "PathNode.h"

@implementation LoadingSheetController{
    NSString*         path;
    PathNode*         root;
    PathNodeProgress* pathNodeProgress;
    NSWindow*         modalWindow;
    id                modalDelegate;
    SEL               didEndSelector;
}

@synthesize name;
@synthesize progress;
@synthesize panel;

- (id)init
{
    self = [super init];
    if (self) {
        pathNodeProgress = [[PathNodeProgress alloc] init];
        progress = [NSNumber numberWithDouble:0.0];
        [NSBundle loadNibNamed:@"LoadingSheet" owner:self];
    }
    
    return self;
}

- (void) loadPath:(NSString*)p forWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)selector
{
    [self willChangeValueForKey:@"name"];
    name = [p lastPathComponent];
    [self didChangeValueForKey:@"name"];
    path = p;
    modalWindow = window;
    modalDelegate = delegate;
    didEndSelector = selector;
    
    [self performSelectorInBackground:@selector(loadPinnedFileInBackground) withObject:nil];
    [self performSelector:@selector(showPanel) withObject:nil afterDelay:0.5f];
}

- (void) loadPinnedFileInBackground
{
    @autoreleasepool {
        PathfinderPinnedFile* pinnedFile = [PathfinderPinnedFile pinnedFileWithPath:path];
        root = [PathNode pathNodeWithPinnedFile:pinnedFile progress:pathNodeProgress];
        [self performSelectorOnMainThread:@selector(didEndLoading) withObject:nil waitUntilDone:NO];
    }
}

- (void) didEndLoading{
    [panel close];
    [modalDelegate performSelector:didEndSelector withObject:root afterDelay:0.0f];
    panel = nil;
}

- (void) showPanel
{
    if (panel && pathNodeProgress.progress < 0.5){
        [[NSApplication sharedApplication] beginSheet:panel
                                       modalForWindow:modalWindow
                                        modalDelegate:nil
                                       didEndSelector:nil
                                          contextInfo:nil];
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1f];
    }
}

- (void) updateProgress{
    [self willChangeValueForKey:@"progress"];
    progress = [NSNumber numberWithDouble:pathNodeProgress.progress];
    [self didChangeValueForKey:@"progress"];
    if (panel){
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1f];
    }
}

- (NSNumber*) progress
{
    return progress;
}

@end
