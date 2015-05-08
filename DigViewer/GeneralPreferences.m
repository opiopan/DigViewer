//
//  GeneralPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/04/11.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "GeneralPreferences.h"
#import "DocumentConfigController.h"
#import "EditImageSetSheetController.h"

@implementation GeneralPreferences{
    EditImageSetSheetController* _editImageSetSheet;
}

- (BOOL) isResizable
{
    return NO;
}

- (NSImage *) imageForPreferenceNamed: (NSString *) prefName
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (void)initializeFromDefaults
{
    self.documentConfigController = [DocumentConfigController sharedController];
    self.slideshowConfigController = [SlideshowConfigController sharedController];
}

//-----------------------------------------------------------------------------------------
// 表示除外ファイル種別編集の開始＆完了応答
//-----------------------------------------------------------------------------------------
- (IBAction)onCustomizeOmittingExtentions:(id)sender
{
    _editImageSetSheet = [[EditImageSetSheetController alloc] init];
    NSArray* omittingExtentions = [DocumentConfigController sharedController].omittingExtentions;
    [_editImageSetSheet editOmittingExtentions:omittingExtentions forWindow:_preferencesView.window
                                 modalDelegate:self didEndSelector:@selector(didEndEditOmittingExtentionsSheet:)];
}

- (void)didEndEditOmittingExtentionsSheet:(id)object
{
    if (object){
        [DocumentConfigController sharedController].omittingExtentions = object;
    }
    _editImageSetSheet = nil;
}

@end
