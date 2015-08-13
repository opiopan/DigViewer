//
//  InspectorArrayController.h
//  DigViewer
//
//  Created by opiopan on 2015/08/13.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InspectorArrayController : NSArrayController

- (BOOL)writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard withOnlyValue:(BOOL)writeOnlyValue;

@end
