//
//  TwoFingerGestureRecognizer.h
//  DigViewer
//
//  Created by opiopan on 2015/05/24.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TouchGestureRecognizer.h"

enum _TwoFingerGestureKind{
    TwoFingerGestureNotRecognized,
    TwoFingerMagnification,
    TwoFingerPanning,
    TwoFingerRotation
};
typedef enum _TwoFingerGestureKind TwoFingerGestureKind;

@interface TwoFingerGestureRecognizer : TouchGestureRecognizer

@property (readonly, nonatomic) TwoFingerGestureKind gestureKind;

@property (readonly, nonatomic) CGPoint initialPoint;

@property (readonly, nonatomic) CGFloat magnification;
@property (readonly, nonatomic) CGPoint panningDelta;
@property (readonly, nonatomic) CGPoint panningVelocity;
@property (readonly, nonatomic) CGFloat rotation;

@property (nonatomic) SEL magnifyGestureHandler;
@property (nonatomic) SEL panGestureHandler;
@property (nonatomic) SEL rotateGestureHandler;

@end
