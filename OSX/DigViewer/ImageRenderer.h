//
//  ImageRenderer.h
//  DigViewer
//
//  Created by opiopan on 2015/06/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageRenderer : NSObject

@property (readonly, nonatomic) NSString* imagePath;
@property (readonly, nonatomic) BOOL isPhotosLibraryImage;
@property (readonly, nonatomic) id image;
@property (readonly, nonatomic) NSInteger rotation;

+ (id) imageRendererWithPath:(NSString*)imagePath isPhotosLibraryImage:(BOOL)isPhotosLibraryImage;

@end
