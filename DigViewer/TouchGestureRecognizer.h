//
//  TouchGestureRecognizer.h
//  DigViewer
//
//  Created by opiopan on 2015/05/24.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum _TouchGestureState {
    TouchGestureStateNone = 0,
    TouchGestureStateBegan,
    TouchGestureStateChanged,
    TouchGestureStateEnded,
    TouchGestureStateCanceled,
    TouchGestureStateFailed
};
typedef enum _TouchGestureState TouchGestureState;

@interface TouchGestureRecognizer : NSResponder

@property (weak, nonatomic) NSView* view;
@property (nonatomic) TouchGestureState state;
@property (nonatomic) BOOL isEnabled;
@property (nonatomic) NSEventModifierFlags modifiers;

- (void)cancelGesture;

@end
