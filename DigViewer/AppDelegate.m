//
//  AppDelegate.m
//  DigViewer
//
//  Created by opiopan on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "AppDelegate.h"
#import "AppPreferences.h"
#import "TemporaryFileController.h"
#import "Document.h"
#import "DocumentWindowController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    DVRemoteServer* server = [DVRemoteServer sharedServer];
    server.delegate = self;
    [server establishServer];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[TemporaryFileController sharedController] cleanUpAllCategories];
    return NSTerminateNow;
}

- (IBAction)showPreferences:(id)sender
{
    [NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
    [[NSPreferences sharedPreferences] showPreferencesPanel];
}

- (IBAction)showMapPreferences:(id)sender
{
    [NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
    [[NSPreferences sharedPreferences] showPreferencesPanel];
}

- (IBAction)openFolder:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    if ([openPanel runModal] == NSFileHandlingPanelOKButton){
        NSDocumentController* controller = [NSDocumentController sharedDocumentController];
        [controller openDocumentWithContentsOfURL:openPanel.URL display:YES
                                completionHandler:^(NSDocument* document, BOOL alreadyOpened, NSError* error){}];
    }
}

//-----------------------------------------------------------------------------------------
// DVRemoteServerDelegateプロトコルの実装
//-----------------------------------------------------------------------------------------
- (void)dvrServer:(DVRemoteServer *)server needMoveToNeighborImageOfDocument:(NSString *)documentName
    withDirection:(DVRCommand)direction
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        for (NSWindowController* windowController in document.windowControllers){
            if ([windowController.class isSubclassOfClass:[DocumentWindowController class]]){
                if (direction == DVRC_MOVE_NEXT_IMAGE){
                    [((DocumentWindowController*)windowController) moveToNextImage:self];
                }else{
                    [((DocumentWindowController*)windowController) moveToPreviousImage:self];
                }
            }
        }
    }
}

- (void)dvrServer:(DVRemoteServer *)server needSendThumbnails:(NSArray *)ids forDocument:(NSString *)documentName
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        [document sendThumbnails:ids];
    }
}

- (void)dvrServer:(DVRemoteServer *)server needSendFullimage:(NSArray *)nodeId
      forDocument:(NSString *)documentName withSize:(CGFloat)maxSize
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        [document sendFullImage:nodeId withSize:maxSize];
    }
}

@end
