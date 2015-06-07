//
//  RelationalImageAccessor.h
//  DigViewer
//
//  Created by opiopan on 2015/06/07.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RelationalImageAccessor : NSObject

@property (nonatomic) SEL imagePathGetter;
@property (nonatomic) SEL nextObjectGetter;
@property (nonatomic) SEL previousObjectGetter;

- (NSString*)imagePathOfObject:(id)object;
- (id)nextObjectOfObject:(id)object;
- (id)previousObjectOfObject:(id)object;

@end
