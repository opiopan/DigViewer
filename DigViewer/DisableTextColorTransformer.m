//
//  DisableTextColorTransformer.m
//  DigViewer
//
//  Created by opiopan on 2015/07/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DisableTextColorTransformer : NSValueTransformer

@end

@implementation DisableTextColorTransformer

+ (Class)transformedValueClass
{
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if ([value boolValue]){
        return [NSColor controlTextColor];
    }else{
        return [NSColor disabledControlTextColor];
    }
}

@end
