//
//  Document.h
//  DigViewer
//
//  Created by opiopan on 2013/01/04.
//  Copyright (c) 2013 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PathNode.h"
#import "DVRemoteSession.h"

@interface Document : NSDocument

@property (strong) PathNode* root;
@property (nonatomic, readonly) NSDictionary* documentWindowPreferences;
@property (nonatomic, readonly) NSUInteger thumbnailCacheCounter;
@property (nonatomic, readonly) id thumnailCache;

- (void)loadDocument:(id)sender;
- (void)saveDocumentWindowPreferences:(NSDictionary*)preferences;

- (void)sendThumbnail:(NSArray*)ids;
- (void)sendFullImage:(NSArray *)nodeId withSize:(CGFloat)maxSize;
- (void)sendNodeListInFolder:(NSArray*)nodeId bySession:(DVRemoteSession*)session;

- (void)updateThumbnailCacheCounter;

@end
