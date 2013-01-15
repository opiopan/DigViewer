//
//  DigViewerObjectController.h
//  DigViewer
//
//  Created by opiopan on 2013/01/11.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjectControllers : NSObject
@property (weak) IBOutlet NSTreeController* imageTreeController;
@property (weak) IBOutlet NSArrayController* imageArrayController;
@property (weak) IBOutlet NSDocument* documentController;
@end
