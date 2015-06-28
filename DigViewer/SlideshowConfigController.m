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

//=========================================================================================
// EffectEntry: エフェクトを表すオブジェクト
//=========================================================================================
static const char* EffectTypeString[] = {"effectBuiltIn", "effectCIKernel", "effectQCCompositon"};

static NSString* kCustomEffectName = @"name";
static NSString* kCustomEffectType = @"type";
static NSString* kCustomEffectPath = @"path";
static NSString* kCustomEffectDuration = @"duration";

@interface EffectEntry : NSObject
@property (nonatomic) NSString* name;
@property (readonly, nonatomic) NSString* identifier;
@property (readonly, nonatomic) EffectType type;
@property (readonly, nonatomic) NSString* typeString;
@property (readonly, nonatomic) NSString* path;
@property (nonatomic) CGFloat duration;
+ (EffectEntry*)entryWithName:(NSString*)name type:(EffectType)type path:(NSString*)path duration:(CGFloat)duration;
- (instancetype)initWithName:(NSString*)name type:(EffectType)type path:(NSString*)path duration:(CGFloat)duration;
@end

@implementation EffectEntry
+ (EffectEntry *)entryWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
{
    return [[EffectEntry alloc] initWithName:name type:type path:path duration:duration];
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
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([[object class] isSubclassOfClass:[NSString class]]){
        return [self.identifier isEqualToString:object];
    }else if ([[object class] isSubclassOfClass:[self class]]){
        return [self.identifier isEqualToString:[(EffectEntry*)object identifier]];
    }else{
        return NO;
    }
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
                                              duration:0],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionFade, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionFade
                                              duration:0],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionMoveIn, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionMoveIn
                                              duration:0],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionPush, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionPush
                                              duration:0],
                            [EffectEntry entryWithName:NSLocalizedString(kSlideshowTransitionReveal, nil)
                                                  type:effectBuiltIn path:kSlideshowTransitionReveal
                                              duration:0]];
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
    if (!entry){
        return nil;
    }

    if (entry.type == effectBuiltIn){
        if ([entry.path isEqualToString:kSlideshowTransitionNone]){
            return [TransitionEffect new];
        }else if ([entry.path isEqualToString:kSlideshowTransitionFade]){
            return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionFade];
            /*
            return [[EffectByCIKernel alloc] initWithShaderPath:[[NSBundle mainBundle] pathForResource:@"FadeEffect"
                                                                                                ofType:@"cikernel"]
                                                       duration:0.5];
             */
        }else if ([entry.path isEqualToString:kSlideshowTransitionMoveIn]){
            return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionMoveIn];
        }else if ([entry.path isEqualToString:kSlideshowTransitionPush]){
            return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionPush];
        }else if ([entry.path isEqualToString:kSlideshowTransitionReveal]){
            return [[BuiltinEffect alloc] initWithType:kSlideshowTransitionReveal];
        }
    }else if (entry.type == effectCIKernel){
        return [[EffectByCIKernel alloc] initWithShaderPath:entry.path duration:entry.duration];
    }else if (entry.type == effectQCComposition){
        // not impremented
    }
    
    return nil;
}

//-----------------------------------------------------------------------------------------
// カスタムエフェクトオブジェクト生成
//-----------------------------------------------------------------------------------------
+ (id)customEffectWithName:(NSString *)name type:(EffectType)type path:(NSString *)path duration:(CGFloat)duration
{
    return [EffectEntry entryWithName:name type:type path:path duration:duration];
}

@end
