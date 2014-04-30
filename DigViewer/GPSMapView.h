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

@interface GPSMapView : WebView

@property (copy) NSString* apiKey;
@property (strong) GPSInfo* gpsInfo;
@property (copy) NSColor* fovColor;
@property (copy) NSColor* arrowColor;

@end
