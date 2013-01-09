//
//  NodeID.m
//  DigViewer
//
//  Created by opiopan on 2013/01/08.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "NodeID.h"

@implementation NodeID

@synthesize image;
@synthesize name;

- (id) initWithName: (NSString*)n image:(NSImage*)i
{
    self = [super init];
    if (self){
        name = n;
        image = i;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithName:name image:image];
}

@end
