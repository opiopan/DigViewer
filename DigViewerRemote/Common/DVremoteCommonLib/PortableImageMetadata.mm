//
//  ImageMetadata+PortableData.m
//  DigViewerRemote
//
//  Created by opiopan on 2016/01/01.
//  Copyright © 2016年 opiopan. All rights reserved.
//


#import "PortableImageMetadata.h"
#import "DVRemoteProtcol.h"
#import "CoreFoundationHelper.h"
#import "ImageMetadata.h"

@implementation PortableImageMetadata

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)initWithImage:(NSData *)imageData name:(NSString *)name type:(NSString *)type
{
    self = [super init];
    if (self){
        _imageData = imageData;
        _name = name;
        _type = type;
        _namespaceChanged = NO;
        _entityChanged = YES;
    }
    return self;
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
// DV Remote Protocolに載せられる可搬データ生成
//-----------------------------------------------------------------------------------------
- (NSDictionary *)portableData
{
    ECGImageSourceRef imageSource(CGImageSourceCreateWithData((__bridge CFDataRef)(_imageData), NULL));
    ImageMetadata* meta = [[ImageMetadata alloc] initWithImage:imageSource name:_name typeName:_type];
    
    NSMutableDictionary* data = [NSMutableDictionary dictionary];
    [data setValue:_documentName forKey:DVRCNMETA_DOCUMENT];
    [data setValue:_path forKey:DVRCNMETA_ID];
    [data setValue:@(_indexInParent) forKey:DVRCNMETA_INDEX_IN_PARENT];
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
    [data setValue:@(_namespaceChanged) forKey:DVRCNMETA_NAMESPACE_CHANGED];
    [data setValue:@(_entityChanged) forKey:DVRCNMETA_ENTITY_CHANGED];
    
    ImageMetadata* smeta = [[ImageMetadata alloc] initWithImage:imageSource name:_name typeName:_type];
    NSArray* filter = @[@0, @5, @8, @11, @13, @14, @15];
    NSArray* summary = [smeta summaryWithFilter:filter];
    [data setValue:summary forKey:DVRCNMETA_POPUP_SUMMARY];

    return data;
}

@end
