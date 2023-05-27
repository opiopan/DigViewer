//
//  SlideshowController.m
//  DigViewer
//
//  Created by opiopan on 2015/06/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SlideshowController.h"
#import "SlideshowConfigController.h"
#import "ImageViewController.h"
#import "NSViewController+Nested.h"
#import "NSView+ViewControllerAssociation.h"
#import "ImageViewConfigController.h"
#import "TransitionEffects.h"

@implementation SlideshowController{
    BOOL _canceled;
    SlideshowConfigController* _config;
    NSString* _transitionType;
    TransitionEffect* _transitionEffect;
    NSProcessInfo* _processInfo;
    id _activityToken;
    
    ImageViewController* _imageViewController;
    id _relationalImage;
    NSWindow* _window;
    NSTimer* _timer;
}

static SlideshowController* _currentController;

//-----------------------------------------------------------------------------------------
// ファクトリメソッド
//-----------------------------------------------------------------------------------------
+ (SlideshowController *)newController
{
    SlideshowController* rc = nil;
    if (!_currentController){
        _currentController = [SlideshowController new];
        rc = _currentController;
    }
    return rc;
}

+ (SlideshowController *)currentController
{
    return _currentController;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _canceled = NO;
        _config = [SlideshowConfigController sharedController];
        _imageAccessor = [RelationalImageAccessor new];
        _processInfo = [NSProcessInfo processInfo];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// スライドショー中にマウスカーソルを隠すべきか判定
//-----------------------------------------------------------------------------------------
- (BOOL)shouldHideCursor
{
    return _config.viewType == SlideshowFullScreen && [NSScreen screens].count == 1;
}

//-----------------------------------------------------------------------------------------
// スライドショー対象スクリーン特定
//-----------------------------------------------------------------------------------------
- (NSScreen*)targetScreenWithCurrentScreen:(NSScreen*)currentScreen
{
    NSArray* screens = [NSScreen screens];
    NSScreen* rc = nil;
    if (screens.count > 1 && _config.showOnTheOtherScreen){
        // 別スクリーン
        for (rc in screens){
            if (rc != currentScreen){
                break;
            }
        }
    }else if (_config.viewType == SlideshowFullScreen){
        // カレントスクリーン
        rc = currentScreen;
    }
    
    return rc;
}

//-----------------------------------------------------------------------------------------
// スライドショー開始
//-----------------------------------------------------------------------------------------
- (void)startSlideshowWithScreen:(NSScreen *)screen
                 relationalImage:(id)relationalImage
                targetController:(NSViewController *)controller
{
    _relationalImage = relationalImage;
    _imageViewController = (ImageViewController*)controller;
    _imageViewController.isVisible = YES;
    [_imageViewController beginSlideshow];
    if (screen){
        NSRect frame = screen.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                  defer:NO
                                                 screen:screen];
        _window.releasedWhenClosed = YES;
        _window.displaysWhenScreenProfileChanges = YES;
        _window.windowController = self;
        _window.backgroundColor = [[ImageViewConfigController sharedController] backgroundColor];
        _window.level = NSScreenSaverWindowLevel + 1;
        [_window.contentView associateSubViewWithController:_imageViewController];
        NSRect vframe = frame;
        if (@available(macOS 12.0, *)) {
            vframe.size.height -= screen.auxiliaryTopLeftArea.size.height;
        }
        _imageViewController.view.frame = vframe;
        [_window makeKeyAndOrderFront:self];
        [_window makeFirstResponder:_imageViewController.view];
        self.window = _window;
    }
    
    if ([self shouldHideCursor]){
        [NSCursor hide];
    }
    if (_config.disableSleep){
        _activityToken = [_processInfo beginActivityWithOptions:NSActivityIdleDisplaySleepDisabled |
                                                                NSActivityIdleSystemSleepDisabled
                                                         reason:@"DigViewer is proceeding a slide show"];
    }
    
    _transitionType = _config.transition;
    _transitionEffect = _config.transitionEffect;
    [_transitionEffect prepareTransitionOnLayer:_imageViewController.view.layer];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:_config.interval.doubleValue target:self
                                            selector:@selector(moveToNextImage:)
                                            userInfo:nil repeats:YES];
}

- (void)moveToNextImage:(NSTimer*)timer
{
    if (_canceled){
        return;
    }
    
    id nextImage = [_imageAccessor nextObjectOfObject:_relationalImage];
    if (nextImage){
        if (![_transitionType isEqualToString:_config.transition]){
            [_transitionEffect cleanUpTransition];
            _transitionType = _config.transition;
            _transitionEffect = _config.transitionEffect;
            [_transitionEffect prepareTransitionOnLayer:_imageViewController.view.layer];
        }
        [_imageViewController moveToDirection:RelationalImageNext withTransition:_transitionEffect];
        _relationalImage = nextImage;
        double interval = _config.interval.doubleValue + _transitionEffect.duration;
        if (interval != _timer.timeInterval){
            [_timer invalidate];
            _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self
                                                    selector:@selector(moveToNextImage:)
                                                    userInfo:nil repeats:YES];
        }
    }else{
        [self cancelSlideshow];
    }
}

//-----------------------------------------------------------------------------------------
// スライドショーキャンセル
//-----------------------------------------------------------------------------------------
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)cancelSlideshow
{
    [_timer invalidate];
    _canceled = YES;
    [_transitionEffect cleanUpTransition];
    
    if (_window){
        [self.window setFrame:NSZeroRect display:YES];
        [_imageViewController.view removeFromSuperview];
        [_imageViewController setIsVisible:NO];
        [self close];
    }
    [_imageViewController endSlideshow];
    [NSCursor unhide];
    if (_activityToken){
        [_processInfo endActivity:_activityToken];
        _activityToken = nil;
    }
    if (_delegate && _didEndSelector){
        [_delegate performSelector:_didEndSelector withObject:nil];
    }
    _currentController = nil;
    
}
#pragma clang diagnostic pop

@end

