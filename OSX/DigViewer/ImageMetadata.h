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
#endif
#import "LensLibrary.h"
#import "ImageMetadataKV.h"

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