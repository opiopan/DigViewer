//
//  EditCustomEffectController.m
//  DigViewer
//
//  Created by opiopan on 2015/06/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditCustomEffectController.h"

@implementation EditCustomEffectController{
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
        [[NSBundle mainBundle] loadNibNamed:@"EditCustomEffect" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
}

//-----------------------------------------------------------------------------------------
// シート開始
//-----------------------------------------------------------------------------------------
- (void)editEffectForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
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
        [_delegate performSelector:_didEndSelector withObject:self afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// OKボタン・キャンセルボタン応答
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender {
    if (self.enableOKButton){
        [self.panel close];
        [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseOK];
    }
}

- (IBAction)onCancel:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSModalResponseCancel];
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setName:(NSString *)name
{
    _name = name;
    self.isChanged = YES;
}

- (void)setDuration:(CGFloat)duration
{
    _duration = duration;
    self.isChanged = YES;
}

- (void)setIsChanged:(BOOL)isChanged
{
    _isChanged = isChanged;
    [self willChangeValueForKey:@"enableOKButton"];
    [self didChangeValueForKey:@"enableOKButton"];
}

- (BOOL)enableOKButton
{
    return _isChanged && _name && _name.length > 0;
}

@end
