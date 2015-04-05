//
//  NSString+escaping.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (escaping)

+ (NSString*) escapedStringForJavascript:(NSString*)string;

@end
