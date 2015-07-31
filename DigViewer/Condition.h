//
//  Condition.h
//  DigViewer
//
//  Created by opiopan on 2015/07/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Condition, Lens;

enum LFCONDITION_TYPE{
    LFCONDITION_TYPE_AND = 0,
    LFCONDITION_TYPE_OR,
    LFCONDITION_TYPE_NAND,
    LFCONDITION_TYPE_NOR,
    LFCONDITION_TYPE_COMPARISON
};

enum LFCONDITION_TARGET{
    LFCONDITION_TARGET_CAMERA_MAKE = 0,
    LFCONDITION_TARGET_CAMERA_NAME,
    LFCONDITION_TARGET_LENS_MAKE,
    LFCONDITION_TARGET_LENS_NAME,
    LFCONDITION_TARGET_FOCAL_LENGTH,
    LFCONDITION_TARGET_FOCAL_LENGTH35,
    LFCONDITION_TARGET_APERTURE
};

enum LFCONDITION_OP{
    LFCONDITION_OP_EQ = 0,
    LFCONDITION_OP_NE,
    LFCONDITION_OP_GT,
    LFCONDITION_OP_GE,
    LFCONDITION_OP_LT,
    LFCONDITION_OP_LE,
    LFCONDITION_OP_LEFTHAND_MATCH,
    LFCONDITION_OP_RIGHTHAND_MATCH,
    LFCONDITION_OP_PARTIAL_MATCH,
    LFCONDITION_OP_IS_NULL
};

@interface LLMatchingProperties : NSObject
@property NSString* cameraMake;
@property NSString* cameraModel;
@property NSString* lensMake;
@property NSString* lensModel;
@property NSNumber* focalLength;
@property NSNumber* focalLength35;
@property NSNumber* aperture;
@end

@interface Condition : NSManagedObject

@property (nonatomic, retain) NSNumber * conditionType;
@property (nonatomic, retain) NSNumber * operatorType;
@property (nonatomic, retain) NSNumber * target;
@property (nonatomic, retain) NSNumber * valueDouble;
@property (nonatomic, retain) NSString * valueString;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) Lens *lens;
@property (nonatomic, retain) Condition *parent;

@property (nonatomic, readonly) Condition* me;
@property (nonatomic, readonly) NSString* summary;
@property (nonatomic, readonly) NSImage* icon;
@property (nonatomic, readonly) NSDictionary* package;

@end

@interface Condition (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(Condition *)value;
- (void)removeChildrenObject:(Condition *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

- (void)updateProperties;
- (BOOL)matchConditionWithProperties:(LLMatchingProperties*)properties;
- (NSInteger)maxChildOrder;
- (void)shiftChildOrder:(NSInteger)amount forChildGraterThan:(NSInteger)order;

+ (BOOL)targetIsString:(enum LFCONDITION_TARGET)target;
+ (NSString*)stringForTarget:(enum LFCONDITION_TARGET)target;
+ (NSString*)stringForOperator:(enum LFCONDITION_OP)op;

@end
