//
//  FocusCatchableTextField.m
//  DigViewer
//
//  Created by opiopan on 2015/06/22.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "FocusCatchableTextField.h"

@implementation FocusCatchableTextField

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (BOOL)becomeFirstResponder
{
    if (self.delegate && self.notifyFocusChangeSelector){
        [self.delegate performSelector:self.notifyFocusChangeSelector withObject:self];
    }
    return [super becomeFirstResponder];
}

/*
- (BOOL)resignFirstResponder
{
    if (self.delegate && self.notifyFocusChangeSelector){
        [self.delegate performSelector:self.notifyFocusChangeSelector withObject:self];
    }
    return [super resignFirstResponder];
}
 */

#pragma clang diagnostic pop

@end
