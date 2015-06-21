//
//  NSView+ViewControllerAssociation_.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "NSView+ViewControllerAssociation.h"

@implementation NSView (ViewControllerAssociation)

- (void) associateSubViewWithController:(NSViewController*)controller
{
    NSView* subView = controller.view;
    subView.frame = self.frame;
    [subView setFrameOrigin:NSZeroPoint];
    [self addSubview:subView];
}

- (BOOL) isBelongToView:(NSView*)view
{
    for (NSView* current = self; current; current = current.superview){
        if (current.superview == view){
            return YES;
        }
    }
    return NO;
}

@end
