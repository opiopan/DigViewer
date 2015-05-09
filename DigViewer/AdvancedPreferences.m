//
//  AdvancedPreferences.m
//  DigViewer
//
//  Created by opiopan on 4/12/15.
//  Copyright (c) 2015 opiopan. All rights reserved.
//

#import "AdvancedPreferences.h"
#import "PathNode.h"

@implementation AdvancedPreferences

//-----------------------------------------------------------------------------------------
// シートアピアランス指定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

- (NSImage *) imageForPreferenceNamed: (NSString *) prefName
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

@end
