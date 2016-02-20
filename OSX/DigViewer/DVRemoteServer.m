//
//  DVRemoteServer.m
//  DigViewer
//
//  Created by opiopan on 2015/09/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteServer.h"
#import "PathNode.h"
#import "ImageMetadata.h"
#import "LensLibrary.h"

@implementation DVRemoteServer{
    BOOL _publishingFailed;
    NSNetService* _service;
    
    NSMutableArray* _reservedSessions;
    NSMutableArray* _authorizedSessions;
    NSMutableArray* _sidebandSessions;
    
    NSData* _currentMeta;
    NSData* _templateMeta;
    
    NSMutableDictionary* _fullImageQue;
    
    NSDictionary* _serverInfo;
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
        _reservedSessions = [NSMutableArray array];
        _authorizedSessions = [NSMutableArray array];
        _sidebandSessions = [NSMutableArray array];
        
        ImageMetadata* meta = [[ImageMetadata alloc] init];
        NSArray* summary = meta.summary;
        NSArray* gpsInfo = meta.gpsInfoStrings;
        NSDictionary* templateMeta = @{DVRCNMETA_SUMMARY:summary, DVRCNMETA_GPS_SUMMARY:gpsInfo};
        _templateMeta = [NSKeyedArchiver archivedDataWithRootObject:templateMeta];
        _fullImageQue = [NSMutableDictionary dictionary];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// サーバ起動・停止
//-----------------------------------------------------------------------------------------
- (BOOL)establishServer
{
    if (_service) return NO;
    
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

- (void)shutdownServer
{
    if (_service){
        [_service stop];
        _service = nil;
        NSArray* array = [NSArray arrayWithArray:_reservedSessions];
        for (DVRemoteSession* session in array){
            [self discardSession:session];
        }
        array = [NSArray arrayWithArray:_authorizedSessions];
        for (DVRemoteSession* session in array){
            [self discardSession:session];
        }
        array = [NSArray arrayWithArray:_sidebandSessions];
        for (DVRemoteSession* session in array){
            [self discardSession:session];
        }
    }
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
    [session sendCommand:DVRC_NOTIFY_ACCEPTED withData:nil replacingQue:NO];
}


//-----------------------------------------------------------------------------------------
// クライアントセッションからのイベント処理
//-----------------------------------------------------------------------------------------
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data
{
    if (command == DVRC_MAIN_CONNECTION){
    }else if (command == DVRC_REQUEST_PAIRING){
        if (_delegate){
            NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [_delegate dvrServer:self needPairingForClient:session withAttributes:args];
        }
    }else if (command == DVRC_CHARENGE_AUTH){
        if (_delegate){
            NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [_delegate dvrServer:self needAuthenticateClient:session withAttributes:args];
        }
    }else if (command == DVRC_SIDE_CONNECTION){
        [_reservedSessions removeObject:session];
        [_sidebandSessions addObject:session];
    }else if (command == DVRC_REQUEST_SEVER_INFO){
        if (_serverInfo){
            [self sendServerInfo:_serverInfo bySession:session];
        }else if(_delegate){
            [_delegate dvrServer:self needSendServerInfoToClient:session];
        }
    }if (command == DVRC_MOVE_PREV_IMAGE || command == DVRC_MOVE_NEXT_IMAGE){
        NSString* document = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate){
            [_delegate dvrServer:self needMoveToNeighborImageOfDocument:document withDirection:command];
        }
    }else if (command == DVRC_MOVE_NODE){
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate && [_delegate respondsToSelector:@selector(dvrServer:needMoveToNode:inDocument:)]){
            [_delegate dvrServer:self needMoveToNode:[args valueForKey:DVRCNMETA_ID]
                      inDocument:[args valueForKey:DVRCNMETA_DOCUMENT]];
        }
    }else if (command == DVRC_REQUEST_THUMBNAIL){
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate){
            [_delegate dvrServer:self needSendThumbnail:[args valueForKey:DVRCNMETA_ID]
                     forDocument:[args valueForKey:DVRCNMETA_DOCUMENT]];
        }
    }else if (command == DVRC_REQUEST_FULLIMAGE){
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSString* idString = [self nodeIDStringForMeta:args];
        
        NSMutableArray* sessions = [_fullImageQue valueForKey:idString];
        if (sessions){
            BOOL found = NO;
            for (DVRemoteSession* registeredSession in sessions){
                if (session == registeredSession){
                    found = YES;
                    break;
                }
                if (!found){
                    [sessions addObject:session];
                }
            }
        }else{
            NSMutableArray* sessions = [NSMutableArray array];
            [sessions addObject:session];
            [_fullImageQue setValue:sessions forKey:idString];
            if (_delegate && [_delegate respondsToSelector:@selector(dvrServer:needSendFullimage:forDocument:withSize:)]){
                [_delegate dvrServer:self needSendFullimage:[args valueForKey:DVRCNMETA_ID]
                         forDocument:[args valueForKey:DVRCNMETA_DOCUMENT]
                            withSize:[[args valueForKey:DVRCNMETA_IMAGESIZEMAX] doubleValue]];
            }
        }
    }else if (command == DVRC_REQUEST_FOLDER_ITEMS){
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate && [_delegate respondsToSelector:@selector(dvrServer:needSendFolderItms:forDocument:bySession:)]){
            [_delegate dvrServer:self needSendFolderItms:[args valueForKey:DVRCNMETA_ID]
                     forDocument:[args valueForKey:DVRCNMETA_DOCUMENT] bySession:session];
        }
        
    }
}

- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error
{
    [session close];
    [_reservedSessions removeObject:session];
    [_authorizedSessions removeObject:session];
    [_sidebandSessions removeObject:session];
    NSMutableArray* removingKeys = [NSMutableArray array];
    for (NSString* key in _fullImageQue){
        NSMutableArray* sessions = [_fullImageQue valueForKey:key];
        [sessions removeObject:session];
        if (sessions.count == 0){
            [removingKeys addObject:key];
        }
    }
    for (NSString* key in removingKeys){
        [_fullImageQue removeObjectForKey:key];
    }
}

//-----------------------------------------------------------------------------------------
// セション切断
//-----------------------------------------------------------------------------------------
- (void)discardSession:(DVRemoteSession *)session
{
    [session close];
    [_reservedSessions removeObject:session];
    [_authorizedSessions removeObject:session];
    [_sidebandSessions removeObject:session];
    NSMutableArray* removingKeys = [NSMutableArray array];
    for (NSString* key in _fullImageQue){
        NSMutableArray* sessions = [_fullImageQue valueForKey:key];
        [sessions removeObject:session];
        if (sessions.count == 0){
            [removingKeys addObject:key];
        }
    }
    for (NSString* key in removingKeys){
        [_fullImageQue removeObjectForKey:key];
    }
}

//-----------------------------------------------------------------------------------------
// クライアント認証
//-----------------------------------------------------------------------------------------
- (void)sendPairingKey:(NSDictionary*)args bySession:(DVRemoteSession*)session
{
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
    [session sendCommand:DVRC_NOTIFY_PAIRCODE withData:data replacingQue:YES];
}

- (void)completeAuthenticationAsResult:(BOOL)succeeded ofSession:(DVRemoteSession*)session
{
    int cmd = succeeded ? DVRC_NOTIFY_AUTHENTICATED : DVRC_NOTIFY_FAIL_AUTH;
    [session sendCommand:cmd withData:nil replacingQue:YES];
    
    if (succeeded){
        [_reservedSessions removeObject:session];
        [_authorizedSessions addObject:session];
        [session sendCommand:DVRC_NOTIFY_TEMPLATE_META withData:_templateMeta replacingQue:YES];
        if (_currentMeta){
            [session sendCommand:DVRC_NOTIFY_META withData:_currentMeta replacingQue:NO];
        }
        [self sendLensLibraryToSession:session];
    }
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

//-----------------------------------------------------------------------------------------
// レンズライブラリ送信
//-----------------------------------------------------------------------------------------
- (void) sendLensLibraryToSession:(DVRemoteSession*)session
{
    LensLibrary* library = [LensLibrary sharedLensLibrary];
    NSArray* lensProfiles = library.allLensProfiles;
    if (lensProfiles.count > 0){
        NSDate* modDate = library.storeModificationDate;
        NSData* storeData = library.storeData;
        NSDictionary* args = @{DVRCNMETA_LENS_LIBRARY: storeData,
                               DVRCNMETA_LENS_LIBRARY_DATE: @(modDate.timeIntervalSince1970)};
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
        [session sendCommand:DVRC_NOTIFY_LENS_LIBRARY withData:data replacingQue:NO];
    }
}

//-----------------------------------------------------------------------------------------
// サムネール送信
//-----------------------------------------------------------------------------------------
- (void)sendThumbnail:(NSData*)thumbnail forNodeID:(NSArray*)nodeID inDocument:(NSString*)documentName withIndex:(NSInteger)index
{
    NSDictionary* args = @{DVRCNMETA_DOCUMENT: documentName,
                           DVRCNMETA_ID: nodeID,
                           DVRCNMETA_THUMBNAIL: thumbnail,
                           DVRCNMETA_INDEX_IN_PARENT: @(index)};
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
    for (DVRemoteSession* session in _authorizedSessions){
        [session sendCommand:DVRC_NOTIFY_THUMBNAIL withData:data replacingQue:NO];
    }
}

//-----------------------------------------------------------------------------------------
// フル画像送信
//-----------------------------------------------------------------------------------------
- (void)sendFullimage:(NSData *)fullimage forNodeID:(NSArray *)nodeID inDocument:(NSString *)documentName
         withRotation:(NSInteger)rotation
{
    NSDictionary* args = @{DVRCNMETA_DOCUMENT: documentName,
                           DVRCNMETA_ID: nodeID,
                           DVRCNMETA_FULLIMAGE: fullimage,
                           DVRCNMETA_IMAGEROTATION: @(rotation)};
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
    NSString* idString = [self nodeIDStringForMeta:args];
    
    NSMutableArray* sessions = [_fullImageQue valueForKey:idString];
    if (sessions){
        for (DVRemoteSession* registeredSession in sessions){
            [registeredSession sendCommand:DVRC_NOTIFY_FULLIMAGE withData:data replacingQue:NO];
        }
        [_fullImageQue removeObjectForKey:idString];
    }
}

//-----------------------------------------------------------------------------------------
// フォルダー内ノード情報一覧送信
//-----------------------------------------------------------------------------------------
- (void)sendFolderItems:(NSArray *)items forNodeID:(NSArray *)nodeID inDocument:(NSString *)documentName
              bySession:(DVRemoteSession *)session
{
    DVRemoteSession* targetSession = nil;
    for (targetSession in _authorizedSessions){
        if (targetSession == session){
            break;
        }
    }
    if (targetSession){
        NSDictionary* args = @{DVRCNMETA_DOCUMENT: documentName,
                               DVRCNMETA_ID: nodeID,
                               DVRCNMETA_ITEM_LIST: items};
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
        [targetSession sendCommand:DVRC_NOTIFY_FOLDER_ITEMS withData:data replacingQue:YES];
    }
}

//-----------------------------------------------------------------------------------------
// サーバー情報送信
//-----------------------------------------------------------------------------------------
- (void)sendServerInfo:(NSDictionary *)serverInfo bySession:(DVRemoteSession *)session
{
    if (!_serverInfo){
        _serverInfo = serverInfo;
    }
    DVRemoteSession* targetSession = nil;
    for (targetSession in _authorizedSessions){
        if (targetSession == session){
            break;
        }
    }
    if (targetSession){
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:serverInfo];
        [targetSession sendCommand:DVRC_NOTIFY_SERVER_INFO withData:data replacingQue:NO];
    }
}

//-----------------------------------------------------------------------------------------
// ノードID文字列生成
//-----------------------------------------------------------------------------------------
- (NSString*)nodeIDStringForMeta:(NSDictionary*)meta
{
    NSString* rc = [meta valueForKey:DVRCNMETA_DOCUMENT];
    NSArray* nodeId = [meta valueForKey:DVRCNMETA_ID];
    for (NSString* element in nodeId){
        rc = [rc stringByAppendingFormat:@"/%@", element];
    }
    return rc;
}

@end
