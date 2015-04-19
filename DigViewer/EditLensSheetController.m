//
//  EditLensSheetController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EditLensSheetController.h"

@implementation EditLensSheetController {
    Lens* _lensForEdit;
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
        [[NSBundle mainBundle] loadNibNamed:@"EditLensSheet" owner:self topLevelObjects:&objects];
        _topLevelObjects = objects;
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
    }else{
        self.matchingType = @(LENS_MATCHING_BY_LENSNAME);
    }

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

        [_delegate performSelector:_didEndSelector withObject:_lensForEdit afterDelay:0];
    }else{
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

    if (_profileName.length > 0 &&
        _lensMaker.length > 0 &&
        _lensName.length > 0 &&
        _focalLengthMin &&
        _focalLengthMax &&
        _apertureMin &&
        _apertureMax &&
        ((_fovMin && _fovMax) || (!_fovMin && !_fovMax)) &&
        ((_sensorHorizontal && _sensorVertical) || (!_sensorHorizontal && !_sensorVertical))){
        self.okButton.enabled = YES;
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
// プロパティの設定メッソッド実装
//-----------------------------------------------------------------------------------------
- (void)setProfileName:(NSString *)profileName
{
    _profileName = profileName;
    [self reflectOkButtonState];
}

- (void)setLensMaker:(NSString *)lensMaker
{
    _lensMaker = lensMaker;
    [self reflectOkButtonState];
}

- (void)setLensName:(NSString *)lensName
{
    _lensName = lensName;
    [self reflectOkButtonState];
}

- (void)setFocalLengthMin:(NSNumber *)focalLengthMin
{
    _focalLengthMin = focalLengthMin;
    [self reflectOkButtonState];
}

- (void)setFocalLengthMax:(NSNumber *)focalLengthMax
{
    _focalLengthMax = focalLengthMax;
    [self reflectOkButtonState];
}

- (void)setApertureMin:(NSNumber *)apertureMin
{
    _apertureMin = apertureMin;
    [self reflectOkButtonState];
}

- (void)setApertureMax:(NSNumber *)apertureMax
{
    _apertureMax = apertureMax;
    [self reflectOkButtonState];
}

- (void)setFovMin:(NSNumber *)fovMin
{
    _fovMin = fovMin;
    [self reflectOkButtonState];
}

- (void)setFovMax:(NSNumber *)fovMax
{
    _fovMax = fovMax;
    [self reflectOkButtonState];
}

- (void)setSensorHorizontal:(NSNumber *)sensorHorizontal
{
    _sensorHorizontal = sensorHorizontal;
    [self reflectOkButtonState];
}

- (void)setSensorVertical:(NSNumber *)sensorVertical
{
    _sensorVertical = sensorVertical;
    [self reflectOkButtonState];
}

@end
