//
//  DVRemoteClient.h
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
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

@property (nonatomic) BOOL isInitialized;
@property (weak) NSRunLoop* runLoop;
@property (readonly) DVRClientState state;
@property (readonly) NSString* stateString;
@property (readonly) NSNetService* service;
@property (readonly) NSString* serviceName;
@property (readonly) NSInteger reconectCount;
@property (readonly) NSDictionary* meta;
@property (readonly) NSDictionary* templateMeta;
@property (readonly) UIImage* thumbnail;
@property (readonly) NSInteger imageRotation;
@property (readonly) BOOL isConnectedToLocal;

@property (weak, nonatomic) id<DVRemoteClientDelegate> tmpDelegate;

+ (DVRemoteClient*)sharedClient;
+ (DVRemoteClient*)temporaryClient;

- (void)addClientDelegate:(id <DVRemoteClientDelegate>)delegate;
- (void)removeClientDelegate:(id <DVRemoteClientDelegate>)delegate;

- (void)regeisterSharedImage:(NSURL*)url;

- (void)connectToServer:(NSNetService *)service withKey:(NSString*)key fromDevice:(NSString*)deviceCode;
- (void)connectToLocal;
- (void)reconnect;
- (void)disconnect;

- (void)moveToNextImage;
- (void)moveToPreviousImage;
- (void)moveToNode:(NSArray*)nodeID inDocument:(NSString*)documentName;

- (UIImage*)thumbnailForID:(NSArray*)nodeID inDocument:(NSString*)documen downloadIfNeed:(BOOL)downloadIfNeed;

- (UIImage*)fullImageForID:(NSArray*)nodeID inDocument:(NSString*)document withMaxSize:(CGFloat)maxSize;

- (NSArray*)nodeListForID:(NSArray*)nodeID inDocument:(NSString*)document;

- (void)requestServerInfo;

- (PHFetchResult*)assetsForID:(NSArray*)nodeID inDocument:(NSString*)document;
- (BOOL)isAssetCollection:(NSArray*)nodeID inDocument:(NSString*)document;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteClientDelegate <NSObject>
@optional
- (void)dvrClient:(DVRemoteClient*)client changeState:(DVRClientState)state;
- (void)dvrClient:(DVRemoteClient*)client didRecieveMeta:(NSDictionary*)meta;
- (void)dvrClient:(DVRemoteClient*)client didRecieveCurrentThumbnail:(UIImage*)thumbnail;
- (void)dvrClient:(DVRemoteClient*)client didRecieveThumbnail:(UIImage*)thumbnail
             ofId:(NSArray*)nodeId inDocument:(NSString*)documentName withIndex:(NSInteger)index;
- (void)dvrClient:(DVRemoteClient*)client didRecieveFullImage:(UIImage*)image
             ofId:(NSArray*)nodeId inDocument:(NSString*)documentName withRotation:(NSInteger)rotation;
- (void)dvrClient:(DVRemoteClient*)client didRecieveNodeList:(NSArray*)nodeList forNode:(NSArray*)nodeID
       inDocument:(NSString*)documentName;
- (void)dvrClient:(DVRemoteClient*)client didRecieveServerInfo:(NSDictionary*)info;

- (void)dvrClient:(DVRemoteClient*)client didRecievePairingKey:(NSString*)key forServer:(NSNetService*)service;
@end