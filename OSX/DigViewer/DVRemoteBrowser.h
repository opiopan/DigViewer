//
//  DVRemoteBrowser.h
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteProtcol.h"

@protocol DVRemoteBrowserDelegate;

//-----------------------------------------------------------------------------------------
// DVRemoteClient宣言
//-----------------------------------------------------------------------------------------
@interface DVRemoteBrowser : NSObject <NSNetServiceBrowserDelegate>

@property (weak, nonatomic) id <DVRemoteBrowserDelegate> delegate;
@property (readonly, nonatomic) NSArray* servers;

- (void)searchServers;
- (void)stop;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteBrowserDelegate <NSObject>
- (void)dvrBrowserDetectAddServer:(DVRemoteBrowser*)browser service:(NSNetService *)service;
- (void)dvrBrowserDetectRemoveServer:(DVRemoteBrowser*)browser service:(NSNetService *)service;
- (void)dvrBrowser:(DVRemoteBrowser*)browser didNotSearch:(NSDictionary*)errorDict;
@end