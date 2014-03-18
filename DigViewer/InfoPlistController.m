//
//  InfoPlistController.m
//  DigViewer
//
//  Created by opiopan on 2014/03/18.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "InfoPlistController.h"

@implementation InfoPlistController

- (NSString*)version
{
    NSDictionary* infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [infoPlist valueForKey:@"CFBundleShortVersionString"];
    NSString* build = [infoPlist valueForKey:@"OPBuildVersion"];
    return [NSString stringWithFormat:@"Version %@ (%@)", version, build];
}

- (NSString*)copyright
{
    NSDictionary* infoPlist = [[NSBundle mainBundle] infoDictionary];
    return [infoPlist valueForKey:@"NSHumanReadableCopyright"];
}

- (NSString*)caution
{
    NSDictionary* infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSArray* cautions = [infoPlist valueForKey:@"OPCaution"];
    if (cautions.count > 0){
        NSMutableString* cautionString = [[NSMutableString alloc] initWithString:cautions[0]];
        for (int i = 1; i < cautions.count; i++){
            [cautionString appendFormat:i + 1 == cautions.count ? @", and %@" : @", %@", cautions[i]];
        }
        return [NSString stringWithFormat:@"Caution:\nThis is NOT OFFICIAL BUILD that is %@.", cautionString];
    }else{
        return nil;
    }
}

@end
