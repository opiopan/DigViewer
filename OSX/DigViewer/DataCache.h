//
//  DataCache.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/07/15.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#pragma once

typedef void (^DataCacheCompletion)(NSData*);

@interface DataCache : NSObject
- (void) getNSdataOf:(NSString*)localIdentifier completion:(DataCacheCompletion)completion;
@end
