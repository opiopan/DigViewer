//
//  DVRemoteClient.h
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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
@property (readonly) NSDictionary* templateMeta;
@property (readonly) UIImage* thumbnail;
@property (readonly) NSInteger imageRotation;

+ (DVRemoteClient*)sharedClient;

- (void)addClientDelegate:(id <DVRemoteClientDelegate>)delegate;
- (void)removeClientDelegate:(id <DVRemoteClientDelegate>)delegate;

- (void)connectToServer:(NSNetService*)service;
- (void)reconnect;
- (void)disconnect;

- (void)moveToNextImage;
- (void)moveToPreviousImage;

- (UIImage*)fullImageForID:(NSArray*)nodeID inDocument:(NSString*)document withMaxSize:(CGFloat)maxSize;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteClientDelegate <NSObject>
@optional
- (void)dvrClient:(DVRemoteClient*)client changeState:(DVRClientState)state;
- (void)dvrClient:(DVRemoteClient*)client didRecieveMeta:(NSDictionary*)meta;
- (void)dvrClient:(DVRemoteClient*)client didRecieveCurrentThumbnail:(UIImage*)thumbnail;
- (void)dvrClient:(DVRemoteClient*)client didRecieveFullImage:(UIImage*)image
             ofId:(NSArray*)nodeId inDocument:(NSString*)documentName withRotation:(NSInteger)rotation;
@end