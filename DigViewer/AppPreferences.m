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
        //[self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_SLIDESHOW", nil) owner: [SlideshowPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_MAP", nil) owner: [MapPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_LENS", nil) owner: [LensPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_ADVANCED", nil) owner: [AdvancedPreferences sharedInstance]];
    }
    return self;
}

- (BOOL) usesButtons
{
    return NO;
}

@end
