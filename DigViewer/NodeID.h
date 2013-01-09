//
//  NodeID.h
//  DigViewer
//
//  Created by opiopan on 2013/01/08.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NodeID : NSObject <NSCopying>

@property (readonly) NSImage*  image;
@property (readonly) NSString* name;

- (id) initWithName: (NSString*)n image:(NSImage*)i;


@end
