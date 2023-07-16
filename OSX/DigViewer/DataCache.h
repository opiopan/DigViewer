//
//  DataCache.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/07/15.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DataCacheCompletion)(NSData* data, NSString* uti);

@interface DataCache : NSObject
- (void) getNSdataOf:(NSString*)localIdentifier completion:(DataCacheCompletion)completion;
@end
