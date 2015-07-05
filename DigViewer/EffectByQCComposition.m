//
//  EffectByQCComposition.m
//  DigViewer
//
//  Created by opiopan on 2015/07/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EffectByQCComposition.h"
#import <Quartz/Quartz.h>

static NSString* kInputBackgroundColor = @"inputBackgroundColor";
static NSString* kInputSourceImage = @"inputSourceImage";
static NSString* kInputDestinationImage = @"inputDestinationImage";
static NSString* kInputStart = @"inputStart";
static NSString* kInputReset = @"inputReset";
static NSString* kInputDuration = @"inputDuration";
static NSString* kOutputEnd = @"outputEnd";

@implementation EffectByQCComposition{
    QCCompositionLayer* _qcLayer;
}

//-----------------------------------------------------------------------------------------
// コンポジションファイルのバリデーション
//-----------------------------------------------------------------------------------------
+ (BOOL)validateFile:(NSString *)path
{
    QCComposition* composition = [QCComposition compositionWithFile:path];
    NSArray* inputs = [composition inputKeys];
    NSArray* outputs = [composition outputKeys];
    return [inputs indexOfObject:kInputBackgroundColor] != NSNotFound &&
           [inputs indexOfObject:kInputSourceImage] != NSNotFound &&
           [inputs indexOfObject:kInputDestinationImage] != NSNotFound &&
           [inputs indexOfObject:kInputStart] != NSNotFound &&
           [inputs indexOfObject:kInputReset] != NSNotFound &&
           [inputs indexOfObject:kInputDuration] != NSNotFound &&
           [outputs indexOfObject:kOutputEnd] != NSNotFound;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithShaderPath:(NSString *)path duration:(CGFloat)duration
{
    self = [self init];
    if (self){
        self.duration = duration;
        _qcLayer = [QCCompositionLayer compositionLayerWithFile:path];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [_qcLayer setValue:@(duration) forInputKey:kInputDuration];
        [_qcLayer setValue:(__bridge id)[[NSColor blackColor] CGColor] forInputKey:kInputBackgroundColor];
        [_qcLayer setValue:@0 forInputKey:kInputStart];
        [_qcLayer setValue:@0 forInputKey:kInputReset];
        [CATransaction commit];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 遷移処理
//-----------------------------------------------------------------------------------------
- (void)performTransition
{
    _qcLayer.contentsScale = self.fromLayer.contentsScale;
    [self.fromLayer.superlayer addSublayer:_qcLayer];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _qcLayer.frame = self.fromLayer.frame;
    _qcLayer.zPosition = 10.0;
    _qcLayer.hidden = NO;
    _qcLayer.opacity = 0.0;
    [_qcLayer setValue:self.fromImage forInputKey:kInputSourceImage];
    [_qcLayer setValue:self.toImage forInputKey:kInputDestinationImage];
    [_qcLayer setValue:@0 forInputKey:kInputStart];
    [_qcLayer setValue:@1 forInputKey:kInputReset];
    [CATransaction commit];
    
    [self performSelector:@selector(startTransition) withObject:nil afterDelay:0.3];
}

- (void)startTransition
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _qcLayer.opacity = 1.0;
    [_qcLayer setValue:@1 forInputKey:kInputStart];
    [_qcLayer setValue:@0 forInputKey:kInputReset];
    [CATransaction commit];

    [self performSelector:@selector(endTransition) withObject:nil afterDelay:self.duration];
}

- (void)endTransition
{
    if ([[_qcLayer valueForOutputKey:kOutputEnd] boolValue]){
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        _qcLayer.hidden = YES;
        self.fromLayer.hidden = YES;
        self.toLayer.hidden = NO;
        [CATransaction commit];
        
        [self performSelector:@selector(cleanUpTransition) withObject:nil afterDelay:0.1];
    }else{
        [self performSelector:@selector(endTransition) withObject:nil afterDelay:0.1];
    }
}

- (void)cleanUpTransition
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _qcLayer.hidden = YES;
    [_qcLayer setValue:nil forInputKey:kInputSourceImage];
    [_qcLayer setValue:nil forInputKey:kInputDestinationImage];
    [_qcLayer setValue:@0 forInputKey:kInputStart];
    [_qcLayer setValue:@1 forInputKey:kInputReset];
    [CATransaction commit];
    
    [_qcLayer removeFromSuperlayer];
    
    [self invokeDelegateWhenDidEnd];
}

@end
