//
//  ThumbnailConfigController.h
//  DigViewer
//
//  Created by opiopan on 2015/04/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThumbnailConfigController : NSObject

@property (weak, nonatomic) id delegate;

@property (strong, nonatomic) NSNumber* updateCount;

@property (strong, nonatomic) NSNumber* defaultSize;
@property (assign, nonatomic) BOOL isVisibleFolderIcon;
@property (strong, nonatomic) NSNumber* folderIconSize;
@property (strong, nonatomic) NSNumber* folderIconSizeRepresentation;
@property (strong, nonatomic) NSNumber* folderIconOpacity;
@property (strong, nonatomic) NSNumber* folderIconOpacityRepresentation;

+ (id) sharedController;

- (void) loadDefaults;
- (void) resetDefaults;

@end
