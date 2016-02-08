//
//  ImageViewConfigController.h
//  DigViewer
//
//  Created by opiopan on 2015/06/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

enum _ImageViewFilterType{
    ImageViewFilterNone = 0,
    ImageViewFilterBilinear = 1,
    ImageViewFilterTrilinear = 2
};
typedef enum _ImageViewFilterType ImageViewFilterType;

@interface ImageViewConfigController : NSObject

@property (nonatomic) NSInteger updateCount;
@property (nonatomic) NSColor* backgroundColor;
@property (nonatomic) ImageViewFilterType magnificationFilter;
@property (nonatomic) ImageViewFilterType minificationFilter;
@property (nonatomic) BOOL useEmbeddedThumbnailRAW;

+ (id) sharedController;

@end
