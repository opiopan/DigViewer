//
//  EditLensSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditLensSheetController.h"
#import "EditCameraSheetController.h"
#import "EditConditionSheetController.h"

@implementation EditLensSheetController {
    Lens* _lensForEdit;
    NSWindow* _window;
    id _delegate;
    SEL _didEndSelector;
    
    NSArray* _topLevelObjects;
    
    BOOL _isEdited;
    LensLibrary* __weak _lensLibrary;
    NSMutableArray* _allowedCameras;
    Condition* _condition;
    Condition* _edittingCondition;
    
    EditCameraSheetController* _editCameraSheet;
    EditConditionSheetController* _editConditionSheet;
}


//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        NSArray* objects = nil;
        [[NSBundle mainBundle] loadNibNamed:@"EditLensSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
        _lensLibrary = [LensLibrary sharedLensLibrary];
    }
    
    return self;
}

- (void) awakeFromNib
{
    [self reflectOkButtonState];
}

//-----------------------------------------------------------------------------------------
// レンズプロファイル編集シート開始
//-----------------------------------------------------------------------------------------
- (void)editLensEntity:(Lens *)lens forWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
{
    _lensForEdit = lens;
    _window = window;
    _delegate = delegate;
    _didEndSelector = didEndSelector;
    
    if (_lensForEdit){
        self.profileName = _lensForEdit.name;
        self.lensMaker = _lensForEdit.lensMake;
        self.lensName = _lensForEdit.lensName;
        self.focalLengthMin = _lensForEdit.focalLengthMin;
        self.focalLengthMax = _lensForEdit.focalLengthMax;
        self.apertureMin = _lensForEdit.apertureMin;
        self.apertureMax = _lensForEdit.apertureMax;
        self.fovMin = _lensForEdit.fovMin;
        self.fovMax = _lensForEdit.fovMax;
        self.sensorHorizontal = _lensForEdit.sensorHorizontal;
        self.sensorVertical = _lensForEdit.sensorVertical;
        self.matchingType = _lensForEdit.matchingType;
        if (_lensForEdit.focalLengthMin && _lensForEdit.focalLengthRatio35){
            self.focalLength35Min = @(_lensForEdit.focalLengthMin.doubleValue * _lensForEdit.focalLengthRatio35.doubleValue);
        }
        _allowedCameras = [NSMutableArray array];
        for (Camera* camera in _lensForEdit.allowedCameras){
            [_allowedCameras addObject:camera];
        }
        if (_lensForEdit.condition){
            _condition = [self cloneCondition:_lensForEdit.condition];
        }
    }else{
        self.matchingType = @(LENS_MATCHING_BY_LENSNAME);
    }

    _isEdited = NO;
    [self reflectOkButtonState];

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
        LensLibrary* library = [LensLibrary sharedLensLibrary];
        
        if (!_lensForEdit){
            _lensForEdit = [library insertNewLensEntity];
        }
        
        _lensForEdit.name = self.profileName;
        _lensForEdit.lensMake = self.lensMaker;
        _lensForEdit.lensName = self.lensName;
        _lensForEdit.focalLengthMin = self.focalLengthMin;
        _lensForEdit.focalLengthMax = self.focalLengthMax;
        _lensForEdit.apertureMin = self.apertureMin;
        _lensForEdit.apertureMax = self.apertureMax;
        _lensForEdit.fovMin = self.fovMin;
        _lensForEdit.fovMax = self.fovMax;
        _lensForEdit.sensorHorizontal = self.sensorHorizontal;
        _lensForEdit.sensorVertical = self.sensorVertical;
        _lensForEdit.matchingType = self.matchingType;
        if (self.focalLength35Min){
            _lensForEdit.focalLengthRatio35 = @(self.focalLength35Min.doubleValue / self.focalLengthMin.doubleValue);
        }else{
            _lensForEdit.focalLengthRatio35 = nil;
        }
        [_lensForEdit removeAllowedCameras:_lensForEdit.allowedCameras];
        for (Camera* camera in _allowedCameras){
            [_lensForEdit addAllowedCamerasObject:camera];
        }
        if (_lensForEdit.matchingType.intValue == LENS_MATCHING_BY_CUSTOM_CONDITION){
            [_lensLibrary removeConditionRecurse:_lensForEdit.condition];
            _lensForEdit.condition = _condition;
        }else{
            [_lensLibrary removeConditionRecurse:_condition];
        }
        [_delegate performSelector:_didEndSelector withObject:_lensForEdit afterDelay:0];
    }else{
        [_lensLibrary removeConditionRecurse:_condition];
        [_delegate performSelector:_didEndSelector withObject:nil afterDelay:0];
    }
}

//-----------------------------------------------------------------------------------------
// OKボタンのenable状態を設定
//-----------------------------------------------------------------------------------------
- (void) reflectOkButtonState
{
    if (_focalLengthMin && _focalLengthMax && _focalLengthMin.doubleValue == _focalLengthMax.doubleValue){
        [self willChangeValueForKey:@"apertureMax"];
        [self willChangeValueForKey:@"fovMax"];
        self.isSingleFocalLength = YES;
        _apertureMax = _apertureMin;
        _fovMax = _fovMin;
        [self didChangeValueForKey:@"apertureMax"];
        [self didChangeValueForKey:@"fovMax"];
    }else{
        self.isSingleFocalLength = NO;
    }
    
    if (_focalLength35Min && _focalLengthMin && _focalLengthMax){
        [self willChangeValueForKey:@"focalLength35Max"];
        _focalLength35Max = @(_focalLength35Min.doubleValue / _focalLengthMin.doubleValue * _focalLengthMax.doubleValue);
        [self didChangeValueForKey:@"focalLength35Max"];
    }else{
        [self willChangeValueForKey:@"focalLength35Max"];
        _focalLength35Max = nil;
        [self didChangeValueForKey:@"focalLength35Max"];
    }

    if (_profileName.length > 0 &&
        _lensMaker.length > 0 &&
        _lensName.length > 0 &&
        _focalLengthMin &&
        _focalLengthMax &&
        _apertureMin &&
        _apertureMax &&
        ((_fovMin && _fovMax) || (!_fovMin && !_fovMax)) &&
        ((_sensorHorizontal && _sensorVertical) || (!_sensorHorizontal && !_sensorVertical))){
        self.okButton.enabled = _isEdited;
    }else{
        self.okButton.enabled = NO;
    }
}

//-----------------------------------------------------------------------------------------
// 値の正規化
//-----------------------------------------------------------------------------------------
- (void) normalizeValues
{
    if (_focalLengthMin && _focalLengthMax && _focalLengthMin.doubleValue > _focalLengthMax.doubleValue){
        NSNumber* tmp = _focalLengthMax;
        self.focalLengthMax = _focalLengthMin;
        self.focalLengthMin = tmp;
    }
    if (_apertureMin && _apertureMax && _apertureMin.doubleValue > _apertureMax.doubleValue){
        NSNumber* tmp = _apertureMax;
        self.apertureMax = _apertureMin;
        self.apertureMin = tmp;
    }
    if (_fovMin && _fovMax && _fovMin.doubleValue < _fovMax.doubleValue){
        NSNumber* tmp = _fovMax;
        self.fovMax = _fovMin;
        self.fovMin = tmp;
    }
    if (_sensorHorizontal && _sensorVertical && _sensorHorizontal.doubleValue < _sensorVertical.doubleValue){
        NSNumber* tmp = _sensorHorizontal;
        self.sensorHorizontal = _sensorVertical;
        self.sensorVertical = tmp;
    }
}

//-----------------------------------------------------------------------------------------
// 条件ツリーのクローン
//-----------------------------------------------------------------------------------------
- (Condition*)cloneCondition:(Condition*)condition
{
    Condition* rc = nil;
    if (condition){
        rc = [_lensLibrary insertNewConditionEntity];
        rc.conditionType = condition.conditionType;
        rc.target = condition.target;
        rc.operatorType = condition.operatorType;
        rc.valueDouble = condition.valueDouble;
        rc.valueString = condition.valueString;
        for (Condition* child in condition.children){
            [rc addChildrenObject:[self cloneCondition:child]];
        }
    }else{
        //条件が空の場合はデフォルトのツリー（レンズ名で一致）を作成
        rc = [_lensLibrary insertNewConditionEntity];
        rc.conditionType = @(LFCONDITION_TYPE_OR);
        Condition* child = [_lensLibrary insertNewConditionEntity];
        child.conditionType = @(LFCONDITION_TYPE_COMPARISON);
        child.target = @(LFCONDITION_TARGET_LENS_NAME);
        child.operatorType = @(LFCONDITION_OP_EQ);
        child.valueString = _lensName;
        [rc addChildrenObject:child];
    }
    return rc;
}

//-----------------------------------------------------------------------------------------
// カメラ編集ボタン応答
//-----------------------------------------------------------------------------------------
- (void)onEditCamera:(id)sender
{
    _editCameraSheet = [EditCameraSheetController new];
    [_editCameraSheet editCameraList:_allowedCameras forWindow:_panel
                       modalDelegate:self didEndSelector:@selector(didEndEditCamera:)];
}

- (void)didEndEditCamera:(id)object
{
    if (object){
        _allowedCameras = object;
        _isEdited = YES;
        [self reflectOkButtonState];
    }
    _editCameraSheet = nil;
}

//-----------------------------------------------------------------------------------------
// 条件編集ボタン応答
//-----------------------------------------------------------------------------------------
- (void)onEditCondition:(id)sender
{
    _editConditionSheet = [EditConditionSheetController new];
    _edittingCondition = [self cloneCondition:_condition];
    [_editConditionSheet editCondition:_edittingCondition forWindow:_panel
                         modalDelegate:self didEndSelector:@selector(didEndEditCondition:)];
}

- (void)didEndEditCondition:(id)object
{
    if (object){
        [_lensLibrary removeConditionRecurse:_condition];
        _condition = _edittingCondition;
        _edittingCondition = nil;
        _isEdited = YES;
        [self reflectOkButtonState];
    }else{
        [_lensLibrary removeConditionRecurse:_edittingCondition];
        _edittingCondition = nil;
    }
    _editConditionSheet = nil;
}

//-----------------------------------------------------------------------------------------
// OKボタン・キャンセルボタン応答
//-----------------------------------------------------------------------------------------
- (IBAction)onOk:(id)sender {
    [self reflectOkButtonState];
    if (_okButton.enabled){
        [self normalizeValues];
        [self.panel close];
        [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSOKButton];
    }
}

- (IBAction)onCancel:(id)sender {
    [self.panel close];
    [[NSApplication sharedApplication] endSheet:self.panel returnCode:NSCancelButton];
}

//-----------------------------------------------------------------------------------------
// 各編集ボタン状態
//-----------------------------------------------------------------------------------------
- (BOOL)isEnableEditCameras
{
    return _matchingType.intValue == LENS_MATCHING_BY_LENSNAME_AND_CAMERANAME;
}

- (BOOL)isEnableEditConditions
{
    return _matchingType.intValue == LENS_MATCHING_BY_CUSTOM_CONDITION;
}

//-----------------------------------------------------------------------------------------
// プロパティの設定メッソッド実装
//-----------------------------------------------------------------------------------------
- (void)setProfileName:(NSString *)profileName
{
    _profileName = profileName;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setLensMaker:(NSString *)lensMaker
{
    _lensMaker = lensMaker;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setLensName:(NSString *)lensName
{
    _lensName = lensName;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setFocalLengthMin:(NSNumber *)focalLengthMin
{
    _focalLengthMin = focalLengthMin;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setFocalLengthMax:(NSNumber *)focalLengthMax
{
    _focalLengthMax = focalLengthMax;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setFocalLength35Min:(NSNumber *)focalLength35Min
{
    _focalLength35Min = focalLength35Min;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setApertureMin:(NSNumber *)apertureMin
{
    _apertureMin = apertureMin;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setApertureMax:(NSNumber *)apertureMax
{
    _apertureMax = apertureMax;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setFovMin:(NSNumber *)fovMin
{
    _fovMin = fovMin;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setFovMax:(NSNumber *)fovMax
{
    _fovMax = fovMax;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setSensorHorizontal:(NSNumber *)sensorHorizontal
{
    _sensorHorizontal = sensorHorizontal;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setSensorVertical:(NSNumber *)sensorVertical
{
    _sensorVertical = sensorVertical;
    _isEdited = YES;
    [self reflectOkButtonState];
}

- (void)setMatchingType:(NSNumber *)matchingType
{
    _matchingType = matchingType;
    _isEdited = YES;
    [self willChangeValueForKey:@"isEnableEditCameras"];
    [self willChangeValueForKey:@"isEnableEditConditions"];
    [self didChangeValueForKey:@"isEnableEditCameras"];
    [self didChangeValueForKey:@"isEnableEditConditions"];
    [self reflectOkButtonState];
}

@end
