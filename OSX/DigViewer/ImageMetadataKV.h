//
//  ImageMetadataKV.h
//  DigViewer
//
//  Created by opiopan on 2015/09/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageMetadataKV : NSObject <NSCoding>
@property NSString* key;
@property NSString* value;
@property NSString* remark;

+ (id)kvWithKey:(NSString*)key value:(NSString*)value;

@end
