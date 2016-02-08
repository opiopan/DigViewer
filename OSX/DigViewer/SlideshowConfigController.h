//
//  SlideshowConfigController.h
//  DigViewer
//
//  Created by opiopan on 2015/05/08.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransitionEffect.h"

extern NSString* kSlideshowTransitionNone;
extern NSString* kSlideshowTransitionFade;
extern NSString* kSlideshowTransitionMoveIn;
extern NSString* kSlideshowTransitionPush;
extern NSString* kSlideshowTransitionReveal;

enum _SlideshowViewType{
    SlideshowWindow,
    SlideshowFullScreen
};
typedef enum _SlideshowViewType SlideshowViewType;

enum _EffectType {effectBuiltIn, effectCIKernel, effectQCComposition};
typedef enum _EffectType EffectType;

@interface SlideshowConfigController : NSObject

@property (strong, nonatomic) NSNumber* interval;
@property (strong, nonatomic) NSString* transition;
@property (readonly, nonatomic) TransitionEffect* transitionEffect;
@property (assign, nonatomic) SlideshowViewType viewType;
@property (assign, nonatomic) BOOL showOnTheOtherScreen;
@property (strong, nonatomic) NSArray* customEffects;
@property (readonly, nonatomic) NSArray* allEffects;
@property (assign, nonatomic) BOOL disableSleep;

@property (assign, readonly, nonatomic) NSInteger updateCount;

+ (SlideshowConfigController*)sharedController;
+ (id)customEffectWithName:(NSString*)name type:(EffectType)type path:(NSString*)path duration:(CGFloat)duration;

@end
