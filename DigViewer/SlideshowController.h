//
//  SlideshowController.h
//  DigViewer
//
//  Created by opiopan on 2015/06/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RelationalImageAccessor.h"

@interface SlideshowController : NSWindowController

@property (weak, nonatomic) id delegate;
@property (nonatomic) SEL didEndSelector;
@property (nonatomic) RelationalImageAccessor* imageAccessor;

+ (SlideshowController*)newController;
+ (SlideshowController*)currentController;

- (BOOL)shouldHideCursor;
- (NSScreen*)targetScreenWithCurrentScreen:(NSScreen*)currentScreen;
- (void)startSlideshowWithScreen:(NSScreen*)screen
                 relationalImage:(id)relationalImage
                targetController:(NSViewController*)controller;
- (void)cancelSlideshow;

@end
