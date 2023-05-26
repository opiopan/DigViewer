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
    NSString*                  path;
    PathNode*                  root;
    PathNodeProgress*          pathNodeProgress;
    NSWindow*                  modalWindow;
    id                         modalDelegate;
    SEL                        didEndSelector;
    PathNodeOmmitingCondition* condition;
    NSArray*                   topLevelObjects;
    BOOL                       isLoading;
    BOOL                       isShowing;
}

@synthesize phase;
@synthesize targetFolder;
@synthesize isIndeterminate;
@synthesize progress;
@synthesize panel;
@synthesize progressIndicator;

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        pathNodeProgress = [[PathNodeProgress alloc] init];
        isIndeterminate = YES;
        progress = [NSNumber numberWithDouble:0.0];
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"LoadingSheet" owner:self topLevelObjects:&objects];
        topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [progressIndicator startAnimation:self];
}

//-----------------------------------------------------------------------------------------
// ドキュメントロード
//-----------------------------------------------------------------------------------------
- (void) loadPath:(NSString*)p forWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)selector
        condition:(PathNodeOmmitingCondition*)cond;
{
    path = p;
    modalWindow = window;
    modalDelegate = delegate;
    didEndSelector = selector;
    condition = cond;
    isLoading = YES;
    isShowing = NO;
    
    [self performSelectorInBackground:@selector(loadPinnedFileInBackground) withObject:nil];
    [self performSelector:@selector(showPanel) withObject:nil afterDelay:0.5f];
}

- (void) loadPinnedFileInBackground
{
    @autoreleasepool {
        self.phase = NSLocalizedString(@"Now loading a pinned file in the folder:", nil);
        self.targetFolder = path;
        PathfinderPinnedFile* pinnedFile = [PathfinderPinnedFile pinnedFileWithPath:path];
        NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
        PathNodeCreateOption option;
        option.isSortByCaseInsensitive = [[controller.values valueForKey:@"pathNodeSortCaseInsensitive"] boolValue];
        option.isSortAsNumeric = [[controller.values valueForKey:@"pathNodeSortAsNumeric"] boolValue];
        if (pinnedFile){
            self.phase = NSLocalizedString(@"Now recognizing a pinned file in the folder:", nil);
            self.isIndeterminate = NO;
            root = [PathNode pathNodeWithPinnedFile:pinnedFile ommitingCondition:condition
                                             option:&option progress:pathNodeProgress];
        }else{
            self.phase = NSLocalizedString(@"Now searching image files in the folder:", nil);
            root = [PathNode pathNodeWithPath:path  ommitingCondition:condition option:&option progress:pathNodeProgress];
        }
        [self performSelectorOnMainThread:@selector(didEndLoading) withObject:nil waitUntilDone:NO];
    }
}

- (void) didEndLoading{
    isLoading = NO;
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    root.sortType = ((NSNumber*)[[controller values] valueForKey:@"pathNodeSortType"]).intValue;
    if (didEndSelector){
        progress = [NSNumber numberWithDouble:pathNodeProgress.progress];
        progressIndicator.doubleValue = progress.doubleValue;
        [modalDelegate performSelector:didEndSelector withObject:root afterDelay: root && !isIndeterminate && isShowing ? 0.4f : 0.0f];
    }else{
        [self cleanupSheet];
    }
}

- (void) cleanupSheet
{
    if (isShowing){
        [panel close];
        [[NSApplication sharedApplication] endSheet:panel returnCode:NSModalResponseOK];
        isShowing =NO;
    }
    panel = nil;
    topLevelObjects = nil;
    root = nil;
}

- (void) showPanel
{
    if (isLoading && pathNodeProgress.progress < 50){
        isShowing = YES;
        [modalWindow beginSheet:panel completionHandler:nil];
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1f];
    }
}

- (void) updateProgress{
    self.progress = [NSNumber numberWithDouble:pathNodeProgress.progress];
    NSString* newTarget = pathNodeProgress.target;
    if (newTarget && ![newTarget isEqual:self.targetFolder]){
        self.targetFolder = newTarget;
    }
    if (panel){
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1f];
    }
}

- (IBAction)onCancel:(id)sender {
    pathNodeProgress.isCanceled = YES;
    self.isCanceled = YES;
}

//-----------------------------------------------------------------------------------------
// 撮影日時ロード
//-----------------------------------------------------------------------------------------
- (void)loadImageDateTimeForPathNode:(PathNode *)pathNode forWindow:(NSWindow *)window
                       modalDelegate:(id)delegate didEndSelector:(SEL)selector
{
    root = pathNode;
    modalWindow = window;
    modalDelegate = delegate;
    didEndSelector = selector;
    isLoading = YES;
    isShowing = NO;
    
    [self performSelectorInBackground:@selector(loadImageDateTimeInBackground) withObject:nil];
    [self performSelector:@selector(showPanel) withObject:nil afterDelay:0.5f];
}

- (void)loadImageDateTimeInBackground
{
    @autoreleasepool {
        self.phase = NSLocalizedString(@"Now extracting image date time in a folder:", nil);
        self.isIndeterminate = NO;
        self.targetFolder = root.originalPath;
        NSArray* children = root.images;
        double total = children.count - root.children.count;
        double current = 0;
        for (PathNode* child in children){
            if (self.isCanceled){
                break;
            }
            if (child.isImage){
                [child imageDateTime];
                current += 100.0;
                pathNodeProgress.progress = current / total;
            }
        }
        [self performSelectorOnMainThread:@selector(didEndLoadingImageDateTime) withObject:nil waitUntilDone:NO];
    }
}

- (void) didEndLoadingImageDateTime
{
    isLoading = NO;
    if (didEndSelector){
        [modalDelegate performSelector:didEndSelector withObject:root afterDelay:0.0f];
    }else{
        [self cleanupSheet];
    }
}

@end
