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

#include "CorefoundationHelper.h"

static struct {
    PHAssetCollectionType type;
    PHAssetCollectionSubtype subType;
}AssetTypes[] = {
    PHAssetCollectionTypeSmartAlbum, PHAssetCollectionSubtypeSmartAlbumUserLibrary,
    PHAssetCollectionTypeSmartAlbum, PHAssetCollectionSubtypeSmartAlbumFavorites,
    PHAssetCollectionTypeAlbum, PHAssetCollectionSubtypeAlbumRegular,
    PHAssetCollectionTypeAlbum, PHAssetCollectionSubtypeAlbumSyncedAlbum,
    (PHAssetCollectionType)0, (PHAssetCollectionSubtype)0
};

@interface LSNode : NSObject
@property NSString* name;
@property NSArray* nodeID;
@property NSMutableArray* children;
@property PHAssetCollection* collection;
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
}

- (void)completeConnect
{
    _root = [LSNode new];
    _root.name = _topName;
    _root.nodeID = @[_topName];
    
    // 固定アルバムを設定
    for (int i = 0; AssetTypes[i].type != 0; i++){
        PHFetchResult* result = [PHAssetCollection fetchAssetCollectionsWithType:AssetTypes[i].type
                                                                         subtype:AssetTypes[i].subType
                                                                         options:nil];
        for (NSUInteger j = 0; j < result.count; j++){
            PHAssetCollection* collection = [result objectAtIndex:j];
            LSNode* node = [LSNode new];
            node.name = collection.localizedTitle;
            node.nodeID = [_root.nodeID arrayByAddingObject:node.name];
            node.collection = collection;
            [_root.children addObject:node];
        }
    }
    _currentNode = _root.children[0];
    _currentCollectionPath = @[_topName, _currentNode.name];
    _currentAssets = [PHAsset fetchAssetsInAssetCollection:_currentNode.collection options:_assetsFetchOptions];
    _currentIndexInAssets = _currentAssets.count > 0 ? _currentAssets.count - 1 : 0;
    
    // スマートコレクションリストに含まれるアルバムをツリーに追加
    PHFetchResult* smartFolderList = [PHCollectionList fetchCollectionListsWithType:PHCollectionListTypeSmartFolder
                                                                            subtype:PHCollectionListSubtypeAny options:nil];
    for (PHCollectionList* list in smartFolderList){
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
    }
    
    // 接続完了を返却
    if (_delegate){
        [_delegate dvrSession:nil recieveCommand:DVRC_NOTIFY_ACCEPTED withData:nil];
        ImageMetadata* meta = [ImageMetadata new];
        NSArray* summary = meta.summary;
        NSArray* gpsInfo = meta.gpsInfoStrings;
        NSDictionary* templateMeta = @{DVRCNMETA_SUMMARY:summary, DVRCNMETA_GPS_SUMMARY:gpsInfo};
        NSData* data = [NSKeyedArchiver archivedDataWithRootObject:templateMeta];
        [_delegate dvrSession:nil recieveCommand:DVRC_NOTIFY_TEMPLATE_META withData:data];
    }
    
    if (_currentAssets.count > 0){
        PHAsset* asset = _currentAssets[_currentIndexInAssets];
        LocalSession* __weak weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf notifyMetaForAsset:asset indexInParent:_currentIndexInAssets];
        });
    }
}

- (void)notifyClosed
{
    if (_delegate){
        [_delegate drvSession:nil shouldBeClosedByCause:nil];
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
{
    LocalSession* __weak weakSelf = self;
    [_imageManager requestImageDataForAsset:asset options:nil resultHandler:
     ^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
         [weakSelf notifyMetaForAsset:asset indexInParent:indexInParent imageData:imageData];
     }];
}

- (void)notifyMetaForAsset:(PHAsset*)asset indexInParent:(NSUInteger)indexInParent imageData:(NSData*)imageData
{
    NSString* name = [asset.localIdentifier substringToIndex:NAME_CLIP_LENGTH];
    NSString* type = [self typeNameOfAsset:asset];
    ECGImageSourceRef imageSource(CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL));
    ImageMetadata* meta = [[ImageMetadata alloc] initWithImage:imageSource name:name typeName:type];
    
    NSMutableDictionary* data = [NSMutableDictionary dictionary];
    [data setValue:_documentName forKey:DVRCNMETA_DOCUMENT];
    NSArray* path = [_currentCollectionPath arrayByAddingObject:asset.localIdentifier];
    [data setValue:path forKey:DVRCNMETA_ID];
    [data setValue:@(indexInParent) forKey:DVRCNMETA_INDEX_IN_PARENT];
    if (meta.gpsInfo){
        MapGeometry geometry = [self mapGeometory:meta.gpsInfo];

        [data setValue:@(geometry.latitude) forKey:DVRCNMETA_LATITUDE];
        [data setValue:@(geometry.longitude) forKey:DVRCNMETA_LONGITUDE];
        if (geometry.isEnableAltitude){
            [data setValue:@(geometry.altitude) forKey:DVRCNMETA_ALTITUDE];
        }
        if (geometry.isEnableHeading){
            [data setValue:@(geometry.heading) forKey:DVRCNMETA_HEADING];
        }
        [data setValue:@(geometry.spanLatitude) forKey:DVRCNMETA_SPAN_LATITUDE];
        [data setValue:@(geometry.spanLongitude) forKey:DVRCNMETA_SPAN_LONGITUDE];
        [data setValue:@(geometry.spanLatitudeMeter) forKey:DVRCNMETA_SPAN_LATITUDE_METER];
        [data setValue:@(geometry.spanLongitudeMeter) forKey:DVRCNMETA_SPAN_LONGITUDE_METER];

        [data setValue:meta.gpsInfoStrings forKey:DVRCNMETA_GPS_SUMMARY];
        
        if (meta.gpsInfo.fovLong){
            NSNumber* fovAngle = meta.gpsInfo.rotation.intValue < 5 ? meta.gpsInfo.fovLong : meta.gpsInfo.fovShort;
            [data setValue:fovAngle forKey:DVRCNMETA_FOV_ANGLE];
        }

    }
    [data setValue:meta.summary forKey:DVRCNMETA_SUMMARY];
    
    ImageMetadata* smeta = [[ImageMetadata alloc] initWithImage:imageSource name:name typeName:type];
    NSArray* filter = @[@0, @5, @8, @11, @13, @14, @15];
    NSArray* summary = [smeta summaryWithFilter:filter];
    [data setValue:summary forKey:DVRCNMETA_POPUP_SUMMARY];
    
    NSData* sdata = [NSKeyedArchiver archivedDataWithRootObject:data];
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
        if (target.collection){
            PHAssetCollection* collection = target.collection;
            PHFetchOptions* options = [PHFetchOptions new];
            options.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO]];
            options.fetchLimit = 1;
            PHFetchResult* repAssets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (repAssets.count > 0){
                image = [self.class thumbnailForAsset:repAssets[0] withSize:imageSize];
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
    if (_currentIndexInAssets + 1 < _currentAssets.count){
        _currentIndexInAssets++;
        PHAsset* asset = _currentAssets[_currentIndexInAssets];
        [self notifyMetaForAsset:asset indexInParent:_currentIndexInAssets];
    }
}

- (void)movePreviousAsset
{
    if (_currentIndexInAssets > 0){
        _currentIndexInAssets--;
        PHAsset* asset = _currentAssets[_currentIndexInAssets];
        [self notifyMetaForAsset:asset indexInParent:_currentIndexInAssets];
    }
}

- (void)moveToAssetWithID: (NSArray*)nodeID
{
    NSString* assetID = nodeID.lastObject;
    
    if (![self nodeID:_currentCollectionPath isEqualToParentOfNodeID:nodeID]){
        _currentNode = [self findNodeWithNodeID:nodeID forParent:YES];
        _currentCollectionPath = _currentNode.nodeID;
        _currentAssets = [PHAsset fetchAssetsInAssetCollection:_currentNode.collection options:_assetsFetchOptions];
        _currentIndexInAssets = 0;
    }
    
    for (int i = 0; i < _currentAssets.count; i++){
        PHAsset* asset = _currentAssets[i];
        if ([assetID isEqualToString:asset.localIdentifier]){
            _currentIndexInAssets = i;
            [self notifyMetaForAsset:asset indexInParent:_currentIndexInAssets];
            break;
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
    if (!target.collection){
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
    return target.collection;
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
