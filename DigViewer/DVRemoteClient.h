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

typedef NS_ENUM(NSUInteger, DVRClientState){
    DVRClientDisconnected,
    DVRClientConnecting,
    DVRClientAuthenticating,
    DVRClientConnected
};

//-----------------------------------------------------------------------------------------
// DVRemoteClient宣言
//-----------------------------------------------------------------------------------------
@interface DVRemoteClient : NSObject <NSNetServiceDelegate, DVRemoteSessionDelegate>

@property (weak, nonatomic) NSRunLoop* runLoop;
@property (readonly) DVRClientState state;
@property (readonly) NSString* stateString;
@property (readonly) NSNetService* service;
@property (readonly) NSInteger reconectCount;
@property (readonly) NSDictionary* meta;

+ (DVRemoteClient*)sharedClient;

- (void)addClientDelegate:(id <DVRemoteClientDelegate>)delegate;
- (void)removeClientDelegate:(id <DVRemoteClientDelegate>)delegate;

- (void)connectToServer:(NSNetService*)service;
- (void)reconnect;
- (void)disconnect;

- (void)moveToNextImage;
- (void)moveToPreviousImage;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteClientDelegate <NSObject>
- (void)dvrClient:(DVRemoteClient*)client changeState:(DVRClientState)state;
- (void)dvrClient:(DVRemoteClient*)client didRecieveMeta:(NSDictionary*)meta;
@end