//
//  ParingWindowController.m
//  DigViewer
//
//  Created by opiopan on 2015/11/29.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import "PairingWindowController.h"

@interface PairingWindowController ()
@property (strong) IBOutlet NSWindow *window;
@property (nonatomic) NSString* inputHash;
@property (weak) IBOutlet NSButton *okButton;
@end



@implementation PairingWindowController{
    PairingWindowCompletionHandler _completionHandler;
    NSString* _referenceHashString;
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
        [[NSBundle mainBundle] loadNibNamed:@"PairingWindow" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [self reflectOkButtonState];
}

//-----------------------------------------------------------------------------------------
// ペアリング開始
//-----------------------------------------------------------------------------------------
- (void)startPairingWithCompletionHandler:(PairingWindowCompletionHandler)handler
{
    _completionHandler = handler;
    _referenceHashString = [NSString stringWithFormat:@"%04ld", (long)self.keyHash];
    [self.window makeKeyAndOrderFront:self];
}

//-----------------------------------------------------------------------------------------
// OKボタン・キャンセルボタン応答
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender
{
    [self reflectOkButtonState];
    if (_okButton.enabled){
        [self.window close];
        _completionHandler(YES);
    }
}

- (IBAction)onCancel:(id)sender
{
    [self.window close];
    _completionHandler(NO);
}

- (void)closeWindow
{
    [self onCancel:nil];
}

//-----------------------------------------------------------------------------------------
// ハッシュ値の妥当性検証
//-----------------------------------------------------------------------------------------
- (void) reflectOkButtonState
{
    self.okButton.enabled = [self.inputHash isEqualToString:_referenceHashString];
}

- (void)setInputHash:(NSString *)inputHash
{
    _inputHash = inputHash;
    [self reflectOkButtonState];
}

@end
