//
//  DVRemoteServer.m
//  DigViewer
//
//  Created by opiopan on 2015/09/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteServer.h"

@implementation DVRemoteServer{
    BOOL _publishingFailed;
    NSNetService* _service;
    
    NSMutableArray* _authorizedSessions;
    
    NSData* _currentMeta;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (DVRemoteServer *)sharedServer
{
    static DVRemoteServer* sharedServer = nil;
    
    if (!sharedServer){
        sharedServer = [DVRemoteServer new];
    }
    
    return sharedServer;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _publishingFailed = NO;
        _authorizedSessions = [NSMutableArray array];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// サーバ起動
//-----------------------------------------------------------------------------------------
- (BOOL)establishServer
{
    NSString* name = [NSString stringWithFormat:@"%@@%@",  NSUserName(), [NSHost currentHost].localizedName];
    _service = [[NSNetService alloc] initWithDomain:@"" type:DVR_SERVICE_TYPE name:name port:0];
    if (_service){
        _service.delegate = self;
        if (!_runLoop){
            _runLoop = [NSRunLoop currentRunLoop];
        }
        [_service scheduleInRunLoop:_runLoop forMode:NSRunLoopCommonModes];
        [_service publishWithOptions:NSNetServiceListenForConnections];
    }
    
    return !_publishingFailed;
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    _publishingFailed = YES;
}

//-----------------------------------------------------------------------------------------
// クライアントからの接続をaccept
//-----------------------------------------------------------------------------------------
- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream
      outputStream:(NSOutputStream *)outputStream
{
    DVRemoteSession* session = [[DVRemoteSession alloc] initWithInputStream:inputStream outputStream:outputStream];
    [_authorizedSessions addObject:session];
    session.delegate = self;
    [session scheduleInRunLoop:_runLoop];
    if (_currentMeta){
        [session sendCommand:DVRC_NOTIFY_META withData:_currentMeta replacingQue:YES];
    }
}


//-----------------------------------------------------------------------------------------
// クライアントセッションからのイベント処理
//-----------------------------------------------------------------------------------------
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data
{
    if (command == DVRC_MOVE_PREV_IMAGE || DVRC_MOVE_NEXT_IMAGE){
        NSString* document = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate){
            [_delegate dvrServer:self needMoveToNeighborImageOfDocument:document withDirection:command];
        }
    }
}

- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error
{
    [session close];
    [_authorizedSessions removeObject:session];
}

//-----------------------------------------------------------------------------------------
// メタデータ送信
//-----------------------------------------------------------------------------------------
- (void)sendMeta:(NSDictionary *)meta
{
    _currentMeta = [NSKeyedArchiver archivedDataWithRootObject:meta];
    for (DVRemoteSession* session in _authorizedSessions){
        [session sendCommand:DVRC_NOTIFY_META withData:_currentMeta replacingQue:YES];
    }
}

@end
