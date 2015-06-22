//
//  SlideshowPreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/06/03.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SlideshowPreferences.h"
#import "FocusCatchableTextField.h"
#import "ClickableImageView.h"
#import "NSWindow+TracingResponderChain.h"

//-----------------------------------------------------------------------------------------
// トランジション用relationalImageオブジェクトの定義
//-----------------------------------------------------------------------------------------
@interface RelationalImageForSample : NSObject
@property (strong) NSString* imagePath;
@property (weak) id nextImageNode;
@property (weak) id previousImageNode;
@end

@implementation RelationalImageForSample
@end

//-----------------------------------------------------------------------------------------
// SlideshowPreferencesの実装
//-----------------------------------------------------------------------------------------
@interface SlideshowPreferences ()
@property (weak) IBOutlet ClickableImageView* imageView;
@property (weak) IBOutlet FocusCatchableTextField* focusingField;
@end

@implementation SlideshowPreferences{
    NSArray* _relationalImages;
    NSTimer* _timerForTransition;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self){
        _slideshowConfig = [SlideshowConfigController sharedController];
    }
    return self;
}

- (void)initializeFromDefaults
{
    // フォーカス移動検出用text fieldに通知セレクタを登録
    _focusingField.delegate = self;
    _focusingField.notifyFocusChangeSelector = @selector(updateTimer:);
    
    // トランジション用relationalImageの作成
    #define RELATIONAL_IMAGE(n) ((RelationalImageForSample*)_relationalImages[n])
    _relationalImages = @[[RelationalImageForSample new], [RelationalImageForSample new], [RelationalImageForSample new]];
    RELATIONAL_IMAGE(0).imagePath = [[NSBundle mainBundle] pathForImageResource:@"thumbnailSampleSquare"];
    RELATIONAL_IMAGE(0).nextImageNode = RELATIONAL_IMAGE(1);
    RELATIONAL_IMAGE(0).previousImageNode = RELATIONAL_IMAGE(2);
    RELATIONAL_IMAGE(1).imagePath = [[NSBundle mainBundle] pathForImageResource:@"thumbnailSampleHorizontal"];
    RELATIONAL_IMAGE(1).nextImageNode = RELATIONAL_IMAGE(2);
    RELATIONAL_IMAGE(1).previousImageNode = RELATIONAL_IMAGE(0);
    RELATIONAL_IMAGE(2).imagePath = [[NSBundle mainBundle] pathForImageResource:@"thumbnailSampleVertical"];
    RELATIONAL_IMAGE(2).nextImageNode = RELATIONAL_IMAGE(0);
    RELATIONAL_IMAGE(2).previousImageNode = RELATIONAL_IMAGE(1);
    
    // ImageViewの設定
    _imageView.delegate = self;
    _imageView.isDrawingByLayer = YES;
    _imageView.backgroundColor = [NSColor blackColor];
    _imageView.enableGesture = NO;
    _imageView.notifySwipeSelector = @selector(didEndTransition:);
    
    // ImageViewにrelationalImageを設定
    _imageView.relationalImage = RELATIONAL_IMAGE(0);
    
    // トランジション用タイマー駆動
    [self updateTimer:self];
}

//-----------------------------------------------------------------------------------------
// シートのアピアランス設定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

//-----------------------------------------------------------------------------------------
// トランジションサンプル制御
//-----------------------------------------------------------------------------------------
static CGFloat TRANSITION_INTERVAL = 2;

- (void) updateTimer:(id)sender
{
    if ([_preferencesView.window isBelongToResponderChain:_focusingField]){
        if (!_timerForTransition){
            _timerForTransition = [NSTimer scheduledTimerWithTimeInterval:TRANSITION_INTERVAL target:self
                                                                 selector:@selector(proceedTransition:)
                                                                 userInfo:nil repeats:YES];
        }
    }else{
        [_timerForTransition invalidate];
        _timerForTransition = nil;
    }
}

- (void) proceedTransition:(NSTimer*)timer
{
    TransitionEffect* effect = _slideshowConfig.transitionEffect;
    [_imageView moveToDirection:RelationalImageNext withTransition:effect];
    double interval = TRANSITION_INTERVAL + effect.dulation;
    if (![_preferencesView.window isBelongToResponderChain:_focusingField]){
        [_timerForTransition invalidate];
        _timerForTransition = nil;
    }else if (_timerForTransition.timeInterval != interval){
        [_timerForTransition invalidate];
        _timerForTransition = [NSTimer scheduledTimerWithTimeInterval:interval target:self
                                                             selector:@selector(proceedTransition:)
                                                             userInfo:nil repeats:YES];
    }
}

- (void)didEndTransition:(NSNumber*)isNext
{
    RelationalImageForSample* next = ((RelationalImageForSample*)_imageView.relationalImage).nextImageNode;
    _imageView.relationalImage = next;
}

@end
