//
//  SelectNewConditionSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/07/28.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SelectNewConditionSheetController.h"
#import "LensLibrary.h"

@implementation SelectNewConditionSheetController {
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
        _targets = @[@{@"name":[Condition stringForTarget:LFCONDITION_TARGET_CAMERA_MAKE]},
                     @{@"name":[Condition stringForTarget:LFCONDITION_TARGET_CAMERA_NAME]},
                     @{@"name":[Condition stringForTarget:LFCONDITION_TARGET_LENS_MAKE]},
                     @{@"name":[Condition stringForTarget:LFCONDITION_TARGET_LENS_NAME]},
                     @{@"name":[Condition stringForTarget:LFCONDITION_TARGET_FOCAL_LENGTH]},
                     @{@"name":[Condition stringForTarget:LFCONDITION_TARGET_FOCAL_LENGTH35]},
                     @{@"name":[Condition stringForTarget:LFCONDITION_TARGET_APERTURE]}];

        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"SelectNewConditionSheet" owner:self topLevelObjects:&objects];
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
- (void)selectNewConditionforWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
    [_window beginSheet:self.panel completionHandler:^(NSModalResponse returnCode){
        [self didEndSheet:self.panel returnCode:returnCode contextInfo:nil];
    }];
}

//-----------------------------------------------------------------------------------------
// シート終了
//-----------------------------------------------------------------------------------------
- (void) didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    if (returnCode == NSModalResponseOK){
        [_delegate performSelector:_didEndSelector withObject:@(_selectedIndexForTarget) afterDelay:0];
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
