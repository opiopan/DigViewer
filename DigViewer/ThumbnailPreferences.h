//
//  ThumbnailPreferences.h
//  DigViewer
//
//  Created by opiopan on 2015/05/09.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferencesModule.h"
#import "ThumbnailConfigController.h"
#import "ThumbnailSampleView.h"

@interface ThumbnailPreferences : NSPreferencesModule

@property (weak) IBOutlet ThumbnailSampleView *thumbnailSampleView;
@property (weak, nonatomic) ThumbnailConfigController* thumbnailConfig;
@property (strong, nonatomic) NSNumber* thumbnailSampleType;

@end
