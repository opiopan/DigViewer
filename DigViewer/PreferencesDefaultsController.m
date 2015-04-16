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
        NSDictionary* defaults = @{@"mapFovColor":          redData ,
                                   @"mapArrowColor":        redData,
                                   @"mapFovGrade":          @30,
                                   @"mapFovGradeMin":       @1,
                                   @"mapFovGradeMax":       @100,
                                   @"mapType":              @0,
                                   @"mapEnableStreetView":  @YES,
                                   @"mapMoveToHomePos":     @YES,
                                   @"dndEnable":            @YES,
                                   @"dndMultiple":          @YES};
        [[[NSUserDefaultsController sharedUserDefaultsController] defaults] registerDefaults:defaults];
    }
    return self;
}

@end
