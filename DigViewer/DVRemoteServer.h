//
//  DVRemoteServer.h
//  DigViewer
//
//  Created by opiopan on 2015/09/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteProtcol.h"
#import "DVRemoteSession.h"

@protocol DVRemoteServerDelegate;

//-----------------------------------------------------------------------------------------
// DVRemoteServer宣言
//-----------------------------------------------------------------------------------------
@interface DVRemoteServer : NSObject <NSNetServiceDelegate, DVRemoteSessionDelegate>

@property (weak, nonatomic) id <DVRemoteServerDelegate> delegate;
@property (strong, nonatomic) NSRunLoop* runLoop;

+ (DVRemoteServer*)sharedServer;

- (BOOL)establishServer;
- (void)discardSession:(DVRemoteSession*)session;

- (void)sendMeta:(NSDictionary*)meta;
- (void)sendThumbnail:(NSData*)thumbnail forNodeID:(NSArray*)nodeID inDocument:(NSString*)documentName
            withIndex:(NSInteger)index;
- (void)sendFullimage:(NSData*)fullimage forNodeID:(NSArray*)nodeID inDocument:(NSString*)documentName
         withRotation:(NSInteger)rotation;
- (void)sendFolderItems:(NSArray*)items forNodeID:(NSArray*)nodeID inDocument:(NSString*)documentName
              bySession:(DVRemoteSession*)session;
- (void)sendServerInfo:(NSDictionary*)serverInfo bySession:(DVRemoteSession*)session;
- (void)sendPairingKey:(NSDictionary*)args bySession:(DVRemoteSession*)session;
- (void)completeAuthenticationAsResult:(BOOL)succeeded ofSession:(DVRemoteSession*)session;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteServerDelegate <NSObject>
- (void)dvrServer:(DVRemoteServer*)server needMoveToNeighborImageOfDocument:(NSString*)document
    withDirection:(DVRCommand)direction;
- (void)dvrServer:(DVRemoteServer*)server needSendThumbnail:(NSArray*)id forDocument:(NSString*)document;
@optional
- (void)dvrServer:(DVRemoteServer*)server needMoveToNode:(NSArray*)nodeID inDocument:(NSString*)documentName;
- (void)dvrServer:(DVRemoteServer*)server needSendFullimage:(NSArray*)nodeId forDocument:(NSString*)document
         withSize:(CGFloat)maxSize;
- (void)dvrServer:(DVRemoteServer*)server needSendFolderItms:(NSArray*)nodeId forDocument:(NSString*)document
        bySession:(DVRemoteSession*)session;
- (void)dvrServer:(DVRemoteServer*)server needSendServerInfoToClient:(DVRemoteSession*)session;
- (void)dvrServer:(DVRemoteServer*)server needPairingForClient:(DVRemoteSession*)session withAttributes:(NSDictionary*)attrs;
- (void)dvrServer:(DVRemoteServer*)server needAuthenticateClient:(DVRemoteSession*)session withAttributes:(NSDictionary*)attrs;
@end

