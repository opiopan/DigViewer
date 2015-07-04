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
#import "EditCustomEffectListController.h"

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
    NSString* _effectType;
    TransitionEffect* _effect;
    EditCustomEffectListController* _editCustomEffectListPanel;
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
    _effectType = _slideshowConfig.transition;
    _effect = _slideshowConfig.transitionEffect;
}

//-----------------------------------------------------------------------------------------
// シートのアピアランス設定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

//-----------------------------------------------------------------------------------------
// エフェクトの選択index属性
//-----------------------------------------------------------------------------------------
- (NSInteger)selectionIndexForEffect
{
    NSArray* effects = _slideshowConfig.allEffects;
    for (NSInteger i = 0; i < effects.count; i++){
        if ([[effects[i] valueForKey:@"identifier"] isEqualToString:_slideshowConfig.transition]){
            return i;
        }
    }
    return NSNotFound;
}

- (void)setSelectionIndexForEffect:(NSInteger)selectionIndexForEffect
{
    NSArray* effects = _slideshowConfig.allEffects;
    if (selectionIndexForEffect >= 0 && selectionIndexForEffect < effects.count){
        _slideshowConfig.transition = [effects[selectionIndexForEffect] valueForKey:@"identifier"];
    }
}

//-----------------------------------------------------------------------------------------
// カスタムエフェクト編集
//-----------------------------------------------------------------------------------------
- (IBAction) editCustomEffectList:(id)sender
{
    _editCustomEffectListPanel = [EditCustomEffectListController new];
    [_editCustomEffectListPanel editEffectList:_slideshowConfig.customEffects forWindow:_preferencesView.window
                                 modalDelegate:self didEndSelector:@selector(didEndEditCustomEffectListSheet:)];
}

- (void)didEndEditCustomEffectListSheet:(id)object
{
    if (object){
        NSString* transition = _slideshowConfig.transition;
        _slideshowConfig.customEffects = object;
        if (![transition isEqualToString:_slideshowConfig.transition]){
            [self willChangeValueForKey:@"selectionIndexForEffect"];
            [self didChangeValueForKey:@"selectionIndexForEffect"];
        }
        _effectType = @"";
    }
    _editCustomEffectListPanel = nil;
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
                                                                 userInfo:nil repeats:NO];
        }
    }else{
        [_timerForTransition invalidate];
        _timerForTransition = nil;
    }
}

- (void) proceedTransition:(NSTimer*)timer
{
    if (![_effectType isEqualToString:_slideshowConfig.transition]){
        _effectType = _slideshowConfig.transition;
        _effect = _slideshowConfig.transitionEffect;
    }
    [_imageView moveToDirection:RelationalImageNext withTransition:_effect];
}

- (void)didEndTransition:(NSNumber*)isNext
{
    RelationalImageForSample* next = ((RelationalImageForSample*)_imageView.relationalImage).nextImageNode;
    _imageView.relationalImage = next;
    if (![_preferencesView.window isBelongToResponderChain:_focusingField]){
        [_timerForTransition invalidate];
        _timerForTransition = nil;
    }else{
        _timerForTransition = [NSTimer scheduledTimerWithTimeInterval:TRANSITION_INTERVAL target:self
                                                             selector:@selector(proceedTransition:)
                                                             userInfo:nil repeats:NO];
    }
}

@end
