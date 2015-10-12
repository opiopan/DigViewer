//
//  LRUCache.h
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/10.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRUCache : NSObject
+ (LRUCache*)cacheWithSize:(int)size;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;
@end
