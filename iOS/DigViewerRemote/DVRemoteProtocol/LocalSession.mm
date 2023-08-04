//
//  LocalSession.m
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/11.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import <Photos/Photos.h>
#import "LocalSession.h"
#import "ImageMetadata.h"
#import "PortableImageMetadata.h"

#include "CorefoundationHelper.h"

static struct {
    PHAssetCollectionType type;
    PHAssetCollectionSubtype subType;
    NSString* folderName;
    BOOL needSort;
    BOOL prevailBottom;
}AssetTypes[] = {
    PHAssetCollectionTypeSmartAlbum, PHAssetCollectionSubtypeSmartAlbumUserLibrary, nil, NO, YES,
    PHAssetCollectionTypeSmartAlbum, PHAssetCollectionSubtypeSmartAlbumFavorites, nil, NO, NO,
    PHAssetCollectionTypeAlbum, PHAssetCollectionSubtypeAlbumRegular, nil, NO, NO,
    PHAssetCollectionTypeAlbum, PHAssetCollectionSubtypeAlbumSyncedAlbum, @"LS_SYNCED_ALBUM", YES, NO,
    (PHAssetCollectionType)0, (PHAssetCollectionSubtype)0, nil, NO, NO,
};

@interface LSNode : NSObject
@property NSString* name;
@property NSArray* nodeID;
@property NSMutableArray* children;
@property PHAssetCollection* collection;
@property BOOL enableSharedImage;
@property BOOL prevailBottom;
@end

@implementation LSNode
- (instancetype)init
{
    self = [super init];
    if (self){
        _children = [NSMutableArray array];
    }
    return self;
}
@end

@implementation LocalSession {
    NSURL* _sharedImage;
    BOOL _isConnected;
    
    PHFetchOptions* _assetsFetchOptions;
    PHImageManager* _imageManager;
    
    NSString* _documentName;
    NSString* _topName;
    LSNode* _root;
    LSNode* _currentNode;
    NSArray* _currentCollectionPath;
    PHFetchResult* _currentAssets;
    NSUInteger _currentIndexInAssets;
}

static const int NAME_CLIP_LENGTH = 13;

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _isConnected = NO;
        _documentName = @"document";
        _topName = NSLocalizedString(@"LS_TOP_FOLDER_NAME", nil);
        _assetsFetchOptions = [PHFetchOptions new];
        //_assetsFetchOptions.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:true]];
        _assetsFetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(PHAssetMediaTypeImage)];
        _imageManager = [PHImageManager defaultManager];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// アプリ間共有イメージの登録
//-----------------------------------------------------------------------------------------
- (void)registerSharedImage:(NSURL *)url
{
    _sharedImage = url;
    if (_isConnected){
        [self createSharedImageNode];
        LSNode* node = _root.children.lastObject;
        NSArray* nodeID = [node.nodeID arrayByAddingObject:NSLocalizedString(@"LS_APP_SHARED_IMAGE", nil)];
        LocalSession* __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf moveToAssetWithID:nodeID];
        });
    }
}

- (void) createSharedImageNode
{
    LSNode* target = _root.children.lastObject;
    if (!target.enableSharedImage){
        LSNode* sharedNode = [LSNode new];
        sharedNode.name = NSLocalizedString(@"LS_APP_SHARED_FOLDER_NAME", nil);
        sharedNode.nodeID = [_root.nodeID arrayByAddingObject:sharedNode.name];
        sharedNode.enableSharedImage = YES;
        sharedNode.prevailBottom = NO;
        [_root.children addObject:sharedNode];
    }
}

//-----------------------------------------------------------------------------------------
// 接続
//-----------------------------------------------------------------------------------------
- (void)connect
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized){
        [self completeConnect];
    }else if (status == PHAuthorizationStatusNotDetermined){
        LocalSession* __weak weakSelf = self;
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            if (status == PHAuthorizationStatusAuthorized){
                [weakSelf completeConnect];
            }else{
                [weakSelf notifyClosed];
            }
        }];
    }else{
        LocalSession* __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf notifyClosed];
        });
    }
    _isConnected = YES;
}

- (void)completeConnect
{
    // 名前空間読み込み
    [self loadNamespace];
    
    // カレントノードを設定
    [self resetCurrentNode];
    
    // 画像ライブラリの変更を監視
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
    
    // 接続完了を返却
    if (_delegate){
        [_delegate dvrSession:nil recieveCommand:DVRC_NOTIFY_ACCEPTED withData:nil];
        ImageMetadata* meta = [ImageMetadata new];
        NSArray* summary = meta.summary;
        NSArray* gpsInfo = meta.gpsInfoStrings;
        NSDictionary* templateMeta = @{DVRCNMETA_SUMMARY:summary, DVRCNMETA_GPS_SUMMARY:gpsInfo};
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:templateMeta
                                             requiringSecureCoding:YES error:nil];
        [_delegate dvrSession:nil recieveCommand:DVRC_NOTIFY_TEMPLATE_META withData:data];
    }
    
    if (_sharedImage || _currentAssets.count > 0){
        PHAsset* asset = _sharedImage ? nil : _currentAssets[_currentIndexInAssets];
        LocalSession* __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            LocalSession* strongSelf = weakSelf;
            [strongSelf notifyMetaForAsset:asset indexInParent:strongSelf->_currentIndexInAssets
                        namespaceChanged:NO entityChanged:YES];
        });
    }
}

- (void)loadNamespace
{
    _root = [LSNode new];
    _root.name = _topName;
    _root.nodeID = @[_topName];
    
    // 固定アルバムを設定
    for (int i = 0; AssetTypes[i].type != 0; i++){
        PHFetchResult* result = [PHAssetCollection fetchAssetCollectionsWithType:AssetTypes[i].type
                                                                         subtype:AssetTypes[i].subType
                                                                         options:nil];
        LSNode* parent = _root;
        if (AssetTypes[i].folderName){
            parent = [LSNode new];
            parent.name = NSLocalizedString(AssetTypes[i].folderName, nil);
            parent.nodeID = [_root.nodeID arrayByAddingObject:parent.name];
            parent.prevailBottom = NO;
            [_root.children addObject:parent];
        }
        NSMutableArray* currentNodes = [NSMutableArray new];
        for (NSUInteger j = 0; j < result.count; j++){
            PHAssetCollection* collection = [result objectAtIndex:j];
            LSNode* node = [LSNode new];
            node.name = collection.localizedTitle;
            node.nodeID = [parent.nodeID arrayByAddingObject:node.name];
            node.collection = collection;
            node.prevailBottom = AssetTypes[i].prevailBottom;
            [currentNodes addObject:node];
        }
        if (AssetTypes[i].needSort) {
            [parent.children addObjectsFromArray:[currentNodes sortedArrayUsingComparator:^(LSNode* obj1, LSNode* obj2){
                return [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch | NSNumericSearch];
            }]];
            
        }else{
            [parent.children addObjectsFromArray:currentNodes];
        }
    }
    
    // スマートコレクションリストに含まれるアルバムをツリーに追加
    PHFetchResult* collectionLists[2];
    collectionLists[0] = [PHCollectionList fetchCollectionListsWithType:PHCollectionListTypeFolder
                                                                subtype:PHCollectionListSubtypeAny options:nil];
    collectionLists[1] = [PHCollectionList fetchCollectionListsWithType:PHCollectionListTypeSmartFolder
                                                                subtype:PHCollectionListSubtypeAny options:nil];
    for (int i = 0; i < 2; i++){
        for (PHCollectionList* list in collectionLists[i]){
            LSNode* node = [LSNode new];
            node.name = list.localizedTitle;
            node.nodeID = [_root.nodeID arrayByAddingObject:node.name];
            [_root.children addObject:node];
            
            PHFetchResult* collections = [PHAssetCollection fetchCollectionsInCollectionList:list options:nil];
            for (PHAssetCollection* collection in collections){
                LSNode* child = [LSNode new];
                child.name = collection.localizedTitle;
                child.nodeID = [node.nodeID arrayByAddingObject:child.name];
                child.collection = collection;
                [node.children addObject:child];
            }
            NSArray* sortedChildren = [node.children sortedArrayUsingComparator:^(LSNode* obj1, LSNode* obj2){
                return [obj1.name compare:obj2.name];
            }];
            node.children = [NSMutableArray arrayWithArray:sortedChildren];
        }
    }
}

- (void)resetCurrentNode
{
    if (_sharedImage){
        [self createSharedImageNode];
        _currentNode = _root.children.lastObject;
        _currentAssets = nil;
        _currentIndexInAssets = 0;
    }else{
        _currentNode = _root.children[0];
        _currentAssets = [PHAsset fetchAssetsInAssetCollection:_currentNode.collection options:_assetsFetchOptions];
        _currentIndexInAssets = _currentAssets.count > 0 ? _currentAssets.count - 1 : 0;
    }
    _currentCollectionPath = _currentNode.nodeID;
}

- (void)notifyClosed
{
    if (_delegate){
        [_delegate drvSession:nil shouldBeClosedByCause:nil];
    }
    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
}

//-----------------------------------------------------------------------------------------
// 画像ライブラリの変更通知
//-----------------------------------------------------------------------------------------
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    LSNode* currentNode = _currentNode;
    PHFetchResult* currentAssets = _currentAssets;
    NSUInteger currentIndexInAssets = _currentIndexInAssets;
    
    BOOL shouldBeReset = NO;
    if (_currentAssets){
        long offset = 0;
        PHFetchResultChangeDetails* detail = [changeInstance changeDetailsForFetchResult:currentAssets];
        if (detail && detail.removedIndexes){
            for (NSUInteger index = detail.removedIndexes.firstIndex;
                 index != NSNotFound;
                 index = [detail.removedIndexes indexGreaterThanIndex:index]){
                if (index < currentIndexInAssets){
                    offset--;
                }else if (index == currentIndexInAssets){
                    shouldBeReset = YES;
                    break;
                }else{
                    break;
                }
            }
        }
        if (detail && detail.insertedIndexes && !shouldBeReset){
            for (NSUInteger index = detail.insertedIndexes.firstIndex;
                 index != NSNotFound;
                 index = [detail.insertedIndexes indexGreaterThanIndex:index]){
                if (index < currentIndexInAssets){
                    offset++;
                }else{
                    break;
                }
            }
        }
        currentIndexInAssets += offset;
    }
    
    [self loadNamespace];

    if (!shouldBeReset){
        _currentNode = [self findNodeWithNodeID:currentNode.nodeID forParent:NO];
        if (_currentNode){
            _currentAssets = [PHAsset fetchAssetsInAssetCollection:_currentNode.collection options:_assetsFetchOptions];
            _currentIndexInAssets = currentIndexInAssets;
        }else{
            shouldBeReset = YES;
        }
    }
    
    if (shouldBeReset){
        [self resetCurrentNode];
    }
    
    if (_delegate){
        LocalSession* __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            LocalSession* strongSelf = weakSelf;
            if (strongSelf->_sharedImage || strongSelf->_currentAssets.count > 0){
                PHAsset* asset = strongSelf->_currentAssets ? strongSelf->_currentAssets[strongSelf->_currentIndexInAssets] : nil;
                [weakSelf notifyMetaForAsset:asset indexInParent:strongSelf->_currentIndexInAssets
                            namespaceChanged:YES entityChanged:shouldBeReset];
            }
        });
    }
}

//-----------------------------------------------------------------------------------------
// 地図表示用ジオメトリ情報算出
//-----------------------------------------------------------------------------------------
struct _MapGeometry{
    double latitude;
    double longitude;
    double altitude;
    BOOL   isEnableAltitude;
    double heading;
    BOOL   isEnableHeading;
    double spanLatitude;
    double spanLongitude;
    double spanLatitudeMeter;
    double spanLongitudeMeter;
};
typedef struct _MapGeometry MapGeometry;

static const CGFloat SPAN_IN_METER = 450.0;

- (MapGeometry)mapGeometory:(GPSInfo*)gpsInfo
{
    MapGeometry rc;
    rc.latitude = gpsInfo.latitude.doubleValue;
    rc.longitude = gpsInfo.longitude.doubleValue;
    if (gpsInfo.altitude){
        rc.altitude = gpsInfo.altitude.doubleValue;
        rc.isEnableAltitude = YES;
    }else{
        rc.altitude = 0;
        rc.isEnableAltitude = NO;
    }
    if (gpsInfo.imageDirection){
        rc.heading = gpsInfo.imageDirection.doubleValue;
        rc.isEnableHeading = YES;
    }else{
        rc.heading = 0;
        rc.isEnableHeading = NO;
    }
   
    rc.spanLatitude = SPAN_IN_METER / 111000.0;
    rc.spanLongitude = SPAN_IN_METER / 111000.0 / fabs(cos(rc.latitude / 180.0 * M_PI));
    rc.spanLatitudeMeter = SPAN_IN_METER;
    rc.spanLongitudeMeter = SPAN_IN_METER;
    
    return rc;
}

//-----------------------------------------------------------------------------------------
// メタ送信
//-----------------------------------------------------------------------------------------
- (void)notifyMetaForAsset:(PHAsset*)asset indexInParent:(NSUInteger)indexInParent
          namespaceChanged:(BOOL)namespaceChanged entityChanged:(BOOL)entityChanged
{
    LocalSession* __weak weakSelf = self;
    if (asset){
        [_imageManager requestImageDataAndOrientationForAsset:asset options:nil resultHandler:
         ^(NSData *imageData, NSString *dataUTI, CGImagePropertyOrientation orientation, NSDictionary *info) {
             [weakSelf notifyMetaForAsset:asset indexInParent:indexInParent imageData:imageData
                         namespaceChanged:namespaceChanged entityChanged:entityChanged];
         }];
    }else{
        NSData* imageData = [NSData dataWithContentsOfURL:_sharedImage];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf notifyMetaForAsset:asset indexInParent:indexInParent imageData:imageData
                        namespaceChanged:namespaceChanged entityChanged:entityChanged];
        });
    }
}

- (void)notifyMetaForAsset:(PHAsset*)asset indexInParent:(NSUInteger)indexInParent imageData:(NSData*)imageData
          namespaceChanged:(BOOL)namespaceChanged entityChanged:(BOOL)entityChanged
{
    NSString* name;
    NSString* type;
    NSArray* path;
    if (asset){
        name = [asset.localIdentifier substringToIndex:NAME_CLIP_LENGTH];
        type = [self typeNameOfAsset:asset];
        path = [_currentCollectionPath arrayByAddingObject:asset.localIdentifier];
    }else{
        name = NSLocalizedString(@"LS_APP_SHARED_IMAGE", nil);
        type = NSLocalizedString(@"LS_IMAGE_TYPE_NAME", nil);
        path = [_currentCollectionPath arrayByAddingObject:name];
    }

    PortableImageMetadata* meta = [[PortableImageMetadata alloc] initWithImage:imageData name:name type:type];
    meta.documentName = _documentName;
    meta.path = path;
    meta.indexInParent = indexInParent;
    meta.namespaceChanged = namespaceChanged;
    meta.entityChanged = entityChanged;
    
    NSData* sdata = [NSKeyedArchiver archivedDataWithRootObject:meta.portableData
                                          requiringSecureCoding:YES error:nil];
    [_delegate dvrSession:nil recieveCommand:DVRC_NOTIFY_META withData:sdata];
}

//-----------------------------------------------------------------------------------------
// サムネール抽出
//-----------------------------------------------------------------------------------------
static const CGFloat THUMBNAIL_SIZE = 100;

- (UIImage *)thumbnailForID:(NSArray *)nodeID
{
    return [self thumbnailForID:nodeID withSize:THUMBNAIL_SIZE * [UIScreen mainScreen].scale];
}

- (UIImage *)thumbnailForID:(NSArray *)nodeID withSize:(CGFloat)imageSize
{
    UIImage *image = nil;

    NSString* identifier = nodeID.lastObject;
    PHFetchResult* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (assets.count > 0){
        PHAsset* asset = assets[0];
        image = [self.class thumbnailForAsset:asset withSize:imageSize];
    }else{
        LSNode* target = [self findNodeWithNodeID:nodeID forParent:NO];
        if (target.enableSharedImage){
            image = [UIImage imageWithContentsOfFile:_sharedImage.path];
        }else if (target.collection){
            PHAssetCollection* collection = target.collection;
            PHFetchResult* repAssets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            if (repAssets.count > 0){
                unsigned long index = target.prevailBottom ? repAssets.count - 1 : repAssets.count / 2;
                image = [self.class thumbnailForAsset:repAssets[index] withSize:imageSize];
            }
        }else{
            if (target.children.count > 0){
                LSNode* child = target.children[0];
                image = [self thumbnailForID:child.nodeID withSize:imageSize];
            }
        }
    }
    
    return image;
}

+ (UIImage*)thumbnailForAsset:(PHAsset*)asset withSize:(CGFloat)imageSize
{
    __block UIImage *image = nil;

    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:CGSizeMake(imageSize, imageSize)
                                              contentMode:PHImageContentModeAspectFill
                                                  options:options
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                image = result;
                                            }
     ];
    
    return image;
}

//-----------------------------------------------------------------------------------------
// フル画像抽出
//-----------------------------------------------------------------------------------------
- (UIImage *)fullImageForID:(NSArray *)nodeID
{
    return [self thumbnailForID:nodeID withSize:1500];
}

//-----------------------------------------------------------------------------------------
// ノード移動
//-----------------------------------------------------------------------------------------
- (void)moveNextAsset
{
    if (_currentAssets && _currentIndexInAssets + 1 < _currentAssets.count){
        _currentIndexInAssets++;
        PHAsset* asset = _currentAssets[_currentIndexInAssets];
        [self notifyMetaForAsset:asset indexInParent:_currentIndexInAssets
                namespaceChanged:NO entityChanged:YES];
    }
}

- (void)movePreviousAsset
{
    if (_currentAssets && _currentIndexInAssets > 0){
        _currentIndexInAssets--;
        PHAsset* asset = _currentAssets[_currentIndexInAssets];
        [self notifyMetaForAsset:asset indexInParent:_currentIndexInAssets
                namespaceChanged:NO entityChanged:YES];
    }
}

- (void)moveToAssetWithID: (NSArray*)nodeID
{
    NSString* assetID = nodeID.lastObject;
    
    if (![self nodeID:_currentCollectionPath isEqualToParentOfNodeID:nodeID]){
        _currentNode = [self findNodeWithNodeID:nodeID forParent:YES];
        _currentCollectionPath = _currentNode.nodeID;
        if (_currentNode.enableSharedImage){
            _currentAssets = nil;
        }else{
            _currentAssets = [PHAsset fetchAssetsInAssetCollection:_currentNode.collection options:_assetsFetchOptions];
        }
        _currentIndexInAssets = 0;
    }

    if (_currentNode.enableSharedImage){
        [self notifyMetaForAsset:nil indexInParent:_currentIndexInAssets
                namespaceChanged:NO entityChanged:YES];
    }else{
        for (int i = 0; i < _currentAssets.count; i++){
            PHAsset* asset = _currentAssets[i];
            if ([assetID isEqualToString:asset.localIdentifier]){
                _currentIndexInAssets = i;
                [self notifyMetaForAsset:asset indexInParent:_currentIndexInAssets
                        namespaceChanged:NO entityChanged:YES];
                break;
            }
        }
    }
}

//-----------------------------------------------------------------------------------------
// ノードリスト返却
//-----------------------------------------------------------------------------------------
- (NSArray *)nodeListForID:(NSArray *)nodeID
{
    LSNode* target = [self findNodeWithNodeID:nodeID forParent:NO];
    
    NSMutableArray* rc = nil;
    if (target.enableSharedImage){
        rc = [NSMutableArray array];
        NSDictionary* nodeAttrs = @{DVRCNMETA_ITEM_NAME: NSLocalizedString(@"LS_APP_SHARED_IMAGE", nil),
                                    DVRCNMETA_ITEM_TYPE: NSLocalizedString(@"LS_IMAGE_TYPE_NAME", nil),
                                    DVRCNMETA_ITEM_IS_FOLDER: @(NO),
                                    DVRCNMETA_LOCAL_ID: NSLocalizedString(@"LS_APP_SHARED_IMAGE", nil)};
        [rc addObject:nodeAttrs];
    }else if (!target.collection){
        rc = [NSMutableArray array];
        for (LSNode* child in target.children){
            NSDictionary* nodeAttrs = @{DVRCNMETA_ITEM_NAME: child.name,
                                        DVRCNMETA_ITEM_TYPE: NSLocalizedString(@"LS_TYPESTRING_ALBUM", nil),
                                        DVRCNMETA_ITEM_IS_FOLDER: @(YES),
                                        /*DVRCNMETA_LOCAL_ID: collection.localIdentifier*/};
            [rc addObject:nodeAttrs];
        }
    }else{
        rc = [NSMutableArray array];
        PHFetchResult* assets = [PHAsset fetchAssetsInAssetCollection:target.collection options:_assetsFetchOptions];
        for (PHAsset* asset in assets){
            NSDate* date = asset.creationDate;
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateStyle = NSDateFormatterMediumStyle;
            dateFormatter.timeStyle = NSDateFormatterMediumStyle;
            NSString *formattedDateString = [dateFormatter stringFromDate:date];
            
            NSDictionary* nodeAttrs = @{DVRCNMETA_ITEM_NAME: formattedDateString,
                                        DVRCNMETA_ITEM_TYPE: [self typeNameOfAsset:asset],
                                        DVRCNMETA_ITEM_IS_FOLDER: @(NO),
                                        DVRCNMETA_LOCAL_ID: asset.localIdentifier};
            [rc addObject:nodeAttrs];
        }
    }
    
    return rc;
}

- (PHFetchResult*)assetsForID:(NSArray*)nodeID
{
    PHFetchResult* assets = nil;
    LSNode* target = [self findNodeWithNodeID:nodeID forParent:NO];
    if (target.collection){
        assets = [PHAsset fetchAssetsInAssetCollection:target.collection options:_assetsFetchOptions];
    }
    return assets;
}

- (BOOL)isAssetCollection:(NSArray*)nodeID
{
    LSNode* target = [self findNodeWithNodeID:nodeID forParent:NO];
    return target.collection != nil;
}

//-----------------------------------------------------------------------------------------
// パス操作
//-----------------------------------------------------------------------------------------
- (BOOL)nodeID:(NSArray*)src isEqualToParentOfNodeID:(NSArray*)dest
{
    BOOL rc = NO;
    if (src.count == dest.count - 1){
        rc = YES;
        for (int i = 0; i < src.count; i++){
            if (![src[i] isEqualToString:dest[i]]){
                rc = NO;
                break;
            }
        }
    }
    return rc;
}

- (LSNode*)findNodeWithNodeID:(NSArray*)nodeID forParent:(BOOL)forParent
{
    NSUInteger limit = forParent ? nodeID.count - 1 : nodeID.count;
    LSNode* current = _root;
    for (int i = 1; i < limit; i++){
        NSString* name = nodeID[i];
        for (LSNode* target in current.children){
            if ([target.name isEqualToString:name]){
                current = target;
                break;
            }
        }
    }
    return current;
}

//-----------------------------------------------------------------------------------------
// 画像タイプ文字列生成
//-----------------------------------------------------------------------------------------
- (NSString*)typeNameOfAsset:(PHAsset*)asset
{
    if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoScreenshot){
        return NSLocalizedString(@"LS_SCREENSHOTIMAGE_TYPE_NAME", nil);
    }else if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoPanorama){
        return NSLocalizedString(@"LS_PANORAMAIMAGE_TYPE_NAME", nil);
    }else if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoHDR){
        return NSLocalizedString(@"LS_HDRIMAGE_TYPE_NAME", nil);
    }else if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive){
        return NSLocalizedString(@"LS_LIVEIMAGE_TYPE_NAME", nil);
    }else{
        return NSLocalizedString(@"LS_IMAGE_TYPE_NAME", nil);
    }
}

@end
