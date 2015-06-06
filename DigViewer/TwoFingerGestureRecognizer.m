//
//  TwoFingerGestureRecognizer.m
//  DigViewer
//
//  Created by opiopan on 2015/05/24.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "TwoFingerGestureRecognizer.h"

//-----------------------------------------------------------------------------------------
// ジオメトリ計算部品
//-----------------------------------------------------------------------------------------
static inline CGPoint vecDelta(CGPoint point1, CGPoint point2)
{
    CGPoint rc;
    rc.x = point1.x - point2.x;
    rc.y = point1.y - point2.y;
    return rc;
}

static inline CGPoint vecMagnify(CGPoint point, CGFloat scale)
{
    CGPoint rc;
    rc.x = point.x * scale;
    rc.y = point.y * scale;
    return rc;
}

static inline CGPoint vecDisnormalize(CGPoint point, NSSize size)
{
    CGPoint rc;
    rc.x = point.x * size.width;
    rc.y = point.y * size.height;
    return rc;
}

static inline CGPoint touchCOG(NSTouch* touch1, NSTouch* touch2)
{
    CGPoint rc;
    rc.x = (touch1.normalizedPosition.x + touch2.normalizedPosition.x) / 2;
    rc.y = (touch1.normalizedPosition.y + touch2.normalizedPosition.y) / 2;
    return rc;
}

static inline CGFloat touchDistance(NSTouch* touch1, NSTouch*touch2)
{
    CGFloat x = touch1.normalizedPosition.x - touch2.normalizedPosition.x;
    CGFloat y = touch1.normalizedPosition.y - touch2.normalizedPosition.y;
    return sqrt(x * x + y * y);
}

//-----------------------------------------------------------------------------------------
// TwoFingerGestureRecognizerの実装
//-----------------------------------------------------------------------------------------
@implementation TwoFingerGestureRecognizer{
    CGFloat _initialDistance;
    NSTouch *_initialTouches[2];
    NSTouch *_currentTouches[2];
    NSTouch *_lastTouches[2];
    NSTimeInterval _currentTimestamp;
    NSTimeInterval _lastTimestamp;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _gestureKind = TwoFingerGestureNotRecognized;
    }
    return self;
}


//-----------------------------------------------------------------------------------------
// タッチイベントの処理
//-----------------------------------------------------------------------------------------
- (void)touchesBeganWithEvent:(NSEvent *)event
{
    if (!self.isEnabled) return;

    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self.view];
    
    if (touches.count == 2){
        self.modifiers = event.modifierFlags;
        
        NSArray *array = [touches allObjects];
        _initialTouches[0] = array[0];
        _initialTouches[1] = array[1];
        _lastTouches[0] = _currentTouches[0] = _initialTouches[0];
        _lastTouches[1] = _currentTouches[1] = _initialTouches[1];

        _initialPoint.x = event.locationInWindow.x - self.view.frame.origin.x;
        _initialPoint.y = event.locationInWindow.y - self.view.frame.origin.y;
        _initialDistance = touchDistance(_initialTouches[0], _initialTouches[1]);
        
        _currentTimestamp = _lastTimestamp = event.timestamp;
        
        self.state = TouchGestureStateBegan;
        _gestureKind = TwoFingerGestureNotRecognized;

        [self invokeHandler];
    }else{
        [self cancelGesture];
    }
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
    if (!self.isEnabled || self.state == TouchGestureStateNone) return;
    
    self.modifiers = [event modifierFlags];
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self.view];
    
    if (touches.count == 2 && _initialTouches[0]) {
        _lastTouches[0] = _currentTouches[0];
        _lastTouches[1] = _currentTouches[1];
        _lastTimestamp = _currentTimestamp;
        _currentTimestamp = event.timestamp;
        
        NSArray *array = [touches allObjects];
        NSTouch *touch = array[0];
        if ([touch.identity isEqual:_initialTouches[0].identity]) {
            _currentTouches[0] = touch;
        } else {
            _currentTouches[1] = touch;
        }
        
        touch = [array objectAtIndex:1];
        if ([touch.identity isEqual:_initialTouches[0].identity]) {
            _currentTouches[0] = touch;
        } else {
            _currentTouches[1] = touch;
        }
        
        switch (_gestureKind){
            case TwoFingerGestureNotRecognized:
                [self updateGestureInNotRecognized];
                break;
            case TwoFingerPanning:
                [self updateGestureInPanning];
                break;
            case TwoFingerMagnification:
                [self updateGestureInMagnification];
                break;
            case TwoFingerRotation:
                [self updateGestureInRotation];
        }
    }
}

- (void)touchesEndedWithEvent:(NSEvent *)event
{
    if (!self.isEnabled || self.state == TouchGestureStateNone) return;
    
    self.state = TouchGestureStateEnded;
    self.modifiers = [event modifierFlags];
    [self cancelGesture];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event
{
    [self cancelGesture];
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    if (_gestureKind != TwoFingerMagnification && self.state != TouchGestureStateNone){
        self.state = TouchGestureStateChanged;
        _gestureKind = TwoFingerMagnification;
        [self invokeHandler];
    }
}

//-----------------------------------------------------------------------------------------
// ジェスチャー更新：ジェスチャー未確定時
//-----------------------------------------------------------------------------------------
- (void)updateGestureInNotRecognized
{
    static const CGFloat panThreshold = 1;
    
    CGPoint COGDelta = [self COGDelta];
    CGFloat COGDeltaX = fabs(COGDelta.x);
    CGFloat COGDeltaY = fabs(COGDelta.y);

    if (COGDeltaX >= panThreshold || COGDeltaY >= panThreshold){
        self.state = TouchGestureStateChanged;
        _gestureKind = TwoFingerPanning;
        [self updateGestureInPanning];
    }
}

//-----------------------------------------------------------------------------------------
// ジェスチャー更新：Magnify
//-----------------------------------------------------------------------------------------
- (void)updateGestureInMagnification
{
    _magnification = touchDistance(_currentTouches[0], _currentTouches[1]) - _initialDistance;
    [self invokeHandler];
}

//-----------------------------------------------------------------------------------------
// ジェスチャー更新：Pan
//-----------------------------------------------------------------------------------------
- (void)updateGestureInPanning
{
    _panningDelta = [self COGDelta];
    _panningVelocity = [self COGVelocity];
    [self invokeHandler];
}

//-----------------------------------------------------------------------------------------
// ジェスチャー更新：rotate
//-----------------------------------------------------------------------------------------
- (void)updateGestureInRotation
{
}

//-----------------------------------------------------------------------------------------
// ジェスチャーキャンセル
//-----------------------------------------------------------------------------------------
- (void)cancelGesture
{
    if (self.state != TouchGestureStateNone){
        if (self.state != TouchGestureStateEnded){
            self.state = TouchGestureStateCanceled;
        }
        
        [self invokeHandler];
        
        self.state = TouchGestureStateNone;
        _gestureKind = TwoFingerGestureNotRecognized;
        self.modifiers = 0;
        _panningDelta = CGPointZero;
        _panningVelocity = CGPointZero;
        _magnification = 0;
        _rotation = 0;
        _initialTouches[0] = _initialTouches[1] = nil;
        _currentTouches[0] = _currentTouches[1] = nil;
        _lastTouches[0] = _lastTouches[1] = nil;
    }
}

//-----------------------------------------------------------------------------------------
// ハンドラー呼び出し
//-----------------------------------------------------------------------------------------
- (void)invokeHandler
{
    switch (_gestureKind){
        case TwoFingerGestureNotRecognized:
        case TwoFingerPanning:
            if (_panGestureHandler){
                [NSApp sendAction:_panGestureHandler to:self.view from:self];
            }
            break;
        case TwoFingerMagnification:
            if (_magnifyGestureHandler){
                [NSApp sendAction:_magnifyGestureHandler to:self.view from:self];
            }
            break;
        case TwoFingerRotation:
            if (_rotateGestureHandler){
                [NSApp sendAction:_rotateGestureHandler to:self.view from:self];
            }
    }
}

//-----------------------------------------------------------------------------------------
// ジオメトリ計算
//-----------------------------------------------------------------------------------------
-(CGPoint)COGDelta
{
    if (!(_initialTouches[0] && _initialTouches[1] && _currentTouches[0] && _currentTouches[1])){
        return CGPointZero;
    }
    
    CGPoint rc;
    rc = vecDelta(touchCOG(_currentTouches[0], _currentTouches[1]), touchCOG(_initialTouches[0], _initialTouches[1]));
    
    return vecDisnormalize(rc, _initialTouches[0].deviceSize);
}

-(CGPoint)COGVelocity
{
    if (!(_currentTouches[0] && _currentTouches[1]) && _lastTouches[0] && _lastTouches[1]){
        return CGPointZero;
    }
    
    CGPoint rc;
    rc = vecDelta(touchCOG(_currentTouches[0], _currentTouches[1]), touchCOG(_lastTouches[0], _lastTouches[1]));
    rc = vecMagnify(rc, 1.0 / (_currentTimestamp - _lastTimestamp));
    
    return vecDisnormalize(rc, _initialTouches[0].deviceSize);
}

@end
