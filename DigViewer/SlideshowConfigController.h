//
//  SlideshowConfigController.h
//  DigViewer
//
//  Created by opiopan on 2015/05/08.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SlideshowConfigController : NSObject

@property (strong, nonatomic) NSNumber* interval;
@property (assign, readonly, nonatomic) NSInteger updateCount;

+ (SlideshowConfigController*)sharedController;

@end
