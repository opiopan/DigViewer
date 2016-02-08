//
//  ImageRepository.h
//  DigViewer
//
//  Created by opiopan on 2015/08/14.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageRepository : NSObject

@property (nonatomic, readonly) NSImage* iconBrowser;
@property (nonatomic, readonly) NSImage* iconMaps;
@property (nonatomic, readonly) NSImage* iconGoogleEarth;

+ (ImageRepository*)sharedImageRepository;

@end
