//
//  NewBrowsingContextController.m
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/05.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import "NewBrowsingContextController.h"

@implementation NewBrowsingContextController{
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;
}

//-----------------------------------------------------------------------------------------
// Initialize
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"NewBrowsingContextSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
}

//-----------------------------------------------------------------------------------------
// Generate sheet
//-----------------------------------------------------------------------------------------
- (void)inputContextNameforWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
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
        [_delegate performSelector:_didEndSelector withObject:_contextName afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// Response handlers for OK button and Cancel button
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseOK];
}

- (IBAction)onCancel:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseCancel];
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setContextName:(NSString *)name
{
    _contextName = name;
    self.isEnableOKButton = _contextName && _contextName.length > 0; }

@end
