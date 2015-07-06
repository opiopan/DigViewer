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
    long _countToFinish;
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
// 遷移環境準備 （初回のグリッジを避けるための暖機運転）
//-----------------------------------------------------------------------------------------
- (void)prepareTransitionOnLayer:(CALayer *)layer
{

    CGImageRef image = [self CGImageFromLayer:layer];

    [layer addSublayer:_qcLayer];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _qcLayer.frame = self.fromLayer.frame;
    _qcLayer.zPosition = -10;
    _qcLayer.hidden = NO;
    _qcLayer.opacity = 1.0;
    [_qcLayer setValue:(__bridge id)image forInputKey:kInputSourceImage];
    [_qcLayer setValue:(__bridge id)image forInputKey:kInputDestinationImage];
    [_qcLayer setValue:@1 forInputKey:kInputStart];
    [_qcLayer setValue:@0 forInputKey:kInputReset];
    [CATransaction commit];
}

//-----------------------------------------------------------------------------------------
// 遷移処理
//-----------------------------------------------------------------------------------------
- (void)performTransition
{
    if (_qcLayer.superlayer){
        [self cleanUpTransition];
    }
    
    _qcLayer.contentsScale = self.fromLayer.contentsScale;
    [self.fromLayer.superlayer addSublayer:_qcLayer];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.toLayer.hidden = NO;
    [CATransaction commit];

    CGImageRef fromImage = [self CGImageFromLayer:self.fromLayer];
    CGImageRef toImage = [self CGImageFromLayer:self.toLayer];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _qcLayer.frame = self.fromLayer.frame;
    _qcLayer.zPosition = 0.0;
    _qcLayer.hidden = NO;
    _qcLayer.opacity = 1.0;
    [_qcLayer setValue:(__bridge id)fromImage forInputKey:kInputSourceImage];
    [_qcLayer setValue:(__bridge id)toImage forInputKey:kInputDestinationImage];
    [_qcLayer setValue:@0 forInputKey:kInputStart];
    [_qcLayer setValue:@1 forInputKey:kInputReset];
    [CATransaction commit];

    [self performSelector:@selector(startTransition) withObject:nil afterDelay:0.4];
}

- (void)startTransition
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _qcLayer.zPosition = 1.0;
    _qcLayer.opacity = 1.0;
    [_qcLayer setValue:@1 forInputKey:kInputStart];
    [_qcLayer setValue:@0 forInputKey:kInputReset];
    [CATransaction commit];

    _countToFinish = 0;
    
    [self performSelector:@selector(endTransition) withObject:nil afterDelay:self.duration];
}

- (void)endTransition
{
    if ([[_qcLayer valueForOutputKey:kOutputEnd] boolValue] || _countToFinish > 10){
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        _qcLayer.hidden = YES;
        self.fromLayer.hidden = YES;
        self.toLayer.hidden = NO;
        [CATransaction commit];
        
        [self performSelector:@selector(postEndTransition) withObject:nil afterDelay:0.1];
    }else{
        _countToFinish++;
        [self performSelector:@selector(endTransition) withObject:nil afterDelay:0.1];
    }
}

- (void)postEndTransition
{
    [self cleanUpTransition];
    [self invokeDelegateWhenDidEnd];
}

//-----------------------------------------------------------------------------------------
// 遷移間環境のクリーンアップ
//-----------------------------------------------------------------------------------------
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

    if (_qcLayer.superlayer){
        [_qcLayer removeFromSuperlayer];
    }
}

@end
