//
//  ImageMetadataKV.m
//  DigViewer
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ImageMetadataKV.h"

//-----------------------------------------------------------------------------------------
// NSArrayController向けKey Value Store
//-----------------------------------------------------------------------------------------
@implementation ImageMetadataKV

+ (id)kvWithKey:(NSString *)key value:(NSString *)value
{
    ImageMetadataKV* kv = [[ImageMetadataKV alloc] init];
    if (kv){
        kv.key = key;
        kv.value = value;
    }
    return kv;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self){
        _key = [aDecoder decodeObjectForKey:@"key"];
        _value = [aDecoder decodeObjectForKey:@"value"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_key forKey:@"key"];
    [aCoder encodeObject:_value forKey:@"value"];
}

@end
