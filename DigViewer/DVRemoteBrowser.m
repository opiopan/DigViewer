//
//  DVRemoteBrowser.m
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteBrowser.h"

@implementation DVRemoteBrowser{
    NSNetServiceBrowser* _browser;
    NSMutableArray* _servers;
}

//-----------------------------------------------------------------------------------------
// 初期化・回収
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _servers = [NSMutableArray new];
        _browser = [NSNetServiceBrowser new];
        _browser.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

//-----------------------------------------------------------------------------------------
// プロパティの実装
//-----------------------------------------------------------------------------------------
- (NSArray *)servers
{
    return _servers;
}

//-----------------------------------------------------------------------------------------
// 検索停止
//-----------------------------------------------------------------------------------------
- (void)stop
{
    [_browser stop];
    _browser.delegate = nil;
}

//-----------------------------------------------------------------------------------------
// サーバ一検索
//-----------------------------------------------------------------------------------------
- (void)searchServers
{
    [_browser searchForServicesOfType:DVR_SERVICE_TYPE inDomain:@""];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
           didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [_servers addObject:aNetService];
    if (!moreComing){
        if (_delegate){
            [_delegate dvrBrowserDetectChangeServers:self];
        }
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser
         didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [_servers removeObject:aNetService];
    if (!moreComing){
        if (_delegate){
            [_delegate dvrBrowserDetectChangeServers:self];
        }
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    if (_delegate){
        [_delegate dvrBrowser:self didNotSearch:errorDict];
    }
    [_browser stop];
}

@end
