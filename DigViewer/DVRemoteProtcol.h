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
    DVRC_REQUEST_FULLIMAGE,
    DVRC_MAIN_CONNECTION,
    DVRC_SIDE_CONNECTION,
    DVRC_REQUEST_FOLDER_ITEMS,
    DVRC_MOVE_NODE,
    DVRC_REQUEST_SEVER_INFO,
    
    // Server -> Client
    DVRC_NOTIFY_META = 1000,
    DVRC_NOTIFY_TEMPLATE_META,
    DVRC_NOTIFY_THUMBNAIL,
    DVRC_NOTIFY_FULLIMAGE,
    DVRC_NOTIFY_ACCEPTED,
    DVRC_NOTIFY_FOLDER_ITEMS,
    DVRC_NOTIFY_SERVER_INFO,
};

//-----------------------------------------------------------------------------------------
// Dictionary Key文字列
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
extern NSString* DVRCNMETA_POPUP_SUMMARY;
extern NSString* DVRCNMETA_THUMBNAIL;
extern NSString* DVRCNMETA_FULLIMAGE;
extern NSString* DVRCNMETA_IMAGESIZEMAX;
extern NSString* DVRCNMETA_IMAGEROTATION;
extern NSString* DVRCNMETA_ITEM_LIST;
extern NSString* DVRCNMETA_ITEM_NAME;
extern NSString* DVRCNMETA_ITEM_IS_FOLDER;
extern NSString* DVRCNMETA_ITEM_TYPE;
extern NSString* DVRCNMETA_INDEX_IN_PARENT;
extern NSString* DVRCNMETA_LOCAL_ID;
extern NSString* DVRCNMETA_FOV_ANGLE;
extern NSString* DVRCNMETA_SERVER_ICON;
extern NSString* DVRCNMETA_SERVER_IMAGE;
extern NSString* DVRCNMETA_SERVER_INFO;
extern NSString* DVRCNMETA_MACHINE_NAME;
extern NSString* DVRCNMETA_CPU;
extern NSString* DVRCNMETA_MEMORY_SIZE;
extern NSString* DVRCNMETA_DESCRIPTION;
extern NSString* DVRCNMETA_DV_VERSION;
extern NSString* DVRCNMETA_OS_VERSION;
extern NSString* DVRCNMETA_GPU;
extern NSString* DVRCNMETA_CPU_CORE_NUM;
