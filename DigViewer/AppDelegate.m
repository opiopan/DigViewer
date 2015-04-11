//
//  AppDelegate.m
//  DigViewer
//
//  Created by opiopan on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "AppDelegate.h"
#import "AppPreferences.h"

@implementation AppDelegate

- (IBAction)showPreferences:(id)sender
{
    [NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
    [[NSPreferences sharedPreferences] showPreferencesPanel];
}

- (IBAction)showMapPreferences:(id)sender
{
    [NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
    [[NSPreferences sharedPreferences] showPreferencesPanel];
}

@end
