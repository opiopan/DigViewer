//
//  MacProductName.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/07/25.
//  Copyright © 2023 opiopan@gmail.com <Hiroshi Murayama>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacProductName : NSObject
+ (NSString*) productNameOfIdentifier: (NSString*)identifier;
@end
