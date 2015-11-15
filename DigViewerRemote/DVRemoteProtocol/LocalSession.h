//
//  LocalSession.h
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/11.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteSession.h"

@interface LocalSession : NSObject

@property (weak) id <DVRemoteSessionDelegate> delegate;

- (void)connect;

- (UIImage*)thumbnailForID: (NSArray*)nodeID;
- (UIImage*)fullImageForID: (NSArray*)nodeID;

- (void)moveNextAsset;
- (void)movePreviousAsset;
- (void)moveToAssetWithID: (NSArray*)nodeID;

- (NSArray *)nodeListForID:(NSArray *)nodeID;

@end