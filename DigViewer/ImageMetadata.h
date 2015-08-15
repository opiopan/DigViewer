//
//  ImageMetadata.h
//  DigViewer
//
//  Created by opiopan on 2014/02/18.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PathNode.h"
#import "LensLibrary.h"

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

- (id)initWithPathNode:(PathNode*)pathNode;
- (NSArray*)summaryWithFilter:(NSArray*)filter;
- (NSDictionary*)propertiesAtIndex:(int)index;
- (Lens*)associatedLensProfile;

@end

@interface ImageMetadataKV : NSObject
@property NSString* key;
@property NSString* value;

+ (id)kvWithKey:(NSString*)key value:(NSString*)value;

@end

extern NSString* dateTimeOfImage(PathNode* pathNode);