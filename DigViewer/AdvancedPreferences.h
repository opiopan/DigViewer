//
//  AdvancedPreferences.h
//  DigViewer
//
//  Created by opiopan on 4/12/15.
//  Copyright (c) 2015 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPreferencesModule.h"
#import "ThumbnailConfigController.h"
#import "ThumbnailSampleView.h"

@interface AdvancedPreferences : NSPreferencesModule

@property (weak) IBOutlet ThumbnailSampleView *thumbnailSampleView;
@property (weak, nonatomic) ThumbnailConfigController* thumbnailConfig;
@property (strong, nonatomic) NSNumber* thumbnailSampleType;

@end
