//
//  LoadingSheetController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/09.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PathfinderPinnedFile.h"

@interface LoadingSheetController : NSObject <NSWindowDelegate>

@property (strong) NSString* phase;
@property (assign) BOOL isIndeterminate;
@property (strong) NSNumber* progress;
@property (strong) IBOutlet NSPanel *panel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (void) loadPath:(NSString*)path forWindow:(NSWindow*)window
          modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
