//
//  DVRemoteSession.h
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteProtcol.h"

@protocol DVRemoteSessionDelegate;

//-----------------------------------------------------------------------------------------
// DVRemoteStream宣言
//-----------------------------------------------------------------------------------------
@interface DVRemoteSession : NSObject <NSStreamDelegate>

@property (weak, nonatomic) id <DVRemoteSessionDelegate> delegate;

- (id)initWithInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream;
- (void)scheduleInRunLoop:(NSRunLoop*)runLoop;
- (void)close;
- (void)sendCommand:(DVRCommand)command withData:(NSData*)data replacingQue:(BOOL)isReplacingQue;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteSessionDelegate <NSObject>
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data;
- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error;
@end