//
//  GPSMapView.h
//  DigViewer
//
//  Created by opiopan on 2014/03/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "ImageMetadata.h"

@interface GPSMapView : NSView <WKUIDelegate, WKScriptMessageHandler>

@property (copy) NSString* apiKey;
@property (strong) GPSInfo* gpsInfo;
@property (copy) NSColor* fovColor;
@property (copy) NSColor* arrowColor;
@property (copy) NSNumber* fovGrade;
@property (nonatomic, copy) NSNumber* mapType;
@property (nonatomic) NSNumber* tilt;
@property (nonatomic) NSNumber* zoomLevel;
@property (nonatomic) NSNumber* spanLatitude;
@property (nonatomic) NSNumber* spanLongitude;
@property bool enableStreetView;
@property bool enableHomePosition;

@property (weak, nonatomic) id delegate;
@property (nonatomic) SEL notifyChangeZoomSelector;

@end
