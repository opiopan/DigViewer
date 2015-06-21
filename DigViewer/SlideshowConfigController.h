//
//  SlideshowConfigController.h
//  DigViewer
//
//  Created by opiopan on 2015/05/08.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransitionEffect.h"

enum _SlideshowTransition{
    SlideshowTransitionNone,
    SlideshowTransitionFade,
    SlideshowTransitionMoveIn,
    SlideshowTransitionPush,
    SlideshowTransitionReveal
};
typedef enum _SlideshowTransition SlideshowTransition;

enum _SlideshowViewType{
    SlideshowWindow,
    SlideshowFullScreen
};
typedef enum _SlideshowViewType SlideshowViewType;

@interface SlideshowConfigController : NSObject

@property (strong, nonatomic) NSNumber* interval;
@property (assign, nonatomic) SlideshowTransition transition;
@property (readonly, nonatomic) TransitionEffect* transitionEffect;
@property (assign, nonatomic) SlideshowViewType viewType;
@property (assign, nonatomic) BOOL showOnTheOtherScreen;

@property (assign, readonly, nonatomic) NSInteger updateCount;

+ (SlideshowConfigController*)sharedController;

@end
