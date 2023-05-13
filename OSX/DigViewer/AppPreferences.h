//
//  AppPreferences.h
//  DigViewer
//
//  Created by opiopan on 2015/04/11.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"

enum AppPreferenceSheet{
    AppPreferenceSheetGeneral = 0,
    AppPreferenceSheetRendering,
    AppPreferenceSheetThumbnail,
    AppPreferenceSheetSlideshow,
    AppPreferenceSheetMap,
    AppPreferenceSheetLens,
    AppPreferenceSheetDevice,
    AppPreferenceSheetAdvanced,
};

@interface AppPreferences : NSPreferences
- (void) showPreferencesPanelWithInitialSheet:(NSUInteger)sheetIndex;
@end
