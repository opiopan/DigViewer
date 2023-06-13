//
//  ManageBrowsingContextConroller.m
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/06.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import "ManageBrowsingContextConroller.h"
#import "DocumentWindowController.h"
#import "NewBrowsingContextController.h"

@interface ManageBrowsingContextConroller()
@property (nonatomic) IBOutlet NSPanel* panel;
@property (nonatomic) IBOutlet NSArrayController* arrayController;
@property (nonatomic) IBOutlet NSTableView* tableView;
@property (nonatomic) NSMutableArray* array;
@end

@implementation ManageBrowsingContextConroller{
    NSWindow* _window;
    DocumentWindowController* _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;
    NewBrowsingContextController* _newBrowsingContextController;
}

//-----------------------------------------------------------------------------------------
// Initialize
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"ManageBrowsingContextSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [_arrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:nil];
}

- (void)prepareForClose
{
    [_arrayController removeObserver:self forKeyPath:@"selectionIndexes"];
}

//-----------------------------------------------------------------------------------------
// Observing other objects
//-----------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == _arrayController){
        [_tableView scrollRowToVisible:_tableView.selectedRowIndexes.firstIndex];
    }
}

//-----------------------------------------------------------------------------------------
// Generate sheet
//-----------------------------------------------------------------------------------------
- (void) manageContexsforWindow:(NSWindow*)window array:(NSMutableArray*)array  modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    self.array = array;
    _delegate = delegate;
    _didEndSelector = didEndSelector;

    id current = _delegate.browseContexts.currentContext;
    for (int i = 0; i < _array.count; i++){
        id context = _arrayController.arrangedObjects[i];
        if (context == current){
            _arrayController.selectionIndex = i;
            break;
        }
    }
    
    [_window beginSheet:self.panel completionHandler:^(NSModalResponse returnCode){
        [self didEndSheet:self.panel returnCode:returnCode contextInfo:nil];
    }];
}

//-----------------------------------------------------------------------------------------
// Handler of closing sheet
//-----------------------------------------------------------------------------------------
- (void) didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == NSModalResponseOK){
        [_delegate performSelector:_didEndSelector withObject:self afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// Response handlers for OK button and Cancel button
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender
{
    [self.panel close];
    [self onDoubleClick:self];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseOK];
}

- (IBAction)onCancel:(id)sender
{
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseCancel];
}

//-----------------------------------------------------------------------------------------
// Context switching
//-----------------------------------------------------------------------------------------
- (IBAction)onDoubleClick:(id)sender
{
    id<BrowseContext> context = _arrayController.selectedObjects[0];
    [_delegate changeBrowsingContextWithName:context.name];
}

//-----------------------------------------------------------------------------------------
// Add / Remove context
//-----------------------------------------------------------------------------------------
- (IBAction)onAddOrRemoveContext:(NSSegmentedControl*)sender
{
    if (sender.selectedSegment == 0){
        _newBrowsingContextController = [NewBrowsingContextController new];
        [_newBrowsingContextController inputContextNameforWindow:self.panel modalDelegate:self didEndSelector:@selector(didEndInputContextName:)];
    }else if (sender.selectedSegment == 1){
        id<BrowseContext> target = _arrayController.selectedObjects[0];
        if (target != _delegate.browseContexts.currentContext){
            NSAlert *alert = [[NSAlert alloc] init];
            NSString* format = NSLocalizedString(@"BCTX_CONFIRM_REMOVE", nil);
            [alert setMessageText:[NSString stringWithFormat:format, target.name]];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert beginSheetModalForWindow:_panel completionHandler:^(NSModalResponse returnCode){
                if (returnCode == NSAlertFirstButtonReturn){
                    [self->_delegate.browseContexts.array removeObject:target];
                    self.array = self->_delegate.browseContexts.array;
                }
            }];
        }else{
            NSAlert *alert = [[NSAlert alloc] init];
            NSString* format = NSLocalizedString(@"BCTX_REMOVE_ERROR_DUE_TO_ACTIVE", nil);
            [alert setMessageText:[NSString stringWithFormat:format, target.name]];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert beginSheetModalForWindow:_panel completionHandler:^(NSModalResponse returnCode){}];
        }
    }
}

- (void)didEndInputContextName:(id)object
{
    if (object){
        id<BrowseContext> newContext = [_delegate.browseContexts forkCurrentContextWithName:object];
        if (newContext){
            [_delegate.browseContexts.array addObject:newContext];
            self.array = _delegate.browseContexts.array;
            _arrayController.selectionIndex = self.array.count - 1;
            [_delegate changeBrowsingContextWithName:newContext.name];
        }
    }
    _newBrowsingContextController = nil;
}

@end
