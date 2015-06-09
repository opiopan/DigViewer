//
//  ImageFrameLayer.m
//  DigViewer
//
//  Created by opiopan on 2015/05/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageFrameLayer.h"
#import "ImageLayer.h"
#import "ImageRenderer.h"
#include "CoreFoundationHelper.h"

//-----------------------------------------------------------------------------------------
// イメージキャッシュノード
//-----------------------------------------------------------------------------------------
enum _CacheState {
    CacheFree, CacheProcessing, CacheCurrent, CacheNext, CachePrevious
};
typedef enum _CacheState CacheState;

@interface ImageCacheEntry : NSObject
@property (weak) id imageId;
@property (assign) CacheState state;
@property (strong) id image;
@property (assign) NSInteger rotation;
@property (strong) dispatch_semaphore_t semaphore;
@end

@implementation ImageCacheEntry
@end

//-----------------------------------------------------------------------------------------
// ImageFrameLayerの実装
//-----------------------------------------------------------------------------------------
@implementation ImageFrameLayer{
    NSMutableArray* _imageCache;
    dispatch_queue_t _dispatchQue;
    
    ImageCacheEntry* __weak _currentEntry;
    ImageCacheEntry* __weak _nextEntry;
    ImageCacheEntry* __weak _previousEntry;
    
    ImageLayer* _currentLayer;
    ImageLayer* _nextLayer;
    ImageLayer* _previousLayer;

    ECGColorRef _imageBackgroundColor;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
static const NSInteger CACHE_SIZE = 6;

- (instancetype)init
{
    self = [super init];
    if (self){
        _imageCache = [NSMutableArray new];
        for (NSInteger i = 0; i < CACHE_SIZE; i++){
            ImageCacheEntry* entry = [ImageCacheEntry new];
            entry.state = CacheFree;
            [_imageCache addObject:entry];
        }
        _dispatchQue = dispatch_queue_create("com.opiopan.DigViewer", DISPATCH_QUEUE_CONCURRENT);
        _currentLayer = [ImageLayer layer];
        _currentLayer.zPosition = 1;
        [self addSublayer:_currentLayer];
        _nextLayer = [ImageLayer layer];
        _nextLayer.zPosition = 0;
        [self addSublayer:_nextLayer];
        _previousLayer = [ImageLayer layer];
        _previousLayer.zPosition = 0;
        [self addSublayer:_previousLayer];
        _relationalImageAccessor = [RelationalImageAccessor new];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// イメージノード設定
//-----------------------------------------------------------------------------------------
- (void)setRelationalImage:(id)relationalImage
{
    if (_relationalImage == relationalImage){
        return;
    }
    _relationalImage = relationalImage;
    
    // キャッシュヒットテスト & LRU処理
    NSInteger index = [_imageCache indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop){
        return (BOOL)(((ImageCacheEntry*)obj).imageId == relationalImage);
    }];
    ImageCacheEntry* current = (index == NSNotFound) ? _imageCache.firstObject : _imageCache[index];
    [_imageCache removeObject:current];
    [_imageCache addObject:current];
    
    // ラスタライズ中であれば完了まで待つ
    if (current.state == CacheProcessing){
        dispatch_semaphore_wait(current.semaphore, DISPATCH_TIME_FOREVER);
    }

    // レイヤーの役割交換 or ラスタライズ
    ImageLayer* oldLayer = nil;
    if (current == _nextEntry){
        oldLayer = _currentLayer;
        _currentLayer = _nextLayer;
        _nextLayer = oldLayer;
        _nextEntry = _currentEntry;
        _nextEntry.state = CacheNext;
        [self applyAttributesForLayer:_currentLayer];
    }else if (current == _previousEntry){
        oldLayer = _currentLayer;
        _currentLayer = _previousLayer;
        _previousLayer = oldLayer;
        _previousEntry = _currentEntry;
        _previousEntry.state = CachePrevious;
        [self applyAttributesForLayer:_currentLayer];
    }else{
        if (index == NSNotFound){
            current.imageId = _relationalImage;
            if (_relationalImage){
                ImageRenderer* renderer;
                renderer = [ImageRenderer imageRendererWithPath:[_relationalImageAccessor imagePathOfObject:_relationalImage]];
                current.image =  renderer.image;
                current.rotation = renderer.rotation;
            }else{
                current.image = nil;
                current.rotation = 1;
            }
        }
        [_currentLayer setImage:current.image withRotation:current.rotation];
    }
    current.state = CacheCurrent;
    _currentEntry = current;
    
    // 表示切り替え
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if (oldLayer){
        oldLayer.zPosition = 0;
    }
    _currentLayer.zPosition = 1;
    [CATransaction commit];
    
    // 投機的キャッシング
    [self performSelector:@selector(fillCacheSpeculatively) withObject:nil afterDelay:0];
}

//-----------------------------------------------------------------------------------------
// 投機的キャッシング
//-----------------------------------------------------------------------------------------
- (void)fillCacheSpeculatively
{
    RelationalImageAccessor* accessor = _relationalImageAccessor;
    
    // 次の画像をキャッシュに充填
    id nextNode = [accessor nextObjectOfObject:_relationalImage];
    NSUInteger index = [_imageCache indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop){
        return (BOOL)(((ImageCacheEntry*)obj).imageId == nextNode);
    }];
    ImageCacheEntry* next = index == NSNotFound ? _imageCache.firstObject : _imageCache[index];
    [_imageCache removeObject:next];
    [_imageCache addObject:next];
    if (next.state == CacheProcessing){
        dispatch_semaphore_wait(next.semaphore, DISPATCH_TIME_FOREVER);
    }
    if (next == _nextEntry){
        // nothing to do
    }else if (next == _previousEntry){
        ImageLayer* tmp = _previousLayer;
        _previousLayer = _nextLayer;
        _nextLayer = tmp;
        _previousEntry = _nextEntry;
        _previousEntry.state = CachePrevious;
        _nextEntry = next;
        _nextEntry.state = CacheNext;
    }else{
        _nextEntry = next;
        next.imageId = nextNode;
        next.state = CacheProcessing;
        next.semaphore = dispatch_semaphore_create(0);
        
        ImageLayer* layer = _nextLayer;
        [layer setImage:nil withRotation:1];
        
        dispatch_async(_dispatchQue, ^(){
            if (index == NSNotFound){
                ImageRenderer* renderer;
                renderer = [ImageRenderer imageRendererWithPath:[accessor imagePathOfObject:nextNode]];
                next.image = renderer.image;
                next.rotation = renderer.rotation;
            }
            [layer setImage:next.image withRotation:next.rotation];
            next.state = CacheNext;
            dispatch_semaphore_signal(next.semaphore);
        });
    }

    // 前の画像をキャッシュに充填
    id previousNode = [accessor previousObjectOfObject:_relationalImage];
    index = [_imageCache indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop){
        return (BOOL)(((ImageCacheEntry*)obj).imageId == previousNode);
    }];
    ImageCacheEntry* previous = index == NSNotFound ? _imageCache.firstObject : _imageCache[index];
    [_imageCache removeObject:previous];
    [_imageCache addObject:previous];
    if (previous.state == CacheProcessing){
        dispatch_semaphore_wait(previous.semaphore, DISPATCH_TIME_FOREVER);
    }
    if (previous == _previousEntry){
        // nothing to do
    }else if (previous == _nextEntry){
        ImageLayer* tmp = _nextLayer;
        _nextLayer = _previousLayer;
        _previousLayer = tmp;
        _nextEntry = _previousEntry;
        _nextEntry.state = CacheNext;
        _previousEntry = previous;
        _previousEntry.state = CachePrevious;
    }else{
        _previousEntry = previous;
        previous.imageId = previousNode;
        previous.state = CacheProcessing;
        previous.semaphore = dispatch_semaphore_create(0);
        
        ImageLayer* layer = _previousLayer;
        [layer setImage:nil withRotation:1];
        
        dispatch_async(_dispatchQue, ^(){
            if (index == NSNotFound){
                ImageRenderer* renderer;
                renderer = [ImageRenderer imageRendererWithPath:[accessor imagePathOfObject:previousNode]];
                previous.image = renderer.image;
                previous.rotation = renderer.rotation;
            }
            [layer setImage:previous.image withRotation:previous.rotation];
            previous.state = CachePrevious;
            dispatch_semaphore_signal(previous.semaphore);
        });
    }
}

//-----------------------------------------------------------------------------------------
// イメージレイヤの属性反映
//-----------------------------------------------------------------------------------------
- (void)applyAttributesForLayer:(ImageLayer*)layer
{
    layer.frame = self.frame;
    if (layer.magnificationFilter != self.magnificationFilter){
        layer.magnificationFilter = self.magnificationFilter;
    }
    if (layer.minificationFilter != self.minificationFilter){
        layer.minificationFilter = self.minificationFilter;
    }
    if (layer.isFitFrame != _isFitFrame){
        layer.isFitFrame = _isFitFrame;
    }
    if (layer.backgroundColor != _imageBackgroundColor){
        layer.backgroundColor = _imageBackgroundColor;
    }
    if (layer.scale != 1.0){
        layer.scale = 1.0;
    }
}


//-----------------------------------------------------------------------------------------
// フレームサイズ変更
//-----------------------------------------------------------------------------------------
- (void)setFrame:(CGRect)frame
{
    if (_currentEntry){
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [super setFrame:frame];
        [_currentLayer setFrame:frame];
        [CATransaction commit];
    }
}

//-----------------------------------------------------------------------------------------
// カレントイメージレイヤへのルーティング
//-----------------------------------------------------------------------------------------
- (void)setIsFitFrame:(BOOL)isFitFrame
{
    _isFitFrame = isFitFrame;
    _currentLayer.isFitFrame = _isFitFrame;
}

- (void)setBackgroundColor:(CGColorRef)backgroundColor
{
    if (backgroundColor){
        CFRetain(backgroundColor);
    }
    _imageBackgroundColor = backgroundColor;
    _currentLayer.backgroundColor = backgroundColor;
}

- (CGFloat)scale
{
    return _currentLayer.scale;
}

- (void)setScale:(CGFloat)scale
{
    _currentLayer.scale = scale;
}

- (CGFloat)transisionalScale
{
    return _currentLayer.transisionalScale;
}

- (void)setTransisionalScale:(CGFloat)transisionalScale withOffset:(CGPoint)offset
{
    [_currentLayer setTransisionalScale:transisionalScale withOffset:offset];
}

- (void)fixScale
{
    [_currentLayer fixScale];
}

- (CGPoint)startPanning
{
    return [_currentLayer startPanning];
}

- (CGPoint)transisionalOffset
{
    return [_currentLayer transisionalOffset];
}

- (void)setTransisionalOffset:(CGPoint)offset
{
    [_currentLayer setTransisionalOffset:offset];
}

- (void)fixOffsetWithVelocity:(CGPoint)velocity
{
    [_currentLayer fixOffsetWithVelocity:velocity];
}

- (CGPoint)offset
{
    return _currentLayer.offset;
}

- (void)setOffset:(CGPoint)offset
{
    _currentLayer.offset = offset;
}

//-----------------------------------------------------------------------------------------
// 拡大・縮小フィルター
//-----------------------------------------------------------------------------------------
- (void)setMagnificationFilter:(NSString *)magnificationFilter
{
    super.magnificationFilter = magnificationFilter;
    _currentLayer.magnificationFilter = magnificationFilter;
}

- (void)setMinificationFilter:(NSString *)minificationFilter
{
    super.minificationFilter = minificationFilter;
    _currentLayer.minificationFilter = minificationFilter;
}

@end
