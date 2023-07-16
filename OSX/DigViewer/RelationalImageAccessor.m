//
//  RelationalImageAccessor.m
//  DigViewer
//
//  Created by opiopan on 2015/06/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "RelationalImageAccessor.h"

@interface RelationalImage : NSObject
- (NSString*)imagePath;
- (BOOL)isPhotosLibraryImage;
- (id)nextImageNode;
- (id)previousImageNode;
@end

@implementation RelationalImage
- (NSString *)imagePath{return nil;}
- (BOOL)isPhotosLibraryImage{return NO;}
- (id)nextImageNode{return nil;}
- (id)previousImageNode{return nil;}
@end

@implementation RelationalImageAccessor{
    NSInvocation* _imagePathInvocation;
    NSInvocation* _isPhotosLibraryImageInvocation;
    NSInvocation* _nextObjectInvocation;
    NSInvocation* _previousObjectInvocation;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        RelationalImage* relationalImage = [RelationalImage new];
        NSMethodSignature* signature;

        _imagePathGetter = @selector(imagePath);
        signature = [relationalImage methodSignatureForSelector:@selector(imagePath)];
        _imagePathInvocation = [NSInvocation invocationWithMethodSignature:signature];
        _imagePathInvocation.selector = _imagePathGetter;
        
        _isPhotosLibraryImageGetter = @selector(isPhotosLibraryImage);
        signature = [relationalImage methodSignatureForSelector:@selector(isPhotosLibraryImage)];
        _isPhotosLibraryImageInvocation = [NSInvocation invocationWithMethodSignature:signature];
        _isPhotosLibraryImageInvocation.selector = _isPhotosLibraryImageGetter;
        
        _nextObjectGetter = @selector(nextImageNode);
        signature = [relationalImage methodSignatureForSelector:_nextObjectGetter];
        _nextObjectInvocation = [NSInvocation invocationWithMethodSignature:signature];
        _nextObjectInvocation.selector = _nextObjectGetter;
        
        _previousObjectGetter = @selector(previousImageNode);
        signature = [relationalImage methodSignatureForSelector:_previousObjectGetter];
        _previousObjectInvocation = [NSInvocation invocationWithMethodSignature:signature];
        _previousObjectInvocation.selector = _previousObjectGetter;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setImagePathGetter:(SEL)imagePathGetter
{
    _imagePathGetter = imagePathGetter;
    _imagePathInvocation.selector = _imagePathGetter;
}

- (void)setIsPhotosLibraryImageGetter:(SEL)isPhotosLibraryImageGetter
{
    _isPhotosLibraryImageGetter = isPhotosLibraryImageGetter;
    _isPhotosLibraryImageInvocation.selector = _isPhotosLibraryImageGetter;
}

- (void)setNextObjectGetter:(SEL)nextObjectGetter
{
    _nextObjectGetter = nextObjectGetter;
    _nextObjectInvocation.selector = _nextObjectGetter;
}

- (void)setPreviousObjectGetter:(SEL)previousObjectGetter
{
    _previousObjectGetter = previousObjectGetter;
    _previousObjectInvocation.selector = _previousObjectGetter;
}

//-----------------------------------------------------------------------------------------
// メソッド呼び出しの実装
//-----------------------------------------------------------------------------------------
- (NSString *)imagePathOfObject:(id)object
{
    return [self invokeMethodForObject:object withInvocation:_imagePathInvocation];
}

- (BOOL)isPhotosLibraryOfObject:(id)object
{
    return [self invokeBoolMethodForObject:object withInvocation:_isPhotosLibraryImageInvocation];
}

- (id)nextObjectOfObject:(id)object
{
    return [self invokeMethodForObject:object withInvocation:_nextObjectInvocation];
}

- (id)previousObjectOfObject:(id)object
{
    return [self invokeMethodForObject:object withInvocation:_previousObjectInvocation];
}

- (id)invokeMethodForObject:(id)object withInvocation:(NSInvocation*)invocation
{
    CFTypeRef rc;
    invocation.target = object;
    [invocation invoke];
    [invocation getReturnValue:&rc];
    invocation.target = nil;
    
    id robject = nil;
    if (rc){
        CFRetain(rc);
        robject = (__bridge_transfer id) rc;
    }
    
    return robject;
}

- (BOOL)invokeBoolMethodForObject:(id)object withInvocation:(NSInvocation*)invocation
{
    BOOL rc;
    invocation.target = object;
    [invocation invoke];
    [invocation getReturnValue:&rc];
    invocation.target = nil;
    return rc;
}


@end
