
//
//  DVRemoteClient.m
//  DigViewer
//
//  Created by opiopan on 2015/09/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteClient.h"
#import "LocalSession.h"
#import "LRUCache.h"
#import "DVRemoteCommonLib.h"
#import "DigViewerRemote-Swift.h"

//-----------------------------------------------------------------------------------------
// ThumbnailCacheEntry: サムネールキャッシュの要素
//-----------------------------------------------------------------------------------------
@interface ThumbnailCacheEntry : NSObject
@property ThumbnailCacheEntry* next;
@property ThumbnailCacheEntry* prev;
@property NSString* key;
@property UIImage* image;
@end

@implementation ThumbnailCacheEntry
@end

//-----------------------------------------------------------------------------------------
// DVRemoteClientの実装
//-----------------------------------------------------------------------------------------
@interface DVRemoteClient ()
@property NSInteger watchDogCount;
@property BOOL runningWatchDog;
@end

@implementation DVRemoteClient{
    NSMutableArray* _delegates;
    
    NSURL* _sharedImage;
    
    NSNetService* _serviceForSession;
    DVRemoteSession* _session;
    LocalSession* _localSession;
    NSString* _lastSessionName;
    NSString* _pairingKey;
    NSString* _deviceCode;
    
    NSDictionary* _meta;
    
    UIImage* _fullImage;
    
    NSDictionary* _nodeListWrap;
    
    LRUCache* _thumbnailCache;
    LRUCache* _nodeListCache;
    
    BOOL _isTemporary;
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
// 一時的な接続
//-----------------------------------------------------------------------------------------
+ (DVRemoteClient *)temporaryClient
{
    DVRemoteClient* client =  [DVRemoteClient new];
    client->_isTemporary = YES;
    return client;
}

//-----------------------------------------------------------------------------------------
// 初期化・回収
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _isInitialized = NO;
        _delegates = [NSMutableArray array];
        _state = DVRClientDisconnected;
        _reconectCount = 0;
        _runLoop = [NSRunLoop currentRunLoop];
        _runningWatchDog = NO;
        [self initCache];
    }
    return self;
}

- (void)dealloc
{
    [_delegates removeAllObjects];
    [self disconnect];
}

- (void)initCache
{
    _thumbnailCache = [LRUCache cacheWithSize:500];
    _nodeListCache = [LRUCache cacheWithSize:10];
}

//-----------------------------------------------------------------------------------------
// デリゲート追加・削除
//-----------------------------------------------------------------------------------------
- (void)addClientDelegate:(id <DVRemoteClientDelegate>)delegate
{
    if ([NSThread isMainThread]){
        [_delegates addObject:delegate];
    }else{
        DVRemoteClient* __weak weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^(){
            [weakSelf addClientDelegate:delegate];
        });
    }
}

- (void)removeClientDelegate:(id <DVRemoteClientDelegate>)delegate
{
    if ([NSThread isMainThread]){
        [_delegates removeObject:delegate];
    }else{
        DVRemoteClient* __weak weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^(){
            [weakSelf removeClientDelegate:delegate];
        });
    }
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
    return NSLocalizedString(descriptions[_state], "");
}

- (NSNetService *)service
{
    return _serviceForSession;
}

- (NSString*) serviceName
{
    if (_state != DVRClientDisconnected){
        return _serviceForSession ? _serviceForSession.name : NSLocalizedString(@"DSNAME_LOCAL", nil);
    }else{
        return nil;
    }
}

- (NSDictionary *)meta
{
    return _meta;
}

- (BOOL)isConnectedToLocal
{
    return _localSession != nil;
}

//-----------------------------------------------------------------------------------------
// 状態変更通知
//-----------------------------------------------------------------------------------------
- (void)notifyStateChange
{
    if (_state == DVRClientConnected ){
        NSString* serviceName = _serviceForSession ? _serviceForSession.name : @"";
        if (![_lastSessionName isEqualToString:serviceName]){
            _meta = nil;
            _fullImage = nil;
            _nodeListWrap = nil;
            [self initCache];
        }
        _lastSessionName = serviceName;
    }
    
    if (_delegates.count){
        for (id <DVRemoteClientDelegate> delegate in _delegates){
            if ([delegate respondsToSelector:@selector(dvrClient:changeState:)]){
                [delegate dvrClient:self changeState:_state];
            }
        }
    }
    if (_tmpDelegate && [_tmpDelegate respondsToSelector:@selector(dvrClient:changeState:)]){
        [_tmpDelegate dvrClient:self changeState:_state];
    }
}

//-----------------------------------------------------------------------------------------
// アプリ間共有イメージの登録
//-----------------------------------------------------------------------------------------
- (void)regeisterSharedImage:(NSURL *)url
{
    _sharedImage = url;
    if (_localSession){
        [_localSession registerSharedImage:url];
        _sharedImage = nil;
    }else if (_isInitialized){
        [self disconnect];
        [self connectToLocal];
    }
}

//-----------------------------------------------------------------------------------------
// セッション開設・回収
//-----------------------------------------------------------------------------------------
- (void)connectToServer:(NSNetService *)service withKey:(NSString*)key fromDevice:(NSString *)deviceCode
{
    if (_state == DVRClientDisconnected){
        _reconectCount = 0;
        _serviceForSession = [[NSNetService alloc] initWithDomain:service.domain type:service.type name:service.name];
        _serviceForSession.delegate = self;
        _pairingKey = key;
        _deviceCode = deviceCode;
        _state = DVRClientConnecting;
        [self notifyStateChange];
        [_serviceForSession resolveWithTimeout:5.0];
    }
}

- (void)connectToLocal
{
    if (_state == DVRClientDisconnected){
        _reconectCount = 0;
        _serviceForSession = nil;
        _pairingKey = nil;
        _state = DVRClientConnecting;
        _localSession = [LocalSession new];
        _localSession.delegate = self;
        [self notifyStateChange];
        if (_sharedImage){
            [_localSession registerSharedImage:_sharedImage];
        }
        [_localSession connect];
    }
}

- (void)reconnect
{
    if (_state == DVRClientDisconnected && _serviceForSession){
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
//    [sender getInputStream:&inputStream outputStream:&outputStream];
//    _sidebandSession = [[DVRemoteSession alloc] initWithInputStream:inputStream outputStream:outputStream];
//    _sidebandSession.delegate = self;
//    [_sidebandSession scheduleInRunLoop:_runLoop];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [self disconnect];
}

- (void)disconnect
{
    _namespaceCounter++;
    
    if (_serviceForSession){
        [_serviceForSession stop];
    }
    if (_session){
        [_session close];
        _session = nil;
    }
    if (_localSession){
        _localSession = nil;
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
    if (_localSession){
        [_localSession moveNextAsset];
    }else{
        [self sendMoveToCommand:DVRC_MOVE_NEXT_IMAGE];
    }
}

- (void)moveToPreviousImage
{
    if (_localSession){
        [_localSession movePreviousAsset];
    }else{
        [self sendMoveToCommand:DVRC_MOVE_PREV_IMAGE];
    }
}

- (void)sendMoveToCommand:(DVRCommand)command
{
    if (_state == DVRClientConnected && _meta){
        NSString* document = [_meta valueForKey:DVRCNMETA_DOCUMENT];
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:document];
        [_session sendCommand:command withData:data replacingQue:NO];
        [self startWatchDog];
    }
}


- (void)moveToNode:(NSArray *)nodeID inDocument:(NSString *)documentName
{
    if (_localSession){
        [_localSession moveToAssetWithID:nodeID];
    }else{
        NSDictionary* args = @{DVRCNMETA_DOCUMENT: documentName,
                               DVRCNMETA_ID: nodeID};
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
        [_session sendCommand:DVRC_MOVE_NODE withData:data replacingQue:YES];
    }
}

- (UIImage *)thumbnailForID:(NSArray *)nodeID inDocument:(NSString *)documentName downloadIfNeed:(BOOL)downloadIfNeed
{
    if (_localSession){
        return [_localSession thumbnailForID:nodeID];
    }else{
        NSDictionary* args = @{DVRCNMETA_DOCUMENT: documentName,
                               DVRCNMETA_ID : nodeID};
        if (_thumbnail && [self compareWithMeta:args andMeta:_meta]){
            return _thumbnail;
        }
        NSString* key = [self keyForID:nodeID inDocument:documentName];
        UIImage* thumbnail = [_thumbnailCache valueForKey:key];
        if (!thumbnail && downloadIfNeed){
            NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
            [_session sendCommand:DVRC_REQUEST_THUMBNAIL withData:data replacingQue:NO];
        }
        
        return thumbnail;
    }
}

- (UIImage *)fullImageForID:(NSArray *)nodeID inDocument:(NSString *)document withMaxSize:(CGFloat)maxSize
{
    if (_localSession){
        return [_localSession fullImageForID:nodeID];
    }else{
        UIImage* rc = nil;
        
        NSDictionary* commandArgs = @{DVRCNMETA_DOCUMENT: document,
                                      DVRCNMETA_ID: nodeID,
                                      DVRCNMETA_IMAGESIZEMAX: @(maxSize)};
        if (_meta && [self compareWithMeta:commandArgs andMeta:_meta]){
            rc = _fullImage;
        }
        
        if (!rc){
            NSData* data = [NSKeyedArchiver archivedDataWithRootObject:commandArgs];
            [_session sendCommand:DVRC_REQUEST_FULLIMAGE withData:data replacingQue:YES];
            [self startWatchDog];
        }
        
        return rc;
    }
}

- (NSArray *)nodeListForID:(NSArray *)nodeID inDocument:(NSString *)document
{
    if (nodeID != nil && document != nil){
        if (_localSession){
            NSString* key = [self keyForID:nodeID inDocument:document];
            NSArray* nodeList = [_nodeListCache valueForKey:key];
            if (!nodeList){
                DVRemoteClient* __weak weakSelf = self;
                LocalSession* localSession = _localSession;
                LRUCache* nodeListCache = _nodeListCache;
                dispatch_queue_t que = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(que, ^(void){
                    NSArray* nodeList = [localSession nodeListForID:nodeID];
                    [nodeListCache setValue:nodeList forKey:key];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakSelf notifyNodeList:nodeList forID:nodeID inDocument:document withKey:key];
                    });
                });
            }
            return nodeList;
        }else{
            NSDictionary* args = @{DVRCNMETA_DOCUMENT: document, DVRCNMETA_ID: nodeID};
            if (_nodeListWrap && [self compareWithMeta:_nodeListWrap andMeta:args]){
                return [_nodeListWrap valueForKey:DVRCNMETA_ITEM_LIST];
            }
            
            NSString* key = [self keyForID:nodeID inDocument:document];
            NSArray* nodeList = [_nodeListCache valueForKey:key];
            if (nodeList){
                return nodeList;
            }
            
            NSData* data = [NSKeyedArchiver archivedDataWithRootObject:args];
            DVRemoteSession* session = _session;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [session sendCommand:DVRC_REQUEST_FOLDER_ITEMS withData:data replacingQue:NO];
            });
        }
    }
    
    return nil;
}

- (void)notifyNodeList:(NSArray*)nodeList forID:(NSArray*)nodeID inDocument:(NSString*)document withKey:(NSString*)key
{
    for (id <DVRemoteClientDelegate> delegate in _delegates){
        if ([delegate respondsToSelector:@selector(dvrClient:didRecieveNodeList:forNode:inDocument:)]){
            [delegate dvrClient:self didRecieveNodeList:nodeList forNode:nodeID inDocument:document];
        }
    }
}

- (void)requestServerInfo
{
    [_session sendCommand:DVRC_REQUEST_SEVER_INFO withData:nil replacingQue:NO];
}

- (PHFetchResult*)assetsForID:(NSArray*)nodeID inDocument:(NSString*)document
{
    if (_localSession){
        return [_localSession assetsForID:nodeID];
    }else{
        return nil;
    }
}

- (BOOL)isAssetCollection:(NSArray*)nodeID inDocument:(NSString*)document
{
    if (_localSession){
        return [_localSession isAssetCollection:nodeID];
    }else{
        return false;
    }
}

//-----------------------------------------------------------------------------------------
// セッションからのイベント処理
//-----------------------------------------------------------------------------------------
- (void)dvrSession:(DVRemoteSession*)session recieveCommand:(DVRCommand)command withData:(NSData*)data
{
    [self endWatchDog];
    if (command == DVRC_NOTIFY_ACCEPTED){
        if (_localSession){
            _state = DVRClientConnected;
            [self notifyStateChange];
        }else if (session == _session){
            [_session sendCommand:DVRC_MAIN_CONNECTION withData:nil replacingQue:YES];
            [self requestAuthentication];
            _state = DVRClientAuthenticating;
            [self notifyStateChange];
        }else{
            [_session sendCommand:DVRC_SIDE_CONNECTION withData:nil replacingQue:YES];
        }
    }else if (command == DVRC_NOTIFY_PAIRCODE){
        //-----------------------------------------------------------------------------------------
        // ペアリングキー受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        _pairingKey = [args valueForKey:DVRCNMETA_PAIRCODE];
        if (_delegates.count){
            for (id <DVRemoteClientDelegate> delegate in _delegates){
                if ([delegate respondsToSelector:@selector(dvrClient:didRecievePairingKey:forServer:)]){
                    [delegate dvrClient:self didRecievePairingKey:_pairingKey forServer:_serviceForSession];
                }
            }
        }
    }else if (command == DVRC_NOTIFY_AUTHENTICATED){
        //-----------------------------------------------------------------------------------------
        // 認証完了
        //-----------------------------------------------------------------------------------------
        _state = DVRClientConnected;
        [self notifyStateChange];
    }else if (command == DVRC_NOTIFY_FAIL_AUTH){
        //-----------------------------------------------------------------------------------------
        // 認証失敗
        //-----------------------------------------------------------------------------------------
        _pairingKey = nil;
        [self requestAuthentication];
    }else if (command == DVRC_NOTIFY_TEMPLATE_META){
        //-----------------------------------------------------------------------------------------
        // テンプレートメタ受信
        //-----------------------------------------------------------------------------------------
        _templateMeta = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_state != DVRClientConnected){
            _state = DVRClientConnected;
            [self notifyStateChange];
        }
    }else if (command == DVRC_NOTIFY_META){
        //-----------------------------------------------------------------------------------------
        // メタデータ受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* newMeta = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        _meta = newMeta;
        _thumbnail = nil;
        _fullImage = nil;
        if (![self compareWithMeta:_nodeListWrap andMetasParent:newMeta]){
            _nodeListWrap = nil;
        }
        _thumbnail = [self thumbnailForID:[_meta valueForKey:DVRCNMETA_ID]
                               inDocument:[_meta valueForKey:DVRCNMETA_DOCUMENT]
                           downloadIfNeed:YES];
        NSNumber* namespaceChanged = [_meta valueForKey:DVRCNMETA_NAMESPACE_CHANGED];
        NSNumber* entityChanged = [_meta valueForKey:DVRCNMETA_ENTITY_CHANGED];
        
        if (namespaceChanged && namespaceChanged.boolValue){
            [self initCache];
            _namespaceCounter++;
            for (id <DVRemoteClientDelegate> delegate in _delegates){
                if ([delegate respondsToSelector:@selector(dvrClientChangeNamespace:)]){
                    [delegate dvrClientChangeNamespace:self];
                }
            }
        }
        if (_delegates.count){
            if (!entityChanged || entityChanged.boolValue){
                for (id <DVRemoteClientDelegate> delegate in _delegates){
                    if ([delegate respondsToSelector:@selector(dvrClient:didRecieveMeta:)]){
                        [delegate dvrClient:self didRecieveMeta:_meta];
                    }
                }
            }
        }
    }else if (command == DVRC_NOTIFY_THUMBNAIL){
        //-----------------------------------------------------------------------------------------
        // サムネール受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSData* tiffData = [args valueForKey:DVRCNMETA_THUMBNAIL];
        UIImage* image = [UIImage imageWithData:tiffData];
        NSString* key = [self keyForID:[args valueForKey:DVRCNMETA_ID] inDocument:[args valueForKey:DVRCNMETA_DOCUMENT]];
        [_thumbnailCache setValue:image forKey:key];
        if ([self compareWithMeta:_meta andMeta:args] && !_thumbnail){
            _thumbnail = image;
            for (id <DVRemoteClientDelegate> delegate in _delegates){
                if ([delegate respondsToSelector:@selector(dvrClient:didRecieveCurrentThumbnail:)]){
                    [delegate dvrClient:self didRecieveCurrentThumbnail:image];
                }
            }
        }
        for (id <DVRemoteClientDelegate> delegate in _delegates){
            if ([delegate respondsToSelector:@selector(dvrClient:didRecieveThumbnail:ofId:inDocument:withIndex:)]){
                [delegate dvrClient:self didRecieveThumbnail:image
                               ofId:[args valueForKey:DVRCNMETA_ID]
                         inDocument:[args valueForKey:DVRCNMETA_DOCUMENT]
                          withIndex:[[args valueForKey:DVRCNMETA_INDEX_IN_PARENT] intValue]];
            }
        }
    }else if (command == DVRC_NOTIFY_FULLIMAGE){
        //-----------------------------------------------------------------------------------------
        // フル画像受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSData* tiffData = [args valueForKey:DVRCNMETA_FULLIMAGE];
        UIImage* image = [UIImage imageWithData:tiffData];
        if ([self compareWithMeta:_meta andMeta:args] && !_fullImage){
            _fullImage = image;
            _imageRotation = [[args valueForKey:DVRCNMETA_IMAGEROTATION] intValue];
        }
        for (id <DVRemoteClientDelegate> delegate in _delegates){
            if ([delegate respondsToSelector:@selector(dvrClient:didRecieveFullImage:ofId:inDocument:withRotation:)]){
                [delegate dvrClient:self didRecieveFullImage:image
                               ofId:[args valueForKey:DVRCNMETA_ID]
                         inDocument:[args valueForKey:DVRCNMETA_DOCUMENT]
                       withRotation:[[args valueForKey:DVRCNMETA_IMAGEROTATION] intValue]];
            }
        }
    }else if (command == DVRC_NOTIFY_FOLDER_ITEMS){
        //-----------------------------------------------------------------------------------------
        // フォルダ内要素一覧受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([self compareWithMeta:args andMetasParent:_meta]){
            _nodeListWrap = args;
        }
        NSArray* nodeList = [args valueForKey:DVRCNMETA_ITEM_LIST];
        NSArray* nodeID = [args valueForKey:DVRCNMETA_ID];
        NSString* document = [args valueForKey:DVRCNMETA_DOCUMENT];
        NSString* key = [self keyForID:nodeID inDocument:document];
        [_nodeListCache setValue:nodeList forKey:key];
        for (id <DVRemoteClientDelegate> delegate in _delegates){
            if ([delegate respondsToSelector:@selector(dvrClient:didRecieveNodeList:forNode:inDocument:)]){
                [delegate dvrClient:self didRecieveNodeList:nodeList forNode:nodeID inDocument:document];
            }
        }
    }else if (command == DVRC_NOTIFY_SERVER_INFO){
        //-----------------------------------------------------------------------------------------
        // サーバー情報受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_tmpDelegate && [_tmpDelegate respondsToSelector:@selector(dvrClient:didRecieveServerInfo:)]){
            [_tmpDelegate dvrClient:self didRecieveServerInfo:args];
        }
    }else if (command == DVRC_NOTIFY_LENS_LIBRARY){
        //-----------------------------------------------------------------------------------------
        // レンズライブラリ受信
        //-----------------------------------------------------------------------------------------
        NSDictionary* args = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSData* libraryData = [args valueForKey:DVRCNMETA_LENS_LIBRARY];
        NSNumber* libraryDate = [args valueForKey:DVRCNMETA_LENS_LIBRARY_DATE];
        ConfigurationController* controller = ConfigurationController.sharedController;

        BOOL shouldBeUpdated = NO;
        if (!controller.lensLibrarySource){
            shouldBeUpdated = YES;
        }else if ([self.serviceName isEqualToString:controller.lensLibrarySource] &&
                  libraryDate.doubleValue > controller.lensLibraryDate){
            shouldBeUpdated = YES;
        }

        if (shouldBeUpdated){
            [LensLibrary updateLensLibraryWithData:libraryData];
            controller.lensLibrarySource = self.serviceName;
            controller.lensLibraryDate = libraryDate.doubleValue;
        }
    }
}

- (void)drvSession:(DVRemoteSession*)session shouldBeClosedByCause:(NSError*)error
{
    [self disconnect];
}

//-----------------------------------------------------------------------------------------
// 認証
//-----------------------------------------------------------------------------------------
- (void)requestAuthentication
{
    if (_isTemporary) return;
    
    UIDevice* device = [UIDevice currentDevice];
    NSDictionary* argBase =@{DVRCNMETA_DEVICE_ID: device.identifierForVendor.UUIDString,
                             DVRCNMETA_DEVICE_NAME: device.name,
                             DVRCNMETA_DEVICE_TYPE: device.localizedModel,
                             DVRCNMETA_DEVICE_CODE: _deviceCode};
    NSMutableDictionary* args = [NSMutableDictionary dictionaryWithDictionary: argBase];
    int cmd;
    if (_pairingKey){
        cmd = DVRC_CHARENGE_AUTH;
        [args setValue:_pairingKey forKey:DVRCNMETA_PAIRCODE];
    }else{
        cmd = DVRC_REQUEST_PAIRING;
    }
    [_session sendCommand:cmd withData:[NSKeyedArchiver archivedDataWithRootObject:args] replacingQue:YES];
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
- (BOOL) compareWithMeta:(NSDictionary*)meta1 andMetasParent:(NSDictionary*)meta2
{
    BOOL rc = YES;
    
    NSString* doc1 = [meta1 valueForKey:DVRCNMETA_DOCUMENT];
    NSString* doc2 = [meta2 valueForKey:DVRCNMETA_DOCUMENT];
    NSArray* path1 = [meta1 valueForKey:DVRCNMETA_ID];
    NSArray* path2 = [meta2 valueForKey:DVRCNMETA_ID];
    
    if ([doc1 isEqualToString:doc2] && path1.count == path2.count - 1){
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

- (NSString*)keyForID:(NSArray*)nodeID inDocument:(NSString*)document
{
    NSString* key = document;
    for (NSString* name in nodeID){
        key = [key stringByAppendingFormat:@"/%@", name];
    }
    return key;
}

//-----------------------------------------------------------------------------------------
// Watch Dog
//-----------------------------------------------------------------------------------------
- (void)startWatchDog
{
    if (_state == DVRClientConnected && !_runningWatchDog){
        _runningWatchDog = YES;
        NSInteger count = _watchDogCount;
        DVRemoteClient* __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (count == weakSelf.watchDogCount){
                weakSelf.runningWatchDog = NO;
                [weakSelf disconnect];
            }
        });
    }
}

- (void)endWatchDog
{
    _runningWatchDog = NO;
    _watchDogCount++;
}

@end
