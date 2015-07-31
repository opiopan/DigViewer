//
//  ConditionMigrationPolicy2.0-2.m
//  DigViewer
//
//  Created by opiopan on 2015/07/31.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "ConditionMigrationPolicy2.1-2.2.h"

@implementation ConditionMigrationPolicy2_1_2_2

- (NSNumber*) counter
{
    static long count = 1;
    return @(count++);
}

@end
