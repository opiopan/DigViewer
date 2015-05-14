//
//  AdvancedPreferences.h
//  DigViewer
//
//  Created by opiopan on 4/12/15.
//  Copyright (c) 2015 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferencesModule.h"

@interface AdvancedPreferences : NSPreferencesModule

@property (assign, nonatomic) NSInteger sortType;
@property (assign, nonatomic) BOOL isCaseInsensitive;
@property (assign, nonatomic) BOOL isSortAsNumeric;

@property (strong, nonatomic) NSArray* exampleList;

@end
