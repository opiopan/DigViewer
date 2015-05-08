//
//  EditImageSetSheetController.h
//  DigViewer
//
//  Created by opiopan on 2015/05/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EditImageSetSheetController : NSObject <NSWindowDelegate>

@property (strong) IBOutlet NSPanel *panel;
@property (weak) IBOutlet NSArrayController* displayableListController;
@property (weak) IBOutlet NSArrayController* omittingListController;

@property (strong) NSMutableArray* displayableList;
@property (strong) NSMutableArray* omittingList;
@property (assign) BOOL okButtonIsEnable;

- (IBAction)onAdd:(id)sender;
- (IBAction)onRemove:(id)sender;
- (IBAction)onOk:(id)sender;
- (IBAction)onCancel:(id)sender;

- (void) editOmittingExtentions:(NSArray*)extentions forWindow:(NSWindow*)window
                  modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
