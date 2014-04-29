//
//  PreferencesDefaultsController.m
//  DigViewer
//
//  Created by opiopan on 2014/04/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "PreferencesDefaultsController.h"

@implementation PreferencesDefaultsController

- (id)init
{
    self = [super init];
    if (self){
        NSData* redData = [NSArchiver archivedDataWithRootObject:[NSColor redColor]];
        NSDictionary* defaults = @{@"mapFovColor":redData , @"mapArrowColor":redData};
        [[[NSUserDefaultsController sharedUserDefaultsController] defaults] registerDefaults:defaults];
    }
    return self;
}

@end
