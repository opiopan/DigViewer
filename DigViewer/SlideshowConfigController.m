//
//  SlideshowConfigController.m
//  DigViewer
//
//  Created by opiopan on 2015/05/08.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SlideshowConfigController.h"
#import "TransitionEffects.h"

NSString* kSlideshowTransitionNone = @"SlideshowTransitionNone";
NSString* kSlideshowTransitionFade = @"SlideshowTransitionFade";
NSString* kSlideshowTransitionMoveIn = @"SlideshowTransitionMoveIn";
NSString* kSlideshowTransitionPush = @"SlideshowTransitionPush";
NSString* kSlideshowTransitionReveal = @"SlideshowTransitionReveal";
NSString* kSlideshowTransitionShutter = @"SlideshowTransitionShutter";
NSString* kSlideshowTransitionCartain = @"SlideshowTransitionCartain";
NSString* kSlideshowTransitionMosaic = @"SlideshowTransitionMosaic";
NSString* kSlideshowTransitionZoom = @"SlideshowTransitionZoom";
NSString* kSlideshowTransitionBlur = @"SlideshowTransitionBlur";
NSString* kSlideshowTransitionMod = @"SlideshowTransitionMod";
NSString* kSlideshowTransitionRipple = @"SlideshowTransitionRipple";
NSString* kSlideshowTransitionBurnOut = @"SlideshowTransitionBurnOut";

//=========================================================================================
// EffectEntry: エフェクトを表すオブジェクト
//=========================================================================================
static const char* EffectTypeString[] = {"effectBuiltIn", "effectCIKernel", "effectQCCompositon"};

static NSString* kCustomEffectName = @"name";
static NSString* kCustomEffectType = @"type";
static NSString* kCustomEffectPath = @"path";
static NSString* kCustomEffectDuration = @"duration";

typedef TransitionEffect* (^EffectFactory)(id);

@interface EffectEntry : NSObject
@property (nonatomic) NSString* name;
@property (readonly, nonatomic) NSString* identifier;
@property (readonly, nonatomic) EffectType type;
@property (readonly, nonatomic) NSString* typeString;
@property (readonly, nonatomic) NSString* path;
@property (nonatomic) CGFloat duration;
@property (readonly, nonatomic) EffectFactory effectFactory;
+ (EffectEntry*)entryWithName:(NSString*)name type:(EffectType)type path:(NSString*)path duration:(CGFloat)duration;
- (instancetype)initWithName:(NSString*)name type:(EffectType)type path:(NSString*)path duration:(CGFloat)duration;
@end

@implementation EffectEntry
+ (EffectEntry *)entryWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
{
    return [[EffectEntry alloc] initWithName:name type:type path:path duration:duration];
}

+ (EffectEntry *)entryWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
                 effectFactory:(EffectFactory)factory
{
    return [[EffectEntry alloc] initWithName:name type:type path:path duration:duration effectFactory:factory];
}

- (instancetype)initWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
{
    self = [self init];
    if (self){
        _name = name;
        _type = type;
        _path = path;
        _duration = duration;
        _typeString = NSLocalizedString(@(EffectTypeString[_type]), nil);
        _identifier = _type == effectBuiltIn ? path : [@"custom:" stringByAppendingString:path];
        if (_type == effectCIKernel){
            _effectFactory = ^(EffectEntry* entry){
                return [[EffectByCIKernel alloc] initWithShaderPath:entry.path duration:entry.duration];
            };
        }else if (_type == effectQCComposition){
            _effectFactory = ^(EffectEntry* entry){
                return [[EffectByQCComposition alloc] initWithShaderPath:entry.path duration:entry.duration];
            };
        }
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
               effectFactory:(EffectFactory)factory
{
    self = [self initWithName:name type:type path:path duration:duration];
    if (self){
        _effectFactory = factory;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    return [self.identifier isEqualToString:[(EffectEntry*)object identifier]];
}

@end

//=========================================================================================
// SlideshowConfigControllerの実装
//=========================================================================================
@implementation SlideshowConfigController{
    NSUserDefaultsController* _controller;
    NSArray* _builtInEffects;
    NSArray* _allEffects;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (id)sharedController
{
    static SlideshowConfigController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [[SlideshowConfigController alloc] init];
    }
    
    return sharedController;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _controller = [NSUserDefaultsController sharedUserDefaultsController];
        _updateCount = 0;
        _interval = [_controller.values valueForKey:@"slideshowInterval"];
        _transition = [_controller.values valueForKey:@"slideshowTransitionID"];
        _viewType = [[_controller.values valueForKey:@"slideshowViewType"] intValue];
        _showOnTheOtherScreen = [[_controller.values valueForKey:@"slideshowShowOnTheOtherScreen"] boolValue];
        _disableSleep = [[_controller.values valueForKey:@"slideshowDisableSleep"] boolValue];
        NSArray* customEffects = [_controller.values valueForKey:@"slideshowCustomEffects"];
        NSMutableArray* converted = [NSMutableArray new];
        for (NSDictionary* entry in customEffects){
            [converted addObject:[EffectEntry entryWithName:[entry valueForKey:kCustomEffectName]
                                                       type:[[entry valueForKey:kCustomEffectType] intValue]
                                                       path:[entry valueForKey:kCustomEffectPath]
                                                   duration:[[entry valueForKey:kCustomEffectDuration] doubleValue]]];
        }
        _customEffects = converted;
        
        _builtInEffects = @[[EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionNone, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionNone
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             return [TransitionEffect new];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionFade, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionFade
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionFade];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionMoveIn, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionMoveIn
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionMoveIn];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionPush, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionPush
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionPush];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionReveal, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionReveal
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionReveal];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionShutter, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionShutter
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByCIKernel alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"Shutter"
                                                                                                           ofType:@"cikernel"]
                                                                  duration:0.5];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionCartain, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionCartain
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByCIKernel alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"Cartain"
                                                                                                           ofType:@"cikernel"]
                                                                  duration:2.0];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionMosaic, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionMosaic
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByCIKernel alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"Mosaic"
                                                                                                           ofType:@"cikernel"]
                                                                  duration:3.0];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionZoom, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionZoom
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByCIKernel alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"Zoom"
                                                                                                           ofType:@"cikernel"]
                                                                  duration:2.0];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionBlur, nil)
                                                    type:effectBuiltIn path:kSlideshowTransitionBlur
                                                duration:0
                                           effectFactory:^(EffectEntry* entry){
                                               return [BlurTransition new];
                                           }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionMod, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionMod
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByQCComposition alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"Mod"
                                                                                                           ofType:@"qtz"]
                                                                  duration:1.0];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionRipple, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionRipple
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByQCComposition alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"Ripple"
                                                                                                           ofType:@"qtz"]
                                                                  duration:1.5];
                                         }],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionBurnOut, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionBurnOut
                                              duration:0
                                         effectFactory:^(EffectEntry* entry){
                                             id rc = [EffectByQCComposition alloc];
                                             return [rc initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"BurnOut"
                                                                                                           ofType:@"qtz"]
                                                                  duration:5.5];
                                         }],
                            ];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setInterval:(NSNumber*)interval
{
    _interval = interval;
    [_controller.values setValue:_interval forKey:@"slideshowInterval"];
    if (!_interval){
        _interval = [_controller.values valueForKey:@"slideshowInterval"];
    }
    _updateCount++;
}

- (void)setTransition:(NSString*)transition
{
    _transition = transition;
    [_controller.values setValue:_transition forKey:@"slideshowTransitionID"];
    _updateCount++;
}

- (void)setViewType:(SlideshowViewType)viewType
{
    _viewType = viewType;
    [_controller.values setValue:@(_viewType) forKey:@"slideshowViewType"];
    _updateCount++;
}

- (void)setShowOnTheOtherScreen:(BOOL)showOnTheOtherScreen
{
    _showOnTheOtherScreen = showOnTheOtherScreen;
    [_controller.values setValue:@(_showOnTheOtherScreen) forKey:@"slideshowShowOnTheOtherScreen"];
    _updateCount++;
}

- (void)setDisableSleep:(BOOL)disableSleep
{
    _disableSleep = disableSleep;
    [_controller.values setValue:@(_disableSleep) forKey:@"slideshowDisableSleep"];
    _updateCount++;
}

- (void)setCustomEffects:(NSArray *)customEffects
{
    _allEffects = nil;
    NSMutableArray* converted = [NSMutableArray new];
    for (EffectEntry* entry in customEffects){
        [converted addObject:@{kCustomEffectName: entry.name,
                               kCustomEffectType: @(entry.type),
                               kCustomEffectPath: entry.path,
                               kCustomEffectDuration: @(entry.duration)}];
    }
    [_controller.values setValue:converted forKey:@"slideshowCustomEffects"];
    _updateCount++;

    [self willChangeValueForKey:@"allEffects"];
    _customEffects = customEffects;
    NSInteger index;
    NSArray* all = self.allEffects;
    for (index = 0; index < all.count; index++){
        if ([[(EffectEntry*)all[index] identifier] isEqualToString:_transition]){
            break;
        }
    }
    if (index >= all.count){
        self.transition = kSlideshowTransitionFade;
    }
    [self didChangeValueForKey:@"allEffects"];
}

- (NSArray*)allEffects
{
    if (!_allEffects){
        _allEffects = [_builtInEffects arrayByAddingObjectsFromArray:_customEffects];
    }
    return _allEffects;
}

//-----------------------------------------------------------------------------------------
// 遷移効果オブジェクトファクトリ
//-----------------------------------------------------------------------------------------
- (TransitionEffect*)transitionEffect
{
    EffectEntry* entry = nil;
    for (EffectEntry* current in self.allEffects){
        if ([current.identifier isEqualToString:_transition]){
            entry = current;
            break;
        }
    }
    if (entry){
        return entry.effectFactory(entry);
    }else{
        return nil;
    }
}

//-----------------------------------------------------------------------------------------
// カスタムエフェクトオブジェクト生成
//-----------------------------------------------------------------------------------------
+ (id)customEffectWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
{
    return [EffectEntry entryWithName:name type:type path:path duration:duration];
}

@end
