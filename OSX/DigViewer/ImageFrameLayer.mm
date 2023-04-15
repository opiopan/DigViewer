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
#include <sys/time.h>

//-----------------------------------------------------------------------------------------
// μs精度通算秒
//-----------------------------------------------------------------------------------------
static inline NSTimeInterval nowInEpocTime(){
    struct timeval timeval;
    gettimeofday(&timeval, NULL);
    return (double)timeval.tv_sec + (double)timeval.tv_usec / 1000000.0;
}

//-----------------------------------------------------------------------------------------
// イメージキャッシュノード
//-----------------------------------------------------------------------------------------
enum _CacheState {
    CacheFree, CacheStandBy, CacheProcessing, CacheVarid
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
enum _SwipeInertiaState {SwipeInertiaEnd, SwipeInertiaInrange, SwipeInertiaOutrange, SwipeInertiaCompensate};
typedef enum _SwipeInertiaState SwipeInertiaState;
@implementation ImageFrameLayer{
    NSMutableArray* _imageCache;
    dispatch_queue_t _dispatchQue;
    
    ECGImageRef _pendingImage;
    
    ImageCacheEntry* __weak _currentEntry;
    ImageCacheEntry* __weak _nextEntry;
    ImageCacheEntry* __weak _previousEntry;
    
    ImageLayer* _currentLayer;
    ImageLayer* _nextLayer;
    ImageLayer* _previousLayer;
    
    ImageLayer* __weak _swipingLayer;
    ImageLayer* __weak _swipeAnotherLayer;
    RelationalImageDirection _swipeDirection;
    CGFloat _swipeOffsetBias;
    CGFloat _swipeLeftLimit;
    CGFloat _swipeRightLimit;
    
    NSTimer* _timerForSwipe;
    NSTimeInterval _lastTimeForSwipe;
    BOOL _swipeWillSucceed;
    SwipeInertiaState _swipeInertiaState;
    CGFloat _swipeInertiaVelocity;
    CGFloat _swipeInertiaTerminalPosition;

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
        
        //_pendingImage = [self pendingImage];
    }
    return self;
}

- (CGImageRef)pendingImage
{
    CGRect frame = [NSScreen mainScreen].frame;
    CGFloat size = MIN(frame.size.width, frame.size.height);
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context(CGBitmapContextCreate(NULL, size, size, 8, 0,colorSpace, kCGImageAlphaNoneSkipLast));
    
    CGFloat lineWidth = size / 200;
    CGFloat lineDash = size / 70;
    CGContextSetRGBStrokeColor(context, 40, 40, 40, 255);
    CGContextSetLineWidth(context, lineWidth);
    CGFloat dashAttrs[]={lineDash, lineDash};
    CGContextSetLineDash(context, 0, dashAttrs, sizeof(dashAttrs)/sizeof(*dashAttrs));
    CGContextStrokeRect(context, CGRectMake(size / 20, size / 20, size - size / 10, size - size / 10));

    return CGBitmapContextCreateImage(context);
}

//-----------------------------------------------------------------------------------------
// イメージノード設定
//-----------------------------------------------------------------------------------------
- (void)setRelationalImage:(id)relationalImage
{
    [_timerForSwipe invalidate];
    _swipeInertiaState = SwipeInertiaEnd;

    if (_relationalImage != relationalImage){
        _relationalImage = relationalImage;
        
        // キャッシュ探索 & 必要であれば画像レンダリング
        ImageCacheEntry* current = [self findCacheById:_relationalImage withImage:YES];
        id nextNode = [_relationalImageAccessor nextObjectOfObject:_relationalImage];
        ImageCacheEntry* next = nextNode ? [self findCacheById:nextNode withImage:NO] : nil;
        id previousNode = [_relationalImageAccessor previousObjectOfObject:_relationalImage];
        ImageCacheEntry* previous = previousNode ? [self findCacheById:previousNode withImage:NO] : nil;

        // レイヤーの役割交換 & レイヤーへの画像割り当て
        ImageLayer* oldLayer = nil;
        if (current == _nextEntry){
            oldLayer = _previousLayer;
            _previousLayer = _currentLayer;
            _currentLayer = _nextLayer;
            _nextLayer = oldLayer;
            [_nextLayer setImage:next.image withRotation:next.rotation];
        }else if (current == _previousEntry){
            oldLayer = _nextLayer;
            _nextLayer = _currentLayer;
            _currentLayer = _previousLayer;
            _previousLayer = oldLayer;
            [_previousLayer setImage:previous.image withRotation:previous.rotation];
        }else{
            [_currentLayer setImage:current.image withRotation:current.rotation];
            [_nextLayer setImage:next.image withRotation:next.rotation];
            [_previousLayer setImage:previous.image withRotation:previous.rotation];
        }
        _currentEntry = current;
        _nextEntry = next;
        _previousEntry = previous;
        [self applyAttributesForLayer:_currentLayer];

        // 表示切り替え
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        _currentLayer.zPosition = 1;
        _currentLayer.hidden = NO;
        _currentLayer.frame = self.frame;
        _nextLayer.zPosition = 0;
        _nextLayer.hidden = YES;
        _previousLayer.zPosition = 0;
        _previousLayer.hidden = YES;
        [CATransaction commit];
    }
    
    // 投機的キャッシング
    if (relationalImage){
        [self fillCacheSpeculatively];
    }
}

//-----------------------------------------------------------------------------------------
// キャッシュ操作
//-----------------------------------------------------------------------------------------
- (ImageCacheEntry*)findCacheById:(id)relationalImage withImage:(BOOL)needImage
{
    NSInteger index = [_imageCache indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL* stop){
        return (BOOL)(((ImageCacheEntry*)obj).imageId == relationalImage);
    }];
    ImageCacheEntry* entry = nil;
    if (index == NSNotFound){
        entry = [_imageCache firstObject];
        entry.state = CacheStandBy;
        entry.imageId = relationalImage;
        entry.image = (__bridge id)(CGImageRef)_pendingImage;
        entry.rotation = 1;
        if (!relationalImage){
            entry.state = CacheVarid;
        }else if (needImage){
            ImageRenderer* renderer =
                [ImageRenderer imageRendererWithPath:[_relationalImageAccessor imagePathOfObject:relationalImage]];
            entry.image = renderer.image;
            entry.rotation = renderer.rotation;
            entry.state = CacheVarid;
        }
    }else{
        entry = _imageCache[index];
        if (entry.state != CacheVarid){
            dispatch_semaphore_wait(entry.semaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
    // process LRU
    [_imageCache removeObject:entry];
    [_imageCache addObject:entry];
    
    return entry;
}

- (void)fillCacheSpeculatively
{
    RelationalImageAccessor* accessor = _relationalImageAccessor;
    
    for (NSInteger i = 0; i < _imageCache.count; i++){
        ImageCacheEntry* entry = _imageCache[i];
        if (entry.state == CacheStandBy){
            entry.state = CacheProcessing;
            entry.semaphore = dispatch_semaphore_create(0);
            ImageLayer* layer = entry == _nextEntry ? _nextLayer :
            entry == _previousEntry ? _previousLayer :
            nil;
            dispatch_async(_dispatchQue, ^(){
                ImageRenderer* renderer = [ImageRenderer imageRendererWithPath:[accessor imagePathOfObject:entry.imageId]];
                entry.image = renderer.image;
                entry.rotation = renderer.rotation;
                [layer setImage:entry.image withRotation:entry.rotation];
                entry.state = CacheVarid;
                dispatch_semaphore_signal(entry.semaphore);
            });
        }
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
// スワイプ処理
//-----------------------------------------------------------------------------------------
static const CGFloat SWIPE_FRICTION = 0.9;
static const CGFloat SWIPE_POSITION_THRESHOLD = 1.0/3.0;
static const CGFloat SWIPE_VELOCITY_THRESHOLD = 1;
static const CGFloat SWIPE_INRANGE_VELOCITY = 3;
static const CGFloat SWIPE_OUTRANGE_SPRING = 1000;
static const CGFloat SWIPE_OUTRANGE_VISCOSITY = 120;
static const CGFloat SWIPE_OUTRANGE_STOP = 1;

- (void)startSwipeForDirection:(RelationalImageDirection)direction
{
    _swipeDirection = direction;
    if (_swipeDirection == RelationalImageNext){
        _swipingLayer = _nextEntry ? _nextLayer : _currentLayer;
        _swipeAnotherLayer = _nextEntry ? _currentLayer : nil;
        _swipeOffsetBias = _nextEntry ? self.frame.size.width : 0;
        _swipeLeftLimit = -self.frame.size.width;
        _swipeRightLimit = 0;
    }else{
        _swipingLayer = _currentLayer;
        _swipeAnotherLayer = _previousEntry ? _previousLayer : nil;
        _swipeOffsetBias = 0;
        _swipeLeftLimit = 0;
        _swipeRightLimit = self.frame.size.width;
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [self applyAttributesForLayer:_swipingLayer == _currentLayer ? _swipeAnotherLayer : _swipingLayer];
    if (_swipingLayer){
        _swipingLayer.zPosition = 1;
        CGRect frame = self.frame;
        frame.origin.x = _swipeOffsetBias;
        _swipingLayer.frame = frame;
        _swipingLayer.hidden = NO;
    }
    if (_swipeAnotherLayer){
        _swipeAnotherLayer.zPosition = 0.5;
        _swipeAnotherLayer.frame = self.frame;
        _swipeAnotherLayer.hidden = NO;
    }
    [CATransaction commit];
}

- (void)setSwipeOffset:(CGFloat)swipeOffset
{
    CGRect frame = _currentLayer.frame;
    swipeOffset *= frame.size.width;
    if (!_swipeAnotherLayer){
        swipeOffset *= (1.0 - SWIPE_FRICTION);
    }
    swipeOffset =  MAX(swipeOffset, _swipeLeftLimit);
    swipeOffset = MIN(swipeOffset, _swipeRightLimit);
    frame.origin.x = swipeOffset + _swipeOffsetBias;
    _swipeOffset = swipeOffset / frame.size.width;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _swipingLayer.frame = frame;
    [CATransaction commit];
}

- (void)fixSwipeOffsetWithVelocity:(CGFloat)velocity
{
    if (_swipeOffset != 0){
        if (_swipeAnotherLayer){
            _swipeInertiaState = SwipeInertiaInrange;
            CGFloat direction = _swipeDirection == RelationalImageNext ? -1.0 : 1.0;
            _swipeInertiaTerminalPosition = self.frame.size.width * direction;
            _swipeWillSucceed = YES;
            if (velocity * direction < 0 ||
                (velocity * direction < SWIPE_VELOCITY_THRESHOLD && fabs(_swipeOffset) < SWIPE_POSITION_THRESHOLD)){
                direction *= -1;
                _swipeWillSucceed = NO;
                _swipeInertiaTerminalPosition = 0;
            }
            _swipeInertiaVelocity = SWIPE_INRANGE_VELOCITY * self.frame.size.width * direction;
        }else{
            _swipeInertiaState = SwipeInertiaOutrange;
            _swipeWillSucceed = NO;
            _swipeInertiaTerminalPosition = 0;
            _swipeInertiaVelocity = velocity * self.frame.size.width;
        }
        _lastTimeForSwipe = nowInEpocTime();
        _timerForSwipe = [NSTimer scheduledTimerWithTimeInterval:0.002 target:self
                                                        selector:@selector(proceedSwipeInertia:)
                                                        userInfo:nil repeats:YES];
    }
}

- (void)proceedSwipeInertia:(NSTimer*)timer
{
    NSTimeInterval now = nowInEpocTime();
    NSTimeInterval interval = now - _lastTimeForSwipe;
    _lastTimeForSwipe = now;

    CGFloat position = _swipingLayer.frame.origin.x - _swipeOffsetBias;
    
    if (_swipeInertiaState == SwipeInertiaInrange){
        position += _swipeInertiaVelocity * interval;
        if ((_swipeInertiaVelocity > 0 && position > _swipeInertiaTerminalPosition) ||
            (_swipeInertiaVelocity < 0 && position < _swipeInertiaTerminalPosition)){
            position = _swipeInertiaTerminalPosition;
            _swipeInertiaState = SwipeInertiaEnd;
        }
    }else if (_swipeInertiaState == SwipeInertiaOutrange){
        _swipeInertiaVelocity += -SWIPE_OUTRANGE_SPRING * position * interval;
        CGFloat delta = _swipeInertiaVelocity * interval;
        if (_swipeInertiaVelocity * position < 0){
            _swipeInertiaState = SwipeInertiaCompensate;
        }
        position += delta;
    }else if (_swipeInertiaState == SwipeInertiaCompensate){
        _swipeInertiaVelocity += (-SWIPE_OUTRANGE_SPRING * position - _swipeInertiaVelocity * SWIPE_OUTRANGE_VISCOSITY) * interval;
        position += _swipeInertiaVelocity * interval;
        if (fabs(position) < SWIPE_OUTRANGE_STOP ||
            (_swipeDirection == RelationalImageNext && position > 0) ||
            (_swipeDirection == RelationalImagePrevious && position < 0)){
            _swipeInertiaState = SwipeInertiaEnd;
            position = 0;
        }
    }

    CGRect frame = _swipingLayer.frame;
    frame.origin.x = position + _swipeOffsetBias;
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    _swipingLayer.frame = frame;
    [CATransaction commit];
    
    if (_swipeInertiaState == SwipeInertiaEnd){
        [timer invalidate];
        if (_swipeWillSucceed){
            if (self.delegate && _didEndSwipeSelector){
                [(NSObject*)self.delegate performSelector:_didEndSwipeSelector withObject:@(_swipeDirection) afterDelay:0];
            }
        }else{
            if (_swipeAnotherLayer){
                CALayer* target = _swipingLayer == _currentLayer ? _swipeAnotherLayer : _swipingLayer;
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                target.zPosition = 0;
                //target.frame = CGRectZero;
                target.hidden = YES;
                [CATransaction commit];
            }
        }
    }
}

- (BOOL)isInSwipeInertiaMode
{
    return _swipeInertiaState != SwipeInertiaEnd;
}

//-----------------------------------------------------------------------------------------
// トランジション処理
//-----------------------------------------------------------------------------------------
- (void)moveToDirection:(RelationalImageDirection)direction withTransition:(TransitionEffect*)effect inScreen:(NSScreen *)screen
{
    CGFloat scale = screen.backingScaleFactor;
    self.contentsScale = scale;
    _currentLayer.contentsScale = scale;
    _nextLayer.contentsScale = scale;
    _previousLayer.contentsScale = scale;
    
    _swipeDirection = direction;
    ImageCacheEntry* targetEntry = direction == RelationalImageNext ? _nextEntry : _previousEntry;
    if (!targetEntry){
        return;
    }
    if (targetEntry.state == CacheProcessing){
        dispatch_semaphore_wait(targetEntry.semaphore, DISPATCH_TIME_FOREVER);
    }

    ImageLayer* target = direction == RelationalImageNext ? _nextLayer : _previousLayer;
    id targetImage = direction == RelationalImageNext ? _nextEntry.image : _previousEntry.image;

    super.backgroundColor = _imageBackgroundColor;
    [self applyAttributesForLayer:target];
    
    effect.delegate = self;
    effect.didEndSelector = @selector(didEndTransition);
    effect.fromLayer = _currentLayer;
    effect.fromImage = _currentEntry.image;
    effect.toLayer = target;
    effect.toImage = targetImage;
    
    [effect performTransition];
}

- (void)didEndTransition
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    super.backgroundColor = [NSColor whiteColor].CGColor;
    [CATransaction commit];
    if (self.delegate && _didEndSwipeSelector){
        [(NSObject*)self.delegate performSelector:_didEndSwipeSelector withObject:@(_swipeDirection) afterDelay:0];
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
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if (backgroundColor){
        CFRetain(backgroundColor);
    }
    _imageBackgroundColor = backgroundColor;
    _currentLayer.backgroundColor = backgroundColor;
    [CATransaction commit];
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

- (int)borderCondition
{
    return _currentLayer.borderCondition;
}

@end
