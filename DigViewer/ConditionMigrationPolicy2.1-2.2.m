//
//  ConditionMigrationPolicy2.0-2.m
//  DigViewer
//
//  Created by opiopan on 2015/07/31.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ConditionMigrationPolicy2.1-2.2.h"

@implementation ConditionMigrationPolicy2_1_2_2

/*
- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance
                                      entityMapping:(NSEntityMapping *)mapping
                                            manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error
{
    static long count = 1;
    
    NSManagedObjectContext* context = [manager destinationContext];
    NSString *entityName = [mapping destinationEntityName];
    NSManagedObject* dInstance = [NSEntityDescription
                                  insertNewObjectForEntityForName:entityName inManagedObjectContext:context];

    [dInstance setValue:[sInstance valueForKey:@"conditionType"] forKey:@"conditionType"];
    [dInstance setValue:[sInstance valueForKey:@"operatorType"] forKey:@"operatorType"];
    [dInstance setValue:[sInstance valueForKey:@"target"] forKey:@"target"];
    [dInstance setValue:[sInstance valueForKey:@"valueDouble"] forKey:@"valueDouble"];
    [dInstance setValue:[sInstance valueForKey:@"valueString"] forKey:@"valueString"];
    [dInstance setValue:@(count++) forKey:@"order"];

    return YES;
}
 */

- (NSNumber*) counter
{
    static long count = 1;
    return @(count++);
}

@end
