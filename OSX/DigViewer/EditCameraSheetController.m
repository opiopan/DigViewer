//
//  EditCameraSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/07/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditCameraSheetController.h"
#import "LensLibrary.h"
#import "InputCameraNameController.h"

@implementation EditCameraSheetController{
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;

    LensLibrary* __weak _lensLibrary;
    InputCameraNameController* _inputCameraSheet;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"EditCameraSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
        _okButtonIsEnable = NO;
        _lensLibrary = [LensLibrary sharedLensLibrary];
    }
    
    return self;
}

- (void) awakeFromNib
{
    NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    _applicableListController.sortDescriptors = sortDescriptors;
    _inapplicableListController.sortDescriptors = sortDescriptors;
}

//-----------------------------------------------------------------------------------------
// レンズプロファイル保存エラーのメッセージ出力
//-----------------------------------------------------------------------------------------
- (void)presentSaveError:(NSError*)error
{
    [[NSApplication sharedApplication] presentError:error];
}

//-----------------------------------------------------------------------------------------
// 編集シート開始
//-----------------------------------------------------------------------------------------
- (void)editCameraList:(NSArray *)cameras forWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
    // リスト生成
    NSMutableArray* applicableList = [NSMutableArray array];
    NSMutableArray* inapplicableList = [NSMutableArray array];
    NSArray* all = _lensLibrary.allCameraProfiles;
    for (Camera* camera in all){
        if (!camera.name || camera.name.length < 1){
            // skip
        }else if ([cameras containsObject:camera]){
            [applicableList addObject:camera];
        }else{
            [inapplicableList addObject:camera];
        }
    }
    self.applicableList = applicableList;
    self.inapplicableList = inapplicableList;
    
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
        [_delegate performSelector:_didEndSelector withObject:_applicableList afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// 追加・削除ボタン応答
//-----------------------------------------------------------------------------------------
- (void)addOrRemoveCamera:(id)sender
{
    NSSegmentedControl* button = sender;
    NSInteger selectedSegment = button.selectedSegment;
    if (selectedSegment == 0){
        // 追加ボタン
        _inputCameraSheet = [InputCameraNameController new];
        [_inputCameraSheet inputCameraNameforWindow:_panel modalDelegate:self didEndSelector:@selector(didEndInputCameraName:)];
    }else{
        // 削除ボタン
        NSArray* selectedObjects = _inapplicableListController.selectedObjects;
        if (selectedObjects.count > 0){
            NSString* all = @"";
            NSString* used = @"";
            for (Camera* camera in selectedObjects){
                all = [all stringByAppendingFormat:@"%@\n", camera.name];
                if (camera.lens.count > 0){
                    used = [used stringByAppendingFormat:@"%@\n", camera.name];
                }
            }
            NSAlert *alert = [[NSAlert alloc] init];
            if (used.length > 0){
                [alert setMessageText:NSLocalizedString(@"CPMSG_WARNING_USED", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [alert setInformativeText:[NSString stringWithFormat:@"%@", used]];
                [alert beginSheetModalForWindow:_panel completionHandler:^(NSModalResponse returnCode) {
                    [self didEndConfirmRemovingCamera:self->_panel returnCode:returnCode contextInfo:nil];
                }];
            }else{
                [alert setMessageText:NSLocalizedString(@"CPMSG_CONF_REMOVE", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [alert setInformativeText:[NSString stringWithFormat:@"%@", all]];
                [alert beginSheetModalForWindow:_panel completionHandler:^(NSModalResponse returnCode) {
                    [self didEndConfirmRemovingCamera:self->_panel returnCode:returnCode contextInfo:nil];
                }];
            }
        }
    }
}

- (void)didEndInputCameraName:(id)object
{
    if (object){
        NSArray* check = [_lensLibrary findCameraByName:object];
        if (check && check.count > 0){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"CPMSG_ERROR_CONFLICT", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert setInformativeText:[NSString stringWithFormat:@"%@", object]];
            [alert beginSheetModalForWindow:_panel completionHandler:nil];
            return;
        }
        
        Camera* camera = [_lensLibrary insertNewCameraEntity];
        camera.name = object;
        NSError* error;
        [_lensLibrary persistChange:&error];
        if (error){
            [self presentSaveError:error];
        }
        [self willChangeValueForKey:@"inapplicableList"];
        [_inapplicableList addObject:camera];
        [self didChangeValueForKey:@"inapplicableList"];
    }
}

- (void)didEndConfirmRemovingCamera:(NSWindow *)sheet returnCode:(NSModalResponse)returnCode contextInfo:(void  *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn){
        NSArray* selectedObjects = [NSArray arrayWithArray:_inapplicableListController.selectedObjects];
        [self willChangeValueForKey:@"inapplicableList"];
        [_inapplicableList removeObjectsInArray:selectedObjects];
        for (Camera* camera in selectedObjects){
            [_lensLibrary.managedObjectContext deleteObject:camera];
        }
        [self didChangeValueForKey:@"inapplicableList"];

        NSError* error = nil;
        [_lensLibrary.managedObjectContext save:&error];
        if (error){
            [self presentSaveError:error];
        }
    }
}

//-----------------------------------------------------------------------------------------
// 適用・非適用ボタン応答
//-----------------------------------------------------------------------------------------
- (void)onApplicate:(id)sender
{
    if (_inapplicableListController.selectedObjects.count > 0){
        [self willChangeValueForKey:@"applicableList"];
        [self willChangeValueForKey:@"inapplicableList"];
        NSArray* selectedObjects = [NSArray arrayWithArray:_inapplicableListController.selectedObjects];
        [_inapplicableList removeObjectsInArray:selectedObjects];
        [_applicableList addObjectsFromArray:selectedObjects];
        [self didChangeValueForKey:@"applicableList"];
        [self didChangeValueForKey:@"inapplicableList"];
        _applicableListController.selectedObjects = selectedObjects;
        self.okButtonIsEnable = YES;
    }
}

- (void)onInapplicate:(id)sender
{
    if (_applicableListController.selectedObjects.count > 0){
        [self willChangeValueForKey:@"applicableList"];
        [self willChangeValueForKey:@"inapplicableList"];
        NSArray* selectedObjects = [NSArray arrayWithArray:_applicableListController.selectedObjects];
        [_applicableList removeObjectsInArray:selectedObjects];
        [_inapplicableList addObjectsFromArray:selectedObjects];
        [self didChangeValueForKey:@"applicableList"];
        [self didChangeValueForKey:@"inapplicableList"];
        _inapplicableListController.selectedObjects = selectedObjects;
        self.okButtonIsEnable = YES;
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
