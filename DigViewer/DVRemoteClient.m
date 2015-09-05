//
//  DVRemoteClient.m
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteClient.h"

@implementation DVRemoteClient{
    NSNetServiceBrowser* _browser;
    NSMutableArray* _servers;
    
    NSNetService* _serviceForSession;
    DVRemoteSession* _session;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _runLoop = [NSRunLoop currentRunLoop];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// サーバ一検索
//-----------------------------------------------------------------------------------------
- (void)searchServers
{
    if (!_browser){
        _servers = [NSMutableArray new];
        _browser = [NSNetServiceBrowser new];
        _browser.delegate = self;
        [_browser searchForServicesOfType:DVR_SERVICE_TYPE inDomain:@""];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
           didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [_servers addObject:aNetService];
    if (!moreComing){
        if (_delegate){
            [_delegate dvrClient:self didFindServers:_servers];
        }
        [_browser stop];
        _browser = nil;
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    if (_delegate){
        [_delegate dvrClient:self didFindServers:nil];
    }
    [_browser stop];
    _browser = nil;
}

//-----------------------------------------------------------------------------------------
// セッション開設・回収
//-----------------------------------------------------------------------------------------
- (void)connectToServer:(NSNetService *)service
{
    if (!_serviceForSession){
        _serviceForSession = [[NSNetService alloc] initWithDomain:service.domain type:service.type name:service.name];
        _serviceForSession.delegate = self;
        [_serviceForSession resolveWithTimeout:5.0];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSInputStream* inputStream;
    NSOutputStream* outputStream;
    [sender getInputStream:&inputStream outputStream:&outputStream];
    _session = [[DVRemoteSession alloc] initWithInputStream:inputStream outputStream:outputStream];
    _session.delegate = self;
    [_session scheduleInRunLoop:_runLoop];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [self disconnect];
    if (_delegate){
        [_delegate dvrClient:self hasBeenDisconnectedByError:nil];
    }
}

- (void)disconnect
{
    if (_browser){
        [_browser stop];
        _browser = nil;
    }
    if (_serviceForSession){
        [_serviceForSession stop];
        _serviceForSession = nil;
    }
    if (_session){
        [_session close];
        _session = nil;
    }
}

//-----------------------------------------------------------------------------------------
// セッションからのイベント処理
//-----------------------------------------------------------------------------------------
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data
{
    if (command == DVRC_NOTIFY_META){
        NSDictionary* meta = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate){
            [_delegate dvrClient:self didRecieveMeta:meta];
        }
    }
}

- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error
{
    [self disconnect];
    if (_delegate){
        [_delegate dvrClient:self hasBeenDisconnectedByError:nil];
    }
}

@end
