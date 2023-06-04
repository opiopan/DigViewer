//
//  ThumbnailCache.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/28.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThumbnailCache : NSObject
+ (CGImageRef) getThumbnailImageOf:(id)node size:(CGFloat)size;
- (CGImageRef) getThumbnailImageOf:(id)node completion:(void (^)(__weak id)) completion;
- (void) clearWaitingQueue;
@end

NS_ASSUME_NONNULL_END
