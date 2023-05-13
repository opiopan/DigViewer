//
//  AppPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/04/11.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "AppPreferences.h"
#import "GeneralPreferences.h"
#import "RenderingPreferences.h"
#import "ThumbnailPreferences.h"
#import "SlideshowPreferences.h"
#import "MapPreferences.h"
#import "LensPreferences.h"
#import "DevicePreferences.h"
#import "AdvancedPreferences.h"

@implementation AppPreferences

- (id) init
{
    _nsBeginNSPSupport();			// MUST come before [super init]
    self = [super init];
    if (self){
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_GENERAL", nil) owner: [GeneralPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_RENDERING", nil) owner: [RenderingPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_THUMBNAIL", nil) owner: [ThumbnailPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_SLIDESHOW", nil) owner: [SlideshowPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_MAP", nil) owner: [MapPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_LENS", nil) owner: [LensPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_DEVICE", nil) owner: [DevicePreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_ADVANCED", nil) owner: [AdvancedPreferences sharedInstance]];
    }
    return self;
}

- (void) showPreferencesPanelWithInitialSheet:(NSUInteger)sheetIndex
{
    NSUserDefaultsController* config = [NSUserDefaultsController sharedUserDefaultsController];
    [config.values setValue:@(sheetIndex) forKey:@"NSPreferencesSelectedIndex"];
    [self showPreferencesPanel];
}

- (BOOL) usesButtons
{
    return NO;
}

- (void) cancel: (id) sender
{
    [_preferencesPanel close];
}

@end
