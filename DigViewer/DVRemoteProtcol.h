//
//  DVRemoteProtcol.h
//  DigViewer
//
//  Created by opiopan on 2015/09/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* DVR_SERVICE_TYPE;
extern NSString* DVR_SERVICE_NAME;

typedef NS_ENUM(NSInteger, DVRCommand){
    DVRC_NA = -1,
    
    // Client -> Server
    DVRC_MOVE_NEXT_IMAGE = 1,
    DVRC_MOVE_PREV_IMAGE,
    DVRC_REQUEST_THUMBNAIL,
    
    // Server -> Client
    DVRC_NOTIFY_META = 1000,
    DVRC_NOTIFY_TEMPLATE_META,
    DVRC_NOTIFY_THUMBNAIL
};

//-----------------------------------------------------------------------------------------
// DVRC_NOTIFY_META用 Dictionary Key文字列
//-----------------------------------------------------------------------------------------
extern NSString* DVRCNMETA_DOCUMENT;
extern NSString* DVRCNMETA_ID;
extern NSString* DVRCNMETA_IDS;
extern NSString* DVRCNMETA_LATITUDE;
extern NSString* DVRCNMETA_LONGITUDE;
extern NSString* DVRCNMETA_ALTITUDE;
extern NSString* DVRCNMETA_HEADING;
extern NSString* DVRCNMETA_SPAN_LATITUDE;
extern NSString* DVRCNMETA_SPAN_LONGITUDE;
extern NSString* DVRCNMETA_SPAN_LATITUDE_METER;
extern NSString* DVRCNMETA_SPAN_LONGITUDE_METER;
extern NSString* DVRCNMETA_VIEW_LATITUDE;
extern NSString* DVRCNMETA_VIEW_LONGITUDE;
extern NSString* DVRCNMETA_STAND_LATITUDE;
extern NSString* DVRCNMETA_STAND_LONGITUDE;
extern NSString* DVRCNMETA_STAND_ALTITUDE;
extern NSString* DVRCNMETA_TILT;
extern NSString* DVRCNMETA_SUMMARY;
extern NSString* DVRCNMETA_GPS_SUMMARY;
extern NSString* DVRCNMETA_THUMBNAIL;
