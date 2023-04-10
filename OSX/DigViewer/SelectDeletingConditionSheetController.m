//
//  SelectDeletingConditionSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/07/28.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SelectDeletingConditionSheetController.h"

@implementation SelectDeletingConditionSheetController {
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"SelectDeletingConditionSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
}

//-----------------------------------------------------------------------------------------
// 編集シート開始
//-----------------------------------------------------------------------------------------
- (void)selectDeletingWayforWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
    self.deletingWay = 1;
    
    [[NSApplication sharedApplication] beginSheet:self.panel
                                   modalForWindow:_window
                                    modalDelegate:self
                                   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                      contextInfo:nil];
}

//-----------------------------------------------------------------------------------------
// シート終了
//-----------------------------------------------------------------------------------------
- (void) didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == NSModalResponseOK){
        [_delegate performSelector:_didEndSelector withObject:@(_deletingWay == 0) afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// OKボタン・キャンセルボタン応答
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseOK];
}

- (IBAction)onCancel:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseCancel];
}

@end
