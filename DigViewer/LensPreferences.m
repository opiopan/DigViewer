//
//  LensPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/04/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "LensPreferences.h"
#import "LensLibrary.h"
#import "EditLensSheetController.h"

@implementation LensPreferences{
    LensLibrary* __weak _lensLibrary;
    EditLensSheetController* _editLensSheet;
}

- (BOOL) isResizable
{
    return NO;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (void)initializeFromDefaults
{
    _lensLibrary = [LensLibrary sharedLensLibrary];
    [self.lensArrayController setManagedObjectContext:_lensLibrary.managedObjectContext];
    
    [_lensProfileTableView setTarget:self];
    [_lensProfileTableView setDoubleAction:@selector(onDoubleClickLensProfileTableView:)];
}

//-----------------------------------------------------------------------------------------
// レンズプロファイル保存エラーのメッセージ出力
//-----------------------------------------------------------------------------------------
- (void)presentSaveError:(NSError*)error
{
    [[NSApplication sharedApplication] presentError:error];
}

//-----------------------------------------------------------------------------------------
// レンズプロファイル追加・削除ボタンの応答
//-----------------------------------------------------------------------------------------
- (IBAction)addOrRemoveLens:(id)sender
{
    NSSegmentedControl* button = sender;
    NSInteger selectedSegment = button.selectedSegment;
    if (selectedSegment == 0){
        _editLensSheet = [[EditLensSheetController alloc] init];
        [_editLensSheet editLensEntity:nil forWindow:_preferencesView.window
                         modalDelegate:self didEndSelector:@selector(didEndEditLens:)];
    }else if (selectedSegment == 1){
        // 削除ボタン押下
        NSArray* selectedObjects = self.lensArrayController.selectedObjects;
        if (selectedObjects.count > 0){
            Lens* lens = selectedObjects[0];
            [_lensLibrary.managedObjectContext deleteObject:lens];
            NSError* error = nil;
            [_lensLibrary.managedObjectContext save:&error];
            if (error){
                [self presentSaveError:error];
            }
        }
    }
}

//-----------------------------------------------------------------------------------------
// レンズプロファイルの編集（ダブルクリック）
//-----------------------------------------------------------------------------------------
- (void)onDoubleClickLensProfileTableView:(id)sender
{
    if (_lensArrayController.selectedObjects.count > 0){
        id lens = _lensArrayController.selectedObjects[0];
        _editLensSheet = [[EditLensSheetController alloc] init];
        [_editLensSheet editLensEntity:lens forWindow:_preferencesView.window
                         modalDelegate:self didEndSelector:@selector(didEndEditLens:)];
    }
}

//-----------------------------------------------------------------------------------------
// レンズプロファイル追加・編集完了応答
//-----------------------------------------------------------------------------------------
- (void)didEndEditLens:(id)object
{
    if (object){
        NSError* error = nil;
        [_lensLibrary.managedObjectContext save:&error];
        if (error){
            NSArray* selectedObjects = _lensArrayController.selectedObjects;
            if (selectedObjects.count > 0 && selectedObjects[0] != object){
                [_lensLibrary.managedObjectContext deleteObject:object];
            }
            [self presentSaveError:error];
        }
    }
    _editLensSheet = nil;
}

@end
