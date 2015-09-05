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

@implementation DVRemoteServer{
    BOOL _publishingFailed;
    NSNetService* _service;
    
    NSMutableArray* _authorizedSessions;
    
    NSData* _currentMeta;
    NSData* _templateMeta;
    
    NSMutableDictionary* _fullImageQue;
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
    [session sendCommand:DVRC_NOTIFY_TEMPLATE_META withData:_templateMeta replacingQue:YES];
    if (_currentMeta){
        [session sendCommand:DVRC_NOTIFY_META withData:_currentMeta replacingQue:NO];
    }
}


//-----------------------------------------------------------------------------------------
// クライアントセッションからのイベント処理
//-----------------------------------------------------------------------------------------
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data
{
    if (command == DVRC_MOVE_PREV_IMAGE || command == DVRC_MOVE_NEXT_IMAGE){
        NSString* document = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate){
            [_delegate dvrServer:self needMoveToNeighborImageOfDocument:document withDirection:command];
        }
    }else if (command == DVRC_REQUEST_THUMBNAIL){
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_delegate){
            [_delegate dvrServer:self needSendThumbnails:[args valueForKey:DVRCNMETA_IDS]
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
    }
}

- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error
{
    [session close];
    [_authorizedSessions removeObject:session];
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
// サムネール送信
//-----------------------------------------------------------------------------------------
- (void)sendThumbnail:(NSData*)thumbnail forNodeID:(NSArray*)nodeID inDocument:(NSString*)documentName
{
    NSDictionary* args = @{DVRCNMETA_DOCUMENT: documentName,
                           DVRCNMETA_ID: nodeID,
                           DVRCNMETA_THUMBNAIL: thumbnail};
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
    for (DVRemoteSession* session in _authorizedSessions){
        [session sendCommand:DVRC_NOTIFY_THUMBNAIL withData:data replacingQue:YES];
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
