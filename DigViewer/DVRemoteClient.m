//
//  DVRemoteClient.m
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteClient.h"

@implementation DVRemoteClient{
    NSMutableArray* _delegates;
    
    NSNetService* _serviceForSession;
    DVRemoteSession* _session;
    
    NSDictionary* _meta;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (DVRemoteClient *)sharedClient
{
    static DVRemoteClient* sharedClient = nil;
    
    if (!sharedClient){
        sharedClient = [DVRemoteClient new];
    }
    
    return sharedClient;
}

//-----------------------------------------------------------------------------------------
// 初期化・回収
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _delegates = [NSMutableArray array];
        _state = DVRClientDisconnected;
        _reconectCount = 0;
        _runLoop = [NSRunLoop currentRunLoop];
    }
    return self;
}

- (void)dealloc
{
    [_delegates removeAllObjects];
    [self disconnect];
}

//-----------------------------------------------------------------------------------------
// デリゲート追加・削除
//-----------------------------------------------------------------------------------------
- (void)addClientDelegate:(id <DVRemoteClientDelegate>)delegate
{
    [_delegates addObject:delegate];
}

- (void)removeClientDelegate:(id <DVRemoteClientDelegate>)delegate
{
    [_delegates removeObject:delegate];
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (NSString *)stateString
{
    NSArray* descriptions = @[@"Disconnected",
                              @"Connecting...",
                              @"Authenticating...",
                              @"Connected"];
    return descriptions[_state];
}

- (NSNetService *)service
{
    return _serviceForSession;
}

- (NSDictionary *)meta
{
    return _meta;
}

//-----------------------------------------------------------------------------------------
// 状態変更通知
//-----------------------------------------------------------------------------------------
- (void)notifyStateChange
{
    if (_delegates.count){
        for (id <DVRemoteClientDelegate> delegate in _delegates){
            [delegate dvrClient:self changeState:_state];
        }
    }
}

//-----------------------------------------------------------------------------------------
// セッション開設・回収
//-----------------------------------------------------------------------------------------
- (void)connectToServer:(NSNetService *)service
{
    if (_state == DVRClientDisconnected){
        _reconectCount = 0;
        _serviceForSession = [[NSNetService alloc] initWithDomain:service.domain type:service.type name:service.name];
        _serviceForSession.delegate = self;
        _state = DVRClientConnecting;
        [self notifyStateChange];
        [_serviceForSession resolveWithTimeout:5.0];
    }
}

- (void)reconnect
{
    if (_state == DVRClientDisconnected){
        _reconectCount++;
        _state = DVRClientConnecting;
        [self notifyStateChange];
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
    _state = DVRClientConnected;
    [self notifyStateChange];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [self disconnect];
}

- (void)disconnect
{
    if (_serviceForSession){
        [_serviceForSession stop];
    }
    if (_session){
        [_session close];
        _session = nil;
    }
    if (_state != DVRClientDisconnected){
        _state = DVRClientDisconnected;
        [self notifyStateChange];
    }
}

//-----------------------------------------------------------------------------------------
// サーバーへのコマンド発行
//-----------------------------------------------------------------------------------------
- (void)moveToNextImage
{
    [self sendMoveToCommand:DVRC_MOVE_NEXT_IMAGE];
}

- (void)moveToPreviousImage
{
    [self sendMoveToCommand:DVRC_MOVE_PREV_IMAGE];
}

- (void)sendMoveToCommand:(DVRCommand)command
{
    if (_state == DVRClientConnected && _meta){
        NSString* document = [_meta valueForKey:DVRCNMETA_DOCUMENT];
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:document];
        [_session sendCommand:command withData:data replacingQue:NO];
    }
}

//-----------------------------------------------------------------------------------------
// セッションからのイベント処理
//-----------------------------------------------------------------------------------------
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data
{
    if (command == DVRC_NOTIFY_TEMPLATE_META){
        _templateMeta = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }else if (command == DVRC_NOTIFY_META){
        NSDictionary* newMeta = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (![self compareWithMeta:_meta andMeta:newMeta]){
            _meta = newMeta;
            _thumbnail = nil;
            NSDictionary* reqDict = @{DVRCNMETA_DOCUMENT: [_meta valueForKey:DVRCNMETA_DOCUMENT],
                                      DVRCNMETA_IDS: @[[_meta valueForKey:DVRCNMETA_ID]]};
            NSData* reqData = [NSKeyedArchiver archivedDataWithRootObject:reqDict];
            [_session sendCommand:DVRC_REQUEST_THUMBNAIL withData:reqData replacingQue:NO];
        }else{
            _meta = newMeta;
        }
        if (_delegates.count){
            for (id <DVRemoteClientDelegate> delegate in _delegates){
                [delegate dvrClient:self didRecieveMeta:_meta];
            }
        }
    }else if (command == DVRC_NOTIFY_THUMBNAIL){
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([self compareWithMeta:_meta andMeta:args] && !_thumbnail){
            NSData* tiffData = [args valueForKey:DVRCNMETA_THUMBNAIL];
            _thumbnail = [UIImage imageWithData:tiffData];
            for (id <DVRemoteClientDelegate> delegate in _delegates){
                if ([delegate respondsToSelector:@selector(dvrClient:didRecieveCurrentThumbnail:)]){
                    [delegate dvrClient:self didRecieveCurrentThumbnail:_thumbnail];
                }
            }
        }
    }
}

- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error
{
    [self disconnect];
}

//-----------------------------------------------------------------------------------------
// メタ比較
//-----------------------------------------------------------------------------------------
- (BOOL) compareWithMeta:(NSDictionary*)meta1 andMeta:(NSDictionary*)meta2
{
    BOOL rc = YES;
    
    NSString* doc1 = [meta1 valueForKey:DVRCNMETA_DOCUMENT];
    NSString* doc2 = [meta2 valueForKey:DVRCNMETA_DOCUMENT];
    NSArray* path1 = [meta1 valueForKey:DVRCNMETA_ID];
    NSArray* path2 = [meta2 valueForKey:DVRCNMETA_ID];
    
    if ([doc1 isEqualToString:doc2] && path1.count == path2.count){
        for (int i = 0; i < path1.count; i++){
            if (![path1[i] isEqualToString:path2[i]]){
                rc = NO;
                break;
            }
        }
    }else{
        rc = NO;
    }
    
    return rc;
}

@end
