//
//  AppDelegate.h
//  DigViewer
//
//  Created by opiopan on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *preferencesWindow;

- (IBAction)onGetApiKey:(id)sender;

- (void)showPreferences;

@end
