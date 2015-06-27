//
//  EditCustomEffectController.h
//  DigViewer
//
//  Created by opiopan on 2015/06/27.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlideshowConfigController.h"

@interface EditCustomEffectController : NSObject <NSWindowDelegate>

@property (strong) IBOutlet NSPanel *panel;

@property (nonatomic) NSString* name;
@property (nonatomic) CGFloat duration;
@property (nonatomic) NSString* path;
@property (nonatomic) EffectType type;
@property (nonatomic) NSString* typeString;

@property (nonatomic) BOOL isChanged;
@property (readonly, nonatomic) BOOL enableOKButton;

- (void) editEffectForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector;

@end
