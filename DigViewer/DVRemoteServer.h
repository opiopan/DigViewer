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
- (void)sendMeta:(NSDictionary*)meta;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteServerDelegate <NSObject>
@end

