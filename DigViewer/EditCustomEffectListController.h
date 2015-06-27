//
//  EditCustomEffectListController.h
//  DigViewer
//
//  Created by opiopan on 2015/06/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EditCustomEffectListController : NSObject <NSWindowDelegate>

@property (strong) IBOutlet NSPanel *panel;
@property (strong) IBOutlet NSArrayController *effectsArrayController;
@property (weak) IBOutlet NSTableView *effectsTableView;

@property (readonly, nonatomic) NSArray* effects;
@property (nonatomic) BOOL isChanged;

- (void) editEffectList:(NSArray*)effects forWindow:(NSWindow*)window modalDelegate:(id)delegate
         didEndSelector:(SEL)didEndSelector;

@end
