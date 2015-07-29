//
//  EditConditionSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/07/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditConditionSheetController.h"
#import "SelectNewConditionSheetController.h"
#import "SelectDeletingConditionSheetController.h"

@implementation EditConditionSheetController{
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;
    
    LensLibrary* __weak _lensLibrary;
    
    NSArray* _operatorsForString;
    NSArray* _operatorsForDouble;
    
    SelectNewConditionSheetController* _selectNewConditionSheet;
    SelectDeletingConditionSheetController* _selectDeletingWaySheet;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"EditConditionSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
        _okButtonIsEnable = NO;
        _lensLibrary = [LensLibrary sharedLensLibrary];
        
        _operatorsForString = @[@{@"name":[Condition stringForOperator:LFCONDITION_OP_EQ], @"op":@(LFCONDITION_OP_EQ)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_NE], @"op":@(LFCONDITION_OP_NE)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_LEFTHAND_MATCH],
                                  @"op":@(LFCONDITION_OP_LEFTHAND_MATCH)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_RIGHTHAND_MATCH],
                                  @"op":@(LFCONDITION_OP_RIGHTHAND_MATCH)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_PARTIAL_MATCH],
                                  @"op":@(LFCONDITION_OP_PARTIAL_MATCH)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_IS_NULL], @"op":@(LFCONDITION_OP_IS_NULL)}];

        _operatorsForDouble = @[@{@"name":[Condition stringForOperator:LFCONDITION_OP_EQ], @"op":@(LFCONDITION_OP_EQ)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_NE], @"op":@(LFCONDITION_OP_NE)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_GT], @"op":@(LFCONDITION_OP_GT)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_GE], @"op":@(LFCONDITION_OP_GE)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_LT], @"op":@(LFCONDITION_OP_LT)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_LE], @"op":@(LFCONDITION_OP_LE)},
                                @{@"name":[Condition stringForOperator:LFCONDITION_OP_IS_NULL], @"op":@(LFCONDITION_OP_IS_NULL)}];
    }
    
    return self;
}

- (void) awakeFromNib
{
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
- (void)editCondition:(Condition *)condition forWindow:(NSWindow *)window
        modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
    [self willChangeValueForKey:@"condition"];
    _condition = condition;
    [self didChangeValueForKey:@"condition"];
    [_conditionTreeView expandItem:nil expandChildren:YES];
    
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
        [_delegate performSelector:_didEndSelector withObject:_condition afterDelay:0];
    }else{
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
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
// 条件ツリー選択位置変更
//-----------------------------------------------------------------------------------------
- (void)setSelectionIndexesInCondition:(NSArray *)selectionIndexesInCondition
{
    _selectionIndexesInCondition = selectionIndexesInCondition;
    Condition* current = selectionIndexesInCondition.count ? [_conditionTreeController.selection valueForKey:@"me"] : nil;
    if (!current){
        [_propertiesTabView selectTabViewItemAtIndex:0];
    }else if (current.conditionType.intValue == LFCONDITION_TYPE_COMPARISON){
        [self willChangeValueForKey:@"targetName"];
        [self willChangeValueForKey:@"operators"];
        [self willChangeValueForKey:@"comparisonValue"];
        [self willChangeValueForKey:@"selectedIndexInOperators"];
        _targetName = [Condition stringForTarget:current.target.intValue];
        _operators = [Condition targetIsString:current.target.intValue] ? _operatorsForString : _operatorsForDouble;
        _comparisonValue = [Condition targetIsString:current.target.intValue] ? current.valueString :
                                                                                [current.valueDouble stringValue];
        int i;
        for (i = 0; i < _operators.count; i++){
            int optype = [[_operators[i] valueForKey:@"op"] intValue];
            if (optype == [current.operatorType intValue]){
                break;
            }
        }
        _selectedIndexInOperators = i < _operators.count ? i : 0;
        [self didChangeValueForKey:@"targetName"];
        [self didChangeValueForKey:@"operators"];
        [self didChangeValueForKey:@"comparisonValue"];
        [self didChangeValueForKey:@"selectedIndexInOperators"];
        [_propertiesTabView selectTabViewItemAtIndex:2];
    }else{
        [self willChangeValueForKey:@"groupingConditon"];
        _groupingConditon = current.conditionType.intValue;
        [self didChangeValueForKey:@"groupingConditon"];
        [_propertiesTabView selectTabViewItemAtIndex:1];
    }
    
    [self updateButtonState];
}

//-----------------------------------------------------------------------------------------
// ボタン状態決定
//-----------------------------------------------------------------------------------------
- (void)updateButtonState
{
    Condition* current = _conditionTreeController.selectionIndexPaths.count > 0 ?
                        [_conditionTreeController.selection valueForKey:@"me"] : nil;
    if (!current){
        self.addButtonIsEnable = NO;
        self.removeButtonIsEnable = NO;
        self.embedButtonIsEnable = NO;
    }else if (current.conditionType.intValue == LFCONDITION_TYPE_COMPARISON){
        self.addButtonIsEnable = YES;
        self.embedButtonIsEnable = YES;
        if (![self removableCondition:current withShrink:NO]){
            self.removeButtonIsEnable = NO;
        }else{
            self.removeButtonIsEnable = YES;
        }
    }else{
        self.addButtonIsEnable = YES;
        self.embedButtonIsEnable = YES;
        if (current == _condition){
            self.removeButtonIsEnable = NO;
        }else{
            self.removeButtonIsEnable = YES;
        }
    }
}

//-----------------------------------------------------------------------------------------
// 追加ボタン応答
//-----------------------------------------------------------------------------------------
- (void)addCondition:(id)sender
{
    _selectNewConditionSheet = [SelectNewConditionSheetController new];
    [_selectNewConditionSheet selectNewConditionforWindow:_panel
                                            modalDelegate:self didEndSelector:@selector(didEndAddCondition:)];
}

- (void)didEndAddCondition:(NSNumber*)targetType
{
    if (targetType){
        Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
        Condition* parent = current.conditionType.intValue == LFCONDITION_TYPE_COMPARISON ? current.parent : current;
        Condition* newNode = [_lensLibrary insertNewConditionEntity];
        newNode.conditionType = @(LFCONDITION_TYPE_COMPARISON);
        newNode.target = targetType;
        newNode.operatorType = @(LFCONDITION_OP_EQ);
        if ([Condition targetIsString:targetType.intValue]){
            newNode.valueString = @"value";
        }else{
            newNode.valueDouble = @0;
        }
        [parent addChildrenObject:newNode];
        self.okButtonIsEnable = YES;
        [self updateButtonState];
        self.selectionIndexesInCondition = _selectionIndexesInCondition;
    }
    _selectNewConditionSheet = nil;
}

//-----------------------------------------------------------------------------------------
// 削除ボタン応答
//-----------------------------------------------------------------------------------------
- (void)removeCondition:(id)sender
{
    Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
    if (current.conditionType.intValue == LFCONDITION_TYPE_COMPARISON){
        while (current.parent && current.parent.children.count < 2){
            current = current.parent;
        }
        Condition* parent = current.parent;
        if (parent){
            [parent removeChildrenObject:current];
            [_lensLibrary removeConditionRecurse:current];
            self.okButtonIsEnable = YES;
            [self updateButtonState];
        }
    }else{
        _selectDeletingWaySheet = [SelectDeletingConditionSheetController new];
        [_selectDeletingWaySheet selectDeletingWayforWindow:_panel
                                              modalDelegate:self didEndSelector:@selector(didEndConfirmDeletingWay:)];
    }
}

- (void)didEndConfirmDeletingWay:(NSNumber*)recurseDeleting
{
    if (recurseDeleting){
        Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
        if (recurseDeleting.boolValue){
            while (current.parent && current.parent.children.count < 2){
                current = current.parent;
            }
            Condition* parent = current.parent;
            if (parent){
                [parent removeChildrenObject:current];
                [_lensLibrary removeConditionRecurse:current];
                self.okButtonIsEnable = YES;
                [self updateButtonState];
            }else{
                NSBeginAlertSheet(NSLocalizedString(@"CDMSG_ERROR_ONLYONE", nill),
                                  NSLocalizedString(@"OK", nil), nil,
                                  nil, _panel,
                                  nil, nil, nil, nil,
                                  @"");
            }
        }else{
            Condition* parent = current.parent;
            if (parent){
                NSMutableArray* buf = [NSMutableArray array];
                for (Condition* child in current.children){
                    [buf addObject:child];
                }
                for (Condition* child in buf){
                    [parent addChildrenObject:child];
                }
                [_lensLibrary removeConditionRecurse:current];
                self.okButtonIsEnable = YES;
                [self updateButtonState];
            }
        }
    }
    _selectDeletingWaySheet = nil;
}

//-----------------------------------------------------------------------------------------
// 新規グループ作成ボタン応答
//-----------------------------------------------------------------------------------------
- (void)embedInNewGroup:(id)sender
{
    Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
    Condition* parent = current.parent;
    Condition* newNode = [_lensLibrary insertNewConditionEntity];
    newNode.conditionType = @(LFCONDITION_TYPE_OR);
    if (parent){
        [parent removeChildrenObject:current];
        [newNode addChildrenObject:current];
        [parent addChildrenObject:newNode];
    }else{
        [self willChangeValueForKey:@"condition"];
        _condition = newNode;
        [newNode addChildrenObject:current];
        [self didChangeValueForKey:@"condition"];
    }
    self.okButtonIsEnable = YES;
    [self updateButtonState];
    [_conditionTreeView expandItem:nil expandChildren:YES];
}

//-----------------------------------------------------------------------------------------
// ノード削除可能性判定（唯一のcomparisonかを判定)
//-----------------------------------------------------------------------------------------
- (BOOL)removableCondition:(Condition*)condition withShrink:(BOOL)isShrink
{
    if (condition == _condition){
        return condition.children.count > 1;
    }else if (isShrink && condition.children.count > 1){
        return YES;
    }else{
        return [self removableCondition:condition.parent withShrink:YES];
    }
}

//-----------------------------------------------------------------------------------------
// バインディング用属性の実装
//-----------------------------------------------------------------------------------------
- (void)setGroupingConditon:(NSInteger)groupingConditon
{
    _groupingConditon = groupingConditon;
    Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
    current.conditionType = @(groupingConditon);
    [current updateProperties];
    self.okButtonIsEnable = YES;
}

- (void)setSelectedIndexInOperators:(NSInteger)selectedIndexInOperators
{
    _selectedIndexInOperators = selectedIndexInOperators;
    Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
    current.operatorType = [_operators[selectedIndexInOperators] valueForKey:@"op"];
    [current updateProperties];
    self.okButtonIsEnable = YES;
}

- (void)setComparisonValue:(NSString *)comparisonValue
{
    Condition* current = [_conditionTreeController.selection valueForKey:@"me"];
    NSString* value = nil;
    if ([Condition targetIsString:current.target.intValue]){
        value = comparisonValue;
        current.valueString = value;
    }else{
        NSScanner* scanner = [NSScanner scannerWithString:comparisonValue];
        double numericValue;
        if (![scanner scanDouble:&numericValue]){
            NSBeginAlertSheet(NSLocalizedString(@"CDMSG_ERROR_INVALID_AS_NUMERIC", nill),
                              NSLocalizedString(@"OK", nil), nil,
                              nil, _panel,
                              nil, nil, nil, nil,
                              @"%@", comparisonValue);
            [self performSelector:@selector(comparisonValueReflection:) withObject:_comparisonValue afterDelay:0];
            return;
        }
        current.valueDouble = @(numericValue);
        value = current.valueDouble.stringValue;
    }
    [self performSelector:@selector(comparisonValueReflection:) withObject:value afterDelay:0];
    [current updateProperties];
    self.okButtonIsEnable = YES;
}

- (void)comparisonValueReflection:(NSString*)comparisonValue
{
    [self willChangeValueForKey:@"comparisonValue"];
    _comparisonValue = comparisonValue;
    [self didChangeValueForKey:@"comparisonValue"];
}

@end
