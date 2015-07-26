//
//  Condition.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2015/07/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Condition, Lens;

@interface Condition : NSManagedObject

@property (nonatomic, retain) NSNumber * conditionType;
@property (nonatomic, retain) NSNumber * operator;
@property (nonatomic, retain) NSNumber * target;
@property (nonatomic, retain) NSNumber * valueDouble;
@property (nonatomic, retain) NSString * valueString;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) Lens *lens;
@property (nonatomic, retain) Condition *parent;
@end

@interface Condition (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(Condition *)value;
- (void)removeChildrenObject:(Condition *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
