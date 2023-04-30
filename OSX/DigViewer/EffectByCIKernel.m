//
//  EffectByCIKernel.m
//  DigViewer
//
//  Created by opiopan on 2015/06/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "EffectByCIKernel.h"

//=========================================================================================
// フラグメントシェーダーを駆動するカスタムCIFilterの実装
//=========================================================================================
@interface FilterForTransition : CIFilter <NSCopying>
@property (nonatomic) CIImage* inputImage;
@property (nonatomic) CIImage* inputTargetImage;
@property (nonatomic) NSNumber* inputTime;
@property (nonatomic) NSNumber* scale;
- (instancetype)initWithShaderPath:(NSString*)path;
@end

@implementation FilterForTransition{
    CIKernel* _kernel;
}

- (void)setInputImage:(CIImage*) image
{
    _inputImage = image;
    NSLog(@"from image: %@", _inputImage);
}

- (void)setInputTargetImage:(CIImage *)image
{
    _inputTargetImage = image;
    NSLog(@"target image: %@", _inputImage);
}

- (void)setInputTime:(NSNumber *)value
{
    _inputTime = value;
    NSLog(@"time: %@", value);
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithShaderPath:(NSString *)path
{
    self = [self init];
    if (self){
        _scale = @1.0;
        NSError* error;
        NSString* kernelProgram = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (kernelProgram){
            _kernel = [CIKernel kernelWithString:kernelProgram];
        }
    }
    return self;
}

- (instancetype)initWithShaderName:(NSString *)name url:(NSURL*)url
{
    self = [self init];
    if (self){
        _scale = @1.0;
        NSError* error;
        NSData* metalLibrary = [NSData dataWithContentsOfURL:url];
        if (metalLibrary){
            _kernel = [CIKernel kernelWithFunctionName:name fromMetalLibraryData:metalLibrary error:&error];
        }
    }
    return self;
}


//-----------------------------------------------------------------------------------------
// コピー
//-----------------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    FilterForTransition* copy = [super copyWithZone:zone];
    if (copy){
        copy->_kernel = self->_kernel;
        copy->_inputImage = self->_inputImage;
        copy->_inputTargetImage = self->_inputTargetImage;
        copy->_inputTime = self->_inputTime;
        copy->_scale = self->_scale;
    }
    
    return copy;
}

//-----------------------------------------------------------------------------------------
// 遷移イメージ生成
//-----------------------------------------------------------------------------------------
- (CIImage *)outputImage
{
    return [self apply:_kernel, _inputImage, _inputTargetImage, _inputTime, _scale,
                       kCIApplyOptionDefinition, _inputImage.definition, nil];
}

@end

//=========================================================================================
// EffectByCIKernelの実装
//=========================================================================================
@implementation EffectByCIKernel{
    FilterForTransition* _filter;
    CIFilter* _filter2;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithShaderPath:(NSString *)path duration:(CGFloat)duration
{
    self = [self init];
    if (self){
        self.duration = duration;
        _filter = [[FilterForTransition alloc] initWithShaderPath:path];
        //_filter2 = [CIFilter filterWithName:@"CIPageCurlTransition"];
        //[_filter2 setValue:@(3.1415926 / 3) forKey:@"inputAngle"];
    }
    return self;
}

- (instancetype)initWithMetalShaderName:(NSString*)name duration:(CGFloat)duration
{
    self = [self init];
    if (self){
        self.duration = duration;
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"default" withExtension:@"metallib"];
        _filter = [[FilterForTransition alloc] initWithShaderName:name url:url];
    }
    return self;
}

- (instancetype)initWithMetalShaderLibraryURL:(NSURL*)url duration:(CGFloat)duration
{
    self = [self init];
    if (self){
        self.duration = duration;
        _filter = [[FilterForTransition alloc] initWithShaderName:@"dv_transition" url:url];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// filte返却
//-----------------------------------------------------------------------------------------
- (CIFilter *)filter
{
    return _filter2 ? _filter2 : _filter;
}

//-----------------------------------------------------------------------------------------
// レイヤー設定
//-----------------------------------------------------------------------------------------
- (void)setFromLayer:(CALayer *)fromLayer
{
    [super setFromLayer:fromLayer];
    _filter.scale = @(self.fromLayer.contentsScale);
    
}

@end
