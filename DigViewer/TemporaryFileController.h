//
//  TemporaryFileController.h
//  DigViewer
//
//  Created by opiopan on 2015/08/15.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TemporaryFileController : NSObject

+ (TemporaryFileController*)sharedController;

- (NSString*) allocatePathWithSuffix:(NSString*)suffix forCategory:(NSString*)category;
- (void) cleanUpForCategory:(NSString*)category;
- (void) cleanUpAllCategories;


@end
