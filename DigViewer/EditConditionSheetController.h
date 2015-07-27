//
//  EditConditionSheetController.h
//  DigViewer
//
//  Created by opiopan on 2015/07/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LensLibrary.h"

@interface EditConditionSheetController : NSObject <NSWindowDelegate>

@property (strong) IBOutlet NSPanel *panel;
@property (weak) IBOutlet NSTreeController* conditionTreeController;
@property (weak) IBOutlet NSOutlineView* conditionTreeView;
@property (weak) IBOutlet NSTabView* propertiesTabView;

@property (readonly, nonatomic) Condition* condition;
@property (nonatomic) NSArray* selectionIndexesInCondition;
@property (nonatomic) NSInteger groupingConditon;
@property (nonatomic) NSString* targetName;
@property (readonly, nonatomic) NSArray* operators;
@property (nonatomic) NSInteger selectedIndexInOperators;
@property (nonatomic) NSString* comparisonValue;
@property (assign) BOOL okButtonIsEnable;
@property (assign) BOOL addButtonIsEnable;
@property (assign) BOOL removeButtonIsEnable;
@property (assign) BOOL embedButtonIsEnable;

- (IBAction)addCondition:(id)sender;
- (IBAction)removeCondition:(id)sender;
- (IBAction)embedInNewGroup:(id)sender;
- (IBAction)onOk:(id)sender;
- (IBAction)onCancel:(id)sender;

- (void) editCondition:(Condition*)condition forWindow:(NSWindow*)window
          modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
