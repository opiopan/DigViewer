//
//  InspectorViewController.h
//  DigViewer
//
//  Created by opiopan on 2014/02/16.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InspectorViewController : NSViewController

@property (weak) IBOutlet NSArrayController* imageArrayController;
@property (weak) IBOutlet NSTableColumn* keyColumn;
@property (strong) NSArray* summary;

@end
