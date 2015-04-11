//
//  AppPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/04/11.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "AppPreferences.h"
#import "GeneralPreferences.h"
#import "MapPreferences.h"

@implementation AppPreferences

- (id) init
{
    _nsBeginNSPSupport();			// MUST come before [super init]
    self = [super init];
    if (self){
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_GENERAL", nil) owner: [GeneralPreferences sharedInstance]];
        [self addPreferenceNamed: NSLocalizedString(@"PREF_TITLE_MAP", nil) owner: [MapPreferences sharedInstance]];
    }
    return self;
}

- (BOOL) usesButtons
{
    return NO;
}

@end
