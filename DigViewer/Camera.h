//
//  Camera.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2015/07/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Lens;

@interface Camera : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Lens *lens;

@end
