//
//  NSObject+MenuItemValidator.m
//  DigViewer
//
//  Created by opiopan on 2014/02/14.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "NSObject+MenuItemValidator.h"

@implementation NSObject (MenuItemValidator)

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    NSString* actionName = NSStringFromSelector(menuItem.action);
    NSString* validatorName = [NSString stringWithFormat:@"validateFor%c%@",
                               (int)[[actionName capitalizedString] characterAtIndex:0],
                               [actionName substringFromIndex:1]];
    SEL validator = NSSelectorFromString(validatorName);
    BOOL rc = YES;
    if ([self respondsToSelector:validator]){
        NSMethodSignature* sig = [self methodSignatureForSelector:validator];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.target = self;
        invocation.selector = validator;
        [invocation setArgument:&menuItem atIndex:2];
        [invocation invoke];
        [invocation getReturnValue:&rc];
    }
    return rc;
}

@end
