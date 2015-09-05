//
//  DVRemoteClient.h
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteSession.h"

@protocol DVRemoteClientDelegate;

//-----------------------------------------------------------------------------------------
// DVRemoteClient宣言
//-----------------------------------------------------------------------------------------
@interface DVRemoteClient : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, DVRemoteSessionDelegate>

@property (weak, nonatomic) id <DVRemoteClientDelegate> delegate;
@property (weak, nonatomic) NSRunLoop* runLoop;

- (void)searchServers;
- (void)connectToServer:(NSNetService*)service;
- (void)disconnect;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteClientDelegate <NSObject>
- (void)dvrClient:(DVRemoteClient*)client didFindServers:(NSArray*)servers;
- (void)dvrClient:(DVRemoteClient*)client hasBeenDisconnectedByError:(NSError*)error;
- (void)dvrClient:(DVRemoteClient*)client didRecieveMeta:(NSDictionary*)meta;
@end