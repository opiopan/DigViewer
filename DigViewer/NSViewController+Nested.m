//
//  NSViewController+Nested.m
//  DigViewer
//
//  Created by opiopan on 2013/01/13.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "NSViewController+Nested.h"

@implementation NSViewController (Nested)

- (NSView*) representationView;
{
    return self.view;
}

- (void) setIsVisible:(BOOL)visible
{
}

- (void) prepareForClose
{
}

- (NSDictionary *)preferences
{
    return @{};
}

- (void)setPreferences:(NSDictionary *)preferences
{
}

@end
