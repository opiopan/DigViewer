//
//  LensPreferences.h
//  DigViewer
//
//  Created by opiopan on 2015/04/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferencesModule.h"

@interface LensPreferences : NSPreferencesModule

@property (strong) IBOutlet NSArrayController *lensArrayController;
@property (weak) IBOutlet NSTableView *lensProfileTableView;

- (IBAction)addOrRemoveLens:(id)sender;

@end
