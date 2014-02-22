//
//  ImageMetadata.h
//  DigViewer
//
//  Created by opiopan on 2014/02/18.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PathNode.h"

@interface ImageMetadata : NSObject

@property (readonly) NSArray* summary;

- (id)initWithPathNode:(PathNode*)pathNode;
- (NSDictionary*)propertiesAtIndex:(int)index;

@end

@interface ImageMetadataKV : NSObject
@property NSString* key;
@property NSString* value;

+ (id)kvWithKey:(NSString*)key value:(NSString*)value;

@end