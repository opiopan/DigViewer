//
//  SelectDeletingConditionSheetController.h
//  DigViewer
//
//  Created by opiopan on 2015/07/28.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SelectDeletingConditionSheetController : NSObject
<NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSPanel* panel;
@property (nonatomic) NSInteger deletingWay;

- (void) selectDeletingWayforWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
