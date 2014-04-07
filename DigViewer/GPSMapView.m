//
//  GPSMapView.m
//  DigViewer
//
//  Created by opiopan on 2014/03/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "GPSMapView.h"

@implementation GPSMapView{
    NSString*   _apiKey;
    GPSInfo*    _gpsInfo;
}

- (NSString*) apiKey
{
    return _apiKey;
}

- (void) setApiKey:(NSString *)apiKey
{
    _apiKey = [apiKey copy];
    WebScriptObject* win = [self windowScriptObject];
    [win setValue:self forKey:@"bridge"];
    
    NSString* htmlString = @
        "<!DOCTYPE html>"
        "<html>"
        "   <head>"
        "       <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\" />"
        "       <style type=\"text/css\">"
        "           html { height: 100%% }"
        "           body { height: 100%%; margin: 0; padding: 0 }"
        "           #map_canvas { height: 100%% }"
        "       </style>"
        "       <script type=\"text/javascript\""
        "           src=\"http://maps.googleapis.com/maps/api/js?key=%@&libraries=geometry,drawing&sensor=false\">"
        "       </script>"
        "       <script type=\"text/javascript\" src=\"GPSMapView.js\"></script>"
        "   </head>"
        "   <body onload=\"initialize()\">"
        "       <div id=\"map_canvas\" style=\"width:100%%; height:100%%\"></div>"
        "   </body>"
        "</html>";
    [[self mainFrame] loadHTMLString:[NSString stringWithFormat:htmlString, _apiKey]
                             baseURL:[[NSBundle mainBundle] resourceURL]];
    [self performSelector:@selector(reflectGpsInfo) withObject:nil afterDelay:1];
}

- (GPSInfo*) gpsInfo
{
    return _gpsInfo;
}

- (void) setGpsInfo:(GPSInfo *)gpsInfo
{
    _gpsInfo = gpsInfo;
    WebScriptObject* window = [self windowScriptObject];
    NSString* script = nil;
    if (_gpsInfo){
        script = [NSString stringWithFormat:@"setMarker(%@, %@, %@);",
                  _gpsInfo.latitude, _gpsInfo.longitude,
                  _gpsInfo.imageDirection ? _gpsInfo.imageDirection : @"null"];
    }else{
        script = @"resetMarker();";
    }
    [window evaluateWebScript:script];
}

- (void) reflectGpsInfo
{
    if (_gpsInfo){
        self.gpsInfo = _gpsInfo;
    }
}
    
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(reflectGpsInfo)) return NO;
    return YES;
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    WebScriptObject* window = [self windowScriptObject];
    [window evaluateWebScript:@"setHeading();"];
}

@end
