//
//  InspectorViewController.m
//  DigViewer
//
//  Created by opiopan on 2014/02/16.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "InspectorViewController.h"
#import "PathNode.h"
#import "ImageMetadata.h"
#import "NSWindow+TracingResponderChain.h"


@interface InspectorViewController ()

@end

@implementation InspectorViewController{
    int     _viewSelector;
    bool    _initialized;
    NSDictionary* _preferences;
}

- (id)init
{
    self = [super initWithNibName:@"InspectorView" bundle:nil];
    if (self) {
        _initialized = nil;
    }
    return self;
}

- (void) awakeFromNib
{
    // EXIF用テーブルビューの第一カラムの幅を決定
    NSCell* cell = self.keyColumn.dataCell;
    NSFont* font = cell.font;
    NSDictionary* attributes = @{NSFontAttributeName:font};
    ImageMetadata* meta = [[ImageMetadata alloc] init];
    NSArray* summary = meta.summary;
    CGFloat width = 0;
    for (int i = 0; i < summary.count; i++){
        ImageMetadataKV* kv = summary[i];
        NSSize size = [kv.key sizeWithAttributes:attributes];
        if (size.width > width){
            width = size.width;
        }
    }
    [self.keyColumn setWidth:width + 10.0];

    // GPS用テーブルビューの第一カラムの幅を決定
    cell = self.gpsKeyColumn.dataCell;
    font = cell.font;
    attributes = @{NSFontAttributeName:font};
    meta = [[ImageMetadata alloc] init];
    NSArray* gpsInfo = meta.gpsInfoStrings;
    width = 0;
    for (int i = 0; i < gpsInfo.count; i++){
        ImageMetadataKV* kv = gpsInfo[i];
        NSSize size = [kv.key sizeWithAttributes:attributes];
        if (size.width > width){
            width = size.width;
        }
    }
    [self.gpsKeyColumn setWidth:width + 10.0];
    
    // Google Map表示に関わる設定変更を監視するobserverを登録
    [self reflectMapFovColor];
    [self reflectMapArrowColor];
    [self reflectMapFovGrade];
    [self reflectMapType];
    [self reflectMapEnableStreetView];
    [self reflectMapMoveToHomePos];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapFovColor"
                                                                 options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapArrowColor"
                                                                 options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapFovGrade"
                                                                 options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapType"
                                                                 options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapEnableStreetView"
                                                                 options:nil context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapMoveToHomePos"
                                                                 options:nil context:nil];
    
    // モデル変更を検知するobserverを登録
    [self.imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:nil context:nil];
    
    // メタデータ反映
    [self performSelector:@selector(reflectMetadata) withObject:nil afterDelay:0];
    
    // タブ反映
    [self performSelector:@selector(reflectViewSelector) withObject:nil afterDelay:0];
    
    _initialized = true;
}

- (void) prepareForClose
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.mapFovColor"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.mapArrowColor"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.mapFovGrade"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.mapType"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.mapEnableStreetView"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.mapMoveToHomePos"];
    [self.imageArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.imageArrayController && [keyPath isEqualToString:@"selectionIndexes"]){
        [self reflectMetadata];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.mapFovColor"]){
        [self reflectMapFovColor];
    }
    else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
             [keyPath isEqualToString:@"values.mapArrowColor"]){
        [self reflectMapArrowColor];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.mapFovGrade"]){
        [self reflectMapFovGrade];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.mapType"]){
        [self reflectMapType];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.mapEnableStreetView"]){
        [self reflectMapEnableStreetView];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.mapMoveToHomePos"]){
        [self reflectMapMoveToHomePos];
    }
}

- (void)reflectMetadata
{
    NSArray* selectedObjects = [self.imageArrayController selectedObjects];
    if (selectedObjects.count > 0){
        PathNode* current = [[self.imageArrayController selectedObjects] objectAtIndex:0];
        ImageMetadata* metadata = [[ImageMetadata alloc] initWithPathNode:current];
        self.summary = metadata.summary;
        if (_viewSelector == 1){
            self.gpsInfo = metadata.gpsInfoStrings;
            self.mapView.gpsInfo = metadata.gpsInfo;
        }
    }
}

- (void)reflectMapFovColor
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSData* data = [[controller values] valueForKey:@"mapFovColor"];
    if (data){
        self.mapView.fovColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:data];
    }
}

- (void)reflectMapArrowColor
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSData* data = [[controller values] valueForKey:@"mapArrowColor"];
    if (data){
        self.mapView.arrowColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:data];
    }
}

- (void)reflectMapFovGrade
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSNumber* grade = [[controller values] valueForKey:@"mapFovGrade"];
    if (grade){
        self.mapView.fovGrade = grade;
    }
}

- (void)reflectMapType
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSNumber* value = [[controller values] valueForKey:@"mapType"];
    self.mapView.mapType = value;
}

- (void)reflectMapEnableStreetView
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSNumber* value = [[controller values] valueForKey:@"mapEnableStreetView"];
    self.mapView.enableStreetView = value.boolValue;
}

- (void)reflectMapMoveToHomePos
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSNumber* value = [[controller values] valueForKey:@"mapMoveToHomePos"];
    self.mapView.enableHomePosition = value.boolValue;
}


- (void)reflectGoogleMapsApiKey
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSString* key = [[controller values] valueForKey:@"googleMapsApiKey"];
    if (!key){
        key = @"";
    }
    if ([self.view superview] && ![self.mapView.apiKey isEqualToString:key]){
        self.mapView.apiKey = key;
    }
}

- (void)reflectViewSelector
{
    self.viewSelector = self.viewSelector;
}

- (int)viewSelector
{
    return _viewSelector;
}

- (void)setViewSelector:(int)viewSelector
{
    _viewSelector = viewSelector;
    if (_initialized){
        [self.tabView selectTabViewItemAtIndex:_viewSelector];
        [self.view.window recalculateKeyViewLoop];

        //マップビューを初期化
        if (_viewSelector == 1){
            [self reflectGoogleMapsApiKey];
            [self reflectMetadata];
        }
    }
}

//-----------------------------------------------------------------------------------------
// View状態属性の実装
//-----------------------------------------------------------------------------------------
static NSString* kMapZoomLevel = @"mapZoomLevel";
static NSString* kMapType = @"mapType";
static NSString* kMapTilt = @"mapTilt";
static NSString* kViewSelector = @"viewSelector";

- (NSDictionary *)preferences
{
    NSDictionary* rc = @{kMapZoomLevel: _mapView.zoomLevel,
                         kMapType: _mapView.mapType,
                         kMapTilt: _mapView.tilt,
                         kViewSelector: @(self.viewSelector)};
    return rc ? rc : _preferences;
}

- (void)setPreferences:(NSDictionary *)preferences
{
    _preferences = preferences;
    [self performSelector:@selector(reflectPreferences) withObject:nil afterDelay:0];
}

- (void)reflectPreferences
{
    if (self.view.superview){
        self.viewSelector = [[_preferences valueForKey:kViewSelector] intValue];
    }
    if ([_preferences valueForKey:kMapZoomLevel]){
        _mapView.zoomLevel = [_preferences valueForKey:kMapZoomLevel];
    }
    if ([_preferences valueForKey:kMapType]){
        _mapView.mapType = [_preferences valueForKey:kMapType];
    }
    if ([_preferences valueForKey:kMapTilt]){
        _mapView.tilt = [_preferences valueForKey:kMapTilt];
    }
}

@end
