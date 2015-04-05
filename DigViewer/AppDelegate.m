//
//  AppDelegate.m
//  DigViewer
//
//  Created by opiopan on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (IBAction)onGetApiKey:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"https://console.developers.google.com/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)showPreferences
{
    [self.preferencesWindow makeKeyAndOrderFront:self];
}

@end
