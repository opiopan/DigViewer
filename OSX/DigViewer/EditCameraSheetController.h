//
//  EditCameraSheetController.h
//  DigViewer
//
//  Created by opiopan on 2015/07/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EditCameraSheetController : NSObject <NSWindowDelegate>

@property (strong) IBOutlet NSPanel *panel;
@property (weak) IBOutlet NSArrayController* inapplicableListController;
@property (weak) IBOutlet NSArrayController* applicableListController;
@property (weak) IBOutlet NSTableView *inapplicableListView;
@property (weak) IBOutlet NSTableView *applicableListView;

@property (strong) NSMutableArray* inapplicableList;
@property (strong) NSMutableArray* applicableList;
@property (assign) BOOL okButtonIsEnable;

- (IBAction)onApplicate:(id)sender;
- (IBAction)onInapplicate:(id)sender;
- (IBAction)addOrRemoveCamera:(id)sender;
- (IBAction)onOk:(id)sender;
- (IBAction)onCancel:(id)sender;

- (void) editCameraList:(NSArray*)cameras forWindow:(NSWindow*)window
                  modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
