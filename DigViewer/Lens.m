//
//  Lens.m
//  DigViewer
//
//  Created by opiopan on 2015/07/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "Lens.h"
#import "Camera.h"
#import "Condition.h"


@implementation Lens

@dynamic apertureMax;
@dynamic apertureMin;
@dynamic focalLengthRatio35;
@dynamic focalLengthMax;
@dynamic focalLengthMin;
@dynamic fovMax;
@dynamic fovMin;
@dynamic lensMake;
@dynamic lensName;
@dynamic matchingType;
@dynamic name;
@dynamic sensorHorizontal;
@dynamic sensorVertical;
@dynamic allowedCameras;
@dynamic condition;


//-----------------------------------------------------------------------------------------
// プロファイル適用可否判定
//-----------------------------------------------------------------------------------------
- (BOOL)matchConditionWithProperties:(LLMatchingProperties *)properties
{
    BOOL rc = NO;
    switch (self.matchingType.intValue){
        case LENS_MATCHING_BY_LENSNAME:
            rc = properties.lensModel && [properties.lensModel isEqualToString:self.lensName];
            break;
        case LENS_MATCHING_BY_LENSNAME_AND_CAMERANAME:
            if (properties.lensModel && [properties.lensModel isEqualToString:self.lensName]){
                for (Camera* camera in self.allowedCameras){
                    rc = rc || [camera.name isEqualToString:properties.cameraModel];
                    if (rc){
                        break;
                    }
                }
            }
            break;
        case LENS_MATCHING_BY_CUSTOM_CONDITION:
            rc = [self.condition matchConditionWithProperties:properties];
            break;
    }
    
    return rc;
}

@end
