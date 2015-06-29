//
//  EditCustomEffectListController.m
//  DigViewer
//
//  Created by opiopan on 2015/06/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditCustomEffectListController.h"
#import "SlideshowConfigController.h"
#import "EditCustomEffectController.h"

@implementation EditCustomEffectListController{
    NSMutableArray* _effectsForEdit;
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    NSArray* _topLevelObjects;
    EditCustomEffectController* _editSheet;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"EditCustomEffectList" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [_effectsTableView setTarget:self];
    [_effectsTableView setDoubleAction:@selector(onDoubleClickEffectsTableView:)];
}

//-----------------------------------------------------------------------------------------
// シート開始
//-----------------------------------------------------------------------------------------
- (void)editEffectList:(NSArray *)effects forWindow:(NSWindow *)window modalDelegate:(id)delegate
        didEndSelector:(SEL)didEndSelector
{
    [self willChangeValueForKey:@"effects"];
    _effectsForEdit = [NSMutableArray arrayWithArray:effects];
    [self didChangeValueForKey:@"effects"];
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
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
    if (returnCode == NSOKButton){
        [_delegate performSelector:_didEndSelector withObject:_effectsForEdit afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (NSArray *)effects
{
    return _effectsForEdit;
}

//-----------------------------------------------------------------------------------------
// OKボタン・キャンセルボタン応答
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSOKButton];
}

- (IBAction)onCancel:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSCancelButton];
}

//-----------------------------------------------------------------------------------------
// エフェクト追加・削除ボタンの応答
//-----------------------------------------------------------------------------------------
- (IBAction)addOrRemoveEffect:(id)sender
{
    NSSegmentedControl* button = sender;
    NSInteger selectedSegment = button.selectedSegment;
    if (selectedSegment == 0){
        // adding
        NSOpenPanel* openPanel = [NSOpenPanel openPanel];
        openPanel.allowedFileTypes = @[@"cikernel", @"CIKERNEL"];
        
        NSMutableArray* effects = _effectsForEdit;
        EditCustomEffectListController* __weak weakSelf = self;
        _editSheet = [EditCustomEffectController new];
        NSWindow* panel = _panel;
        EditCustomEffectController* __weak editSheet = _editSheet;
        
        [openPanel beginSheetModalForWindow:_panel completionHandler:^(NSModalResponse response){
            if (response == NSModalResponseOK){
                NSString* path = openPanel.URL.path;
                EffectType type;
                if ([[[path pathExtension] lowercaseString] isEqualToString:@"cikernel"]){
                    type = effectCIKernel;
                }else{
                    type = effectQCComposition;
                }
                id entry = [SlideshowConfigController customEffectWithName:@"" type:type path:path duration:0];
                NSInteger index = [effects indexOfObject:entry];
                if (index == NSNotFound){
                    editSheet.name = [path lastPathComponent];
                    editSheet.duration = 1.0;
                    editSheet.path = path;
                    editSheet.type = type;
                    editSheet.typeString = [entry valueForKey:@"typeString"];
                    editSheet.isChanged = YES;
                    [editSheet editEffectForWindow:panel modalDelegate:weakSelf didEndSelector:@selector(didEndEditEffect:)];
                }else{
                    // 既に登録済み
                    [self performSelector:@selector(showConflictErrorWithSubtext:) withObject:path afterDelay:0];
                }
            }
        }];
    }else if (selectedSegment == 1){
        // deleting
        if (_effectsArrayController.selectedObjects && _effectsArrayController.selectedObjects.count > 0){
            id effect = _effectsArrayController.selectedObjects[0];
            NSBeginAlertSheet(NSLocalizedString(@"CEMSG_CONF_REMOVE", nill),
                              NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil),
                              nil, _panel,
                              self, @selector(didEndConfirmRemovingEffect:returnCode:contextInfo:), nil, nil,
                              @"%@", [effect valueForKey:@"name"]);
        }
    }
}

- (void)didEndEditEffect:(id)object
{
    if (object){
        id entry = [SlideshowConfigController customEffectWithName:_editSheet.name type:_editSheet.type
                                                              path:_editSheet.path duration:_editSheet.duration];
        NSInteger index = [_effectsForEdit indexOfObject:entry];
        if (index == NSNotFound){
            [_effectsForEdit addObject:entry];
        }else{
            entry = _effectsForEdit[index];
            [entry setValue:_editSheet.name forKey:@"name"];
            [entry setValue:@(_editSheet.duration) forKey:@"duration"];
        }
        [self willChangeValueForKey:@"effects"];
        [self didChangeValueForKey:@"effects"];
        self.isChanged = YES;
    }

    _editSheet = nil;
}

- (void)showConflictErrorWithSubtext:(NSString*)subtext
{
    [self showAlertSheetWithMessage:NSLocalizedString(@"CEMSG_ERROR_CONFLICT", nil) andSubtext:subtext];
}

//-----------------------------------------------------------------------------------------
// エフェクト上下移動
//-----------------------------------------------------------------------------------------
- (IBAction)moveUpOrDownEffect:(id)sender
{
    if (_effectsArrayController.selectedObjects && _effectsArrayController.selectedObjects.count > 0){
        id target = _effectsArrayController.selectedObjects[0];
        NSInteger index = [_effectsForEdit indexOfObject:target];
        NSSegmentedControl* button = sender;
        NSInteger selectedSegment = button.selectedSegment;
        if (selectedSegment == 0){
            /* 上に移動 */
            if (index > 0){
                [_effectsForEdit removeObject:target];
                [_effectsForEdit insertObject:target atIndex:index - 1];
                [self willChangeValueForKey:@"effects"];
                [self didChangeValueForKey:@"effects"];
                self.isChanged = YES;
            }
        }else{
            /* 下に移動 */
            if (index < _effectsForEdit.count - 1){
                [_effectsForEdit removeObject:target];
                [_effectsForEdit insertObject:target atIndex:index + 1];
                [self willChangeValueForKey:@"effects"];
                [self didChangeValueForKey:@"effects"];
                self.isChanged = YES;
            }
        }
    }
}

//-----------------------------------------------------------------------------------------
// エフェクト編集（ダブルクリック）
//-----------------------------------------------------------------------------------------
- (void)onDoubleClickEffectsTableView:(id)sender
{
    if (_effectsArrayController.selectedObjects.count > 0){
        id effect = _effectsArrayController.selectedObjects[0];
        _editSheet = [EditCustomEffectController new];
        _editSheet.name = [effect valueForKey:@"name"];
        _editSheet.duration = [[effect valueForKey:@"duration"] doubleValue];
        _editSheet.path = [effect valueForKey:@"path"];
        _editSheet.type = [[effect valueForKey:@"type"] intValue];
        _editSheet.typeString = [effect valueForKey:@"typeString"];
        _editSheet.isChanged = NO;
        [_editSheet editEffectForWindow:_panel modalDelegate:self didEndSelector:@selector(didEndEditEffect:)];
    }
}

//-----------------------------------------------------------------------------------------
// エフェクト削除確認
//-----------------------------------------------------------------------------------------
- (void)didEndConfirmRemovingEffect:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn){
        if (_effectsArrayController.selectedObjects && _effectsArrayController.selectedObjects.count > 0){
            id effect = _effectsArrayController.selectedObjects[0];
            [_effectsForEdit removeObject:effect];
            [self willChangeValueForKey:@"effects"];
            [self didChangeValueForKey:@"effects"];
            self.isChanged = YES;
        }
    }
}

//-----------------------------------------------------------------------------------------
// エラーメッセージ表示
//-----------------------------------------------------------------------------------------
- (void) showAlertSheetWithMessage:(NSString*)message andSubtext:(NSString*)subtext
{
    NSBeginAlertSheet(message,
                      NSLocalizedString(@"OK", nil), nil, nil, _panel,
                      self, nil, nil, nil,
                      @"%@", subtext);
}

@end
