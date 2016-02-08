//
//  RenderingPreferences.h
//  DigViewer
//
//  Created by opiopan on 2015/06/03.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "NSPreferencesModule.h"
#import "ThumbnailConfigController.h"
#import "ImageViewConfigController.h"

@interface RenderingPreferences : NSPreferencesModule

@property (weak, nonatomic) ThumbnailConfigController* thumbnailConfig;
@property (weak, nonatomic) ImageViewConfigController* imageViewConfig;

@end
