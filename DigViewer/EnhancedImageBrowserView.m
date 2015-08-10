//
//  EnhancedImageBrowserView.m
//  DigViewer
//
//  Created by opiopan on 2015/08/10.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EnhancedImageBrowserView.h"

@implementation EnhancedImageBrowserView

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(cut:) || menuItem.action == @selector(paste:)){
        return NO;
    }else{
        return [super validateMenuItem:menuItem];
    }
}

@end
