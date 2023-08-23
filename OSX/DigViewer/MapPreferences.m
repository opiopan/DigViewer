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

- (NSImage *) imageForPreferenceNamed: (NSString *) prefName
{
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"map" accessibilityDescription:nil];
    } else {
        return [[NSBundle mainBundle] imageForResource:@"MapPreferences.png"];
    }
}

- (IBAction)onGetApiKey:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"https://console.developers.google.com/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
