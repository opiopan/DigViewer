//
//  DraggingSourceArrayController.h
//  DigViewer
//
//  Created by opiopan on 2015/04/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SortOmittedArrayController.h"

@interface DraggingSourceArrayController : SortOmittedArrayController

+ (void)setEnableDragging:(BOOL)enable;

@end
