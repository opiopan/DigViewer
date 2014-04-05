//
//  ImageMetadata.h
//  DigViewer
//
//  Created by opiopan on 2014/02/18.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PathNode.h"

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
@end

@interface ImageMetadata : NSObject

@property (readonly) NSArray* summary;
@property (readonly) GPSInfo* gpsInfo;
@property (readonly) NSArray* gpsInfoStrings;

- (id)initWithPathNode:(PathNode*)pathNode;
- (NSDictionary*)propertiesAtIndex:(int)index;

@end

@interface ImageMetadataKV : NSObject
@property NSString* key;
@property NSString* value;

+ (id)kvWithKey:(NSString*)key value:(NSString*)value;

@end