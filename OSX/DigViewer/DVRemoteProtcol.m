//
//  DVRemoteProtcol.m
//  DigViewer
//
//  Created by opiopan on 2015/09/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "DVRemoteProtcol.h"

NSString* DVR_SERVICE_TYPE = @"_dv-remote._tcp";
NSString* DVR_SERVICE_NAME = @"DigViewer Remote";

//-----------------------------------------------------------------------------------------
// Dictionary Key文字列
//-----------------------------------------------------------------------------------------
NSString* DVRCNMETA_DOCUMENT = @"document";
NSString* DVRCNMETA_ID = @"id";
NSString* DVRCNMETA_IDS = @"ids";
NSString* DVRCNMETA_LATITUDE = @"latitude";
NSString* DVRCNMETA_LONGITUDE = @"longitude";
NSString* DVRCNMETA_ALTITUDE = @"altitude";
NSString* DVRCNMETA_HEADING = @"heading";
NSString* DVRCNMETA_SPAN_LATITUDE = @"spanLatitude";
NSString* DVRCNMETA_SPAN_LONGITUDE = @"spanLongitude";
NSString* DVRCNMETA_SPAN_LATITUDE_METER = @"spanLatitudeMeter";
NSString* DVRCNMETA_SPAN_LONGITUDE_METER = @"spanLongitudeMeter";
NSString* DVRCNMETA_VIEW_LATITUDE = @"viewLatitude";
NSString* DVRCNMETA_VIEW_LONGITUDE = @"viewLongitude";
NSString* DVRCNMETA_STAND_LATITUDE = @"standLatitude";
NSString* DVRCNMETA_STAND_LONGITUDE = @"standLongitude";
NSString* DVRCNMETA_STAND_ALTITUDE = @"standaAltitude";
NSString* DVRCNMETA_TILT = @"tilt";
NSString* DVRCNMETA_SUMMARY = @"summary";
NSString* DVRCNMETA_GPS_SUMMARY = @"gpsSummary";
NSString* DVRCNMETA_THUMBNAIL = @"thumbnail";
NSString* DVRCNMETA_FULLIMAGE = @"fullimage";
NSString* DVRCNMETA_IMAGESIZEMAX = @"imagesizemax";
NSString* DVRCNMETA_IMAGEROTATION = @"imagerotation";
NSString* DVRCNMETA_ITEM_LIST = @"itemlist";
NSString* DVRCNMETA_ITEM_NAME = @"itemname";
NSString* DVRCNMETA_ITEM_IS_FOLDER = @"itemisfolder";
NSString* DVRCNMETA_ITEM_TYPE = @"itemtype";
NSString* DVRCNMETA_INDEX_IN_PARENT = @"indexinparent";
NSString* DVRCNMETA_POPUP_SUMMARY = @"popupsummary";
NSString* DVRCNMETA_LOCAL_ID = @"localid";
NSString* DVRCNMETA_FOV_ANGLE = @"fovangle";
NSString* DVRCNMETA_SERVER_ICON = @"servericon";
NSString* DVRCNMETA_SERVER_IMAGE = @"serverimage";
NSString* DVRCNMETA_SERVER_INFO = @"serverinfo";
NSString* DVRCNMETA_MACHINE_NAME = @"machinename";
NSString* DVRCNMETA_CPU = @"cpu";
NSString* DVRCNMETA_MEMORY_SIZE = @"memorysize";
NSString* DVRCNMETA_DESCRIPTION = @"description";
NSString* DVRCNMETA_DV_VERSION = @"dvverstion";
NSString* DVRCNMETA_OS_VERSION = @"osversion";
NSString* DVRCNMETA_GPU = @"gpu";
NSString* DVRCNMETA_GPU_CORE_NUM = @"gpucorenum";
NSString* DVRCNMETA_CPU_CORE_NUM = @"cpucorenum";
NSString* DVRCNMETA_PAIRCODE = @"paircode";
NSString* DVRCNMETA_DEVICE_ID = @"deviceid";
NSString* DVRCNMETA_DEVICE_NAME = @"devicename";
NSString* DVRCNMETA_DEVICE_TYPE = @"devicetype";
NSString* DVRCNMETA_DEVICE_CODE = @"devicecode";
NSString* DVRCNMETA_NAMESPACE_CHANGED = @"namespacechanged";
NSString* DVRCNMETA_ENTITY_CHANGED= @"entitychanged";
NSString* DVRCNMETA_LENS_LIBRARY = @"lenslibrary";
NSString* DVRCNMETA_LENS_LIBRARY_DATE = @"lenslibrarydate";
