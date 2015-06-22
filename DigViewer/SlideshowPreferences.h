//
//  SlideshowPreferences.h
//  DigViewer
//
//  Created by opiopan on 2015/06/03.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "NSPreferencesModule.h"
#import "SlideshowConfigController.h"

@interface SlideshowPreferences : NSPreferencesModule  <NSTextFieldDelegate>

@property (readonly) SlideshowConfigController* slideshowConfig;

@end
