//
//  AppDelegate.h
//  DigViewer
//
//  Created by opiopan on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteServer.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, DVRemoteServerDelegate>

- (IBAction)showPreferences:(id)sender;

- (IBAction)showMapPreferences:(id)sender;

@end
