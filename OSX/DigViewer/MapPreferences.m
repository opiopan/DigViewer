//
//  MapPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/04/11.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "MapPreferences.h"

@implementation MapPreferences

- (BOOL) isResizable
{
    return NO;
}

- (IBAction)onGetApiKey:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"https://console.developers.google.com/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
