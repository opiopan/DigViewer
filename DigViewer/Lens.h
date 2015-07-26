//
//  Lens.h
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

enum LensMatchingTypeValue{
    LENS_MATCHING_BY_LENSNAME = 0,
    LENS_MATCHING_BY_LENSNAME_AND_CAMERANAME,
    LENS_MATCHING_BY_CUSTOM_CONDITION
};

@class Camera, Condition;

@interface Lens : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * lensName;
@property (nonatomic, retain) NSString * lensMake;
@property (nonatomic, retain) NSNumber * apertureMin;
@property (nonatomic, retain) NSNumber * apertureMax;
@property (nonatomic, retain) NSNumber * focalLengthMin;
@property (nonatomic, retain) NSNumber * focalLengthMax;
@property (nonatomic, retain) NSNumber * focalLengthRatio35;
@property (nonatomic, retain) NSNumber * fovMin;
@property (nonatomic, retain) NSNumber * fovMax;
@property (nonatomic, retain) NSNumber * sensorHorizontal;
@property (nonatomic, retain) NSNumber * sensorVertical;
@property (nonatomic, retain) NSNumber * matchingType;
@property (nonatomic, retain) NSSet *allowedCameras;
@property (nonatomic, retain) Condition *condition;
@end

@interface Lens (CoreDataGeneratedAccessors)

- (void)addAllowedCamerasObject:(Camera *)value;
- (void)removeAllowedCamerasObject:(Camera *)value;
- (void)addAllowedCameras:(NSSet *)values;
- (void)removeAllowedCameras:(NSSet *)values;

@end
