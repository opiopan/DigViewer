//
//  ImageMetadata.h
//  DigViewer
//
//  Created by opiopan on 2014/02/18.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#if ! TARGET_OS_IPHONE
#import "PathNode.h"
#import "LensLibrary.h"
#endif
#import "ImageMetadataKV.h"

#if TARGET_OS_IPHONE
@interface Lens : NSObject
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
@property (nonatomic, readonly) NSString* lensSpecString;
@property (nonatomic, readonly) NSString* matchingRuleString;
@end
#endif

@interface GPSInfo : NSObject
@property NSNumber* latitude;
@property NSNumber* longitude;
@property NSNumber* altitude;
@property NSNumber* imageDirection;
@property NSString* imageDirectionKind;
@property NSNumber* heading;
@property NSString* headingKind;
@property NSNumber* velocity;
@property NSString* velocityUnit;
@property NSString* dateTime;
@property NSString* measureMode;
@property NSString* geodeticReferenceSystem;
@property NSNumber* focalLengthIn35mm;
@property NSNumber* rotation;
@property NSNumber* fovLong;
@property NSNumber* fovShort;
@end

@interface ImageMetadata : NSObject

@property (readonly) NSArray* summary;
@property (readonly) GPSInfo* gpsInfo;
@property (readonly) NSArray* gpsInfoStrings;

#if ! TARGET_OS_IPHONE
- (id)initWithPathNode:(PathNode*)pathNode;
#endif
- (id)initWithImage:(CGImageSourceRef)imageSource name:(NSString *)name typeName:(NSString*)typeName;
- (NSArray*)summaryWithFilter:(NSArray*)filter;
- (NSDictionary*)propertiesAtIndex:(int)index;
- (Lens*)associatedLensProfile;
@end

#if ! TARGET_OS_IPHONE
extern NSString* dateTimeOfImage(PathNode* pathNode);
#endif