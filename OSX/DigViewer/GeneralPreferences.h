//
//  GeneralPreferences.h
//  DigViewer
//
//  Created by opiopan on 2015/04/11.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferencesModule.h"
#import "DocumentConfigController.h"
#import "SlideshowConfigController.h"
#import "ImageViewConfigController.h"


@interface GeneralPreferences : NSPreferencesModule

@property (strong, nonatomic) DocumentConfigController* documentConfigController;
@property (strong, nonatomic) SlideshowConfigController* slideshowConfigController;
@property (strong, nonatomic) ImageViewConfigController* imageViewConfigController;

@end
