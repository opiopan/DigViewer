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
#import "InspectorArrayController.h"
#import "DocumentWindowController.h"
#import "TemporaryFileController.h"
#import <MapKit/MapKit.h>
#import <quartz/Quartz.h>

#import "CoreFoundationHelper.h"

@interface InspectorViewController ()
@property (nonatomic) IBOutlet NSTableView* summaryView;
@property (nonatomic) IBOutlet NSTableView* gpsInfoView;
@property (nonatomic) IBOutlet InspectorArrayController* summaryController;
@property (nonatomic) IBOutlet InspectorArrayController* gpsInfoController;
@property (nonatomic) IBOutlet NSMenu* attributesMenu;
@end

@implementation InspectorViewController{
    int     _viewSelector;
    bool    _initialized;
    NSDictionary* _preferences;
}

//-----------------------------------------------------------------------------------------
//  初期化
//-----------------------------------------------------------------------------------------
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
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapArrowColor"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapFovGrade"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapType"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapEnableStreetView"
                                                                 options:0 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.mapMoveToHomePos"
                                                                 options:0 context:nil];
    
    // モデル変更を検知するobserverを登録
    [self.imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:nil];
    
    // メタデータ反映
    [self performSelector:@selector(reflectMetadata) withObject:nil afterDelay:0];
    
    // タブ反映
    [self performSelector:@selector(reflectViewSelector) withObject:nil afterDelay:0];

    // Dragging sourceの登録
    [_summaryView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    [_gpsInfoView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];

    // コンテキストメニューの生成＆登録
    NSMenu* attributesMenu = [[NSMenu alloc] initWithTitle:@"summary context menu"];
    NSMenu* mapMenu = [[NSMenu alloc] initWithTitle:@"gps info context menu"];
    DocumentWindowController* controller = [self.representedObject valueForKey:@"controller"];
    NSArray* commonItems = controller.contextMenu.itemArray;
    NSArray* mapItems = controller.contextMenuForMap.itemArray;
    for (int i = 0; i < 5; i++){
        [attributesMenu addItem:[commonItems[i] copy]];
        [mapMenu addItem:[commonItems[i] copy]];
    }
    for (NSMenuItem* item in _attributesMenu.itemArray){
        [attributesMenu addItem:[item copy]];
    }
    for (NSMenuItem* source in mapItems){
        NSMenuItem* item = [source copy];
        item.keyEquivalent = @"";
        item.target = self;
        [mapMenu addItem:item];
    }
    _summaryView.menu = attributesMenu;
    _gpsInfoView.menu = attributesMenu;
    _mapView.menu = mapMenu;
    
    _initialized = true;
}


//-----------------------------------------------------------------------------------------
// クローズ準備
//-----------------------------------------------------------------------------------------
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


//-----------------------------------------------------------------------------------------
// キー値監視
//-----------------------------------------------------------------------------------------
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

//-----------------------------------------------------------------------------------------
// 表示タブ属性の実装
//-----------------------------------------------------------------------------------------
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
    NSMutableDictionary* rc = [NSMutableDictionary dictionary];
    id value = _mapView.zoomLevel;
    if (value){
        [rc setObject:value forKey:kMapZoomLevel];
    }
    value = _mapView.mapType;
    if (value){
        [rc setObject:value forKey:kMapType];
    }
    value = _mapView.tilt;
    if (value){
        [rc setObject:value forKey:kMapTilt];
    }
    value = @(self.viewSelector);
    if (value){
        [rc setObject:value forKey:kViewSelector];
    }
    return rc;
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

//-----------------------------------------------------------------------------------------
// テーブルビューのコンテキストメニュー処理
//-----------------------------------------------------------------------------------------
- (IBAction)selectAll:(id)sender
{
    NSTableView* targetView = _viewSelector == 0 ? _summaryView : _gpsInfoView;
    [targetView selectAll:sender];
}

- (IBAction)copyAttributes:(id)sender
{
    NSTableView* targetView = _viewSelector == 0 ? _summaryView : _gpsInfoView;
    InspectorArrayController* targetController = _viewSelector == 0 ? _summaryController : _gpsInfoController;
    NSIndexSet* indexSet = targetView.selectedRowIndexes;
    if (targetView.clickedRow >= 0 && ![indexSet containsIndex:targetView.clickedRow]){
        indexSet = [NSIndexSet indexSetWithIndex:targetView.clickedRow];
    }
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [targetController writeItemsAtIndexes:indexSet toPasteboard:pboard withOnlyValue:[sender tag]];
}

- (BOOL)validateForCopyAttributes:(NSMenuItem*)menuItem
{
    NSTableView* targetView = _viewSelector == 0 ? _summaryView : _gpsInfoView;
    return targetView.clickedRow >= 0 || targetView.selectedRowIndexes.count > 0;
}

//-----------------------------------------------------------------------------------------
// デフォルトのコピーアクション
//-----------------------------------------------------------------------------------------
- (void)copy:(id)sender
{
    [self copyAttributes:sender];
}

- (BOOL)validateForCopy:(NSMenuItem*)menuItem
{
    return [self validateForCopyAttributes:menuItem];
}

//-----------------------------------------------------------------------------------------
// マップビューのコンテキストメニュー: センタリング
//-----------------------------------------------------------------------------------------
- (IBAction)moveToPhotograhingPlace:(id)sender
{
    self.mapView.gpsInfo = self.mapView.gpsInfo;
}

- (BOOL)validateForMoveToPhotograhingPlace:(NSMenuItem*)menuItem
{
    return self.mapView.gpsInfo != nil;
}

//-----------------------------------------------------------------------------------------
// マップビューのコンテキストメニュー: ブラウザでGoogle Maps起動
//-----------------------------------------------------------------------------------------
- (IBAction)openMapWithBrowser:(id)sender
{
    GPSInfo* gpsInfo = self.mapView.gpsInfo;
    NSString* urlString = [NSString stringWithFormat:@"http://www.google.com/maps?ll=%@,%@&z=%@&q=%@,%@",
                           gpsInfo.latitude, gpsInfo.longitude,
                           self.mapView.zoomLevel,
                           gpsInfo.latitude, gpsInfo.longitude];
    NSURL* url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (BOOL)validateForOpenMapWithBrowser:(NSMenuItem*)menuItem
{
    return self.mapView.gpsInfo != nil;
}

//-----------------------------------------------------------------------------------------
// マップビューのコンテキストメニュー: マップアプリ起動
//-----------------------------------------------------------------------------------------
- (IBAction)openMapWithMapApp:(id)sender
{
    PathNode* current = _imageArrayController.selectedObjects[0];
    GPSInfo* gpsInfo = self.mapView.gpsInfo;

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(gpsInfo.latitude.doubleValue,
                                                                   gpsInfo.longitude.doubleValue);
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    [mapItem setName:current.imageNode.name];
    
    NSNumber* spanLatitude = _mapView.spanLatitude;
    NSNumber* spanLongitude = _mapView.spanLongitude;
    NSDictionary* options = nil;
    if (spanLatitude && spanLongitude){
        MKCoordinateSpan span = {spanLatitude.doubleValue, spanLongitude.doubleValue};
        options = @{MKLaunchOptionsMapSpanKey: [NSValue valueWithMKCoordinateSpan:span]};
    }
    
    [mapItem openInMapsWithLaunchOptions:options];
}

- (BOOL)validateForOpenMapWithMapApp:(NSMenuItem*)menuItem
{
    return self.mapView.gpsInfo != nil;
}

//-----------------------------------------------------------------------------------------
// マップビューのコンテキストメニュー: Google Earth起動
//-----------------------------------------------------------------------------------------
static NSString* CategoryKML = @"KML";

- (IBAction)openMapWithGoogleEarth:(id)sender
{
    static NSString* format = @
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n"
        "    <Placemark>\n"
        "        <name>%@</name>\n"
        "        <description><![CDATA[<img src=\"%@\" align=\"center\"/><p>%@]]></description>\n"
        "        <Point>\n"
        "            <altitudeMode>%@</altitudeMode>\n"
        "            <coordinates>%@,%@,%@</coordinates>\n"
        "        </Point>\n"
        "        <LookAt>\n"
        "            <longitude>%@</longitude>\n"
        "            <latitude>%@</latitude>\n"
        "            <heading>%@</heading>\n"
        "            <tilt>%@</tilt>\n"
        "            <range>%@</range>\n"
        "        </LookAt>\n"
        "    </Placemark>\n"
        "</kml>\n";
    PathNode* current = _imageArrayController.selectedObjects[0];
    GPSInfo* gpsInfo = self.mapView.gpsInfo;

    // 説明テキスト(HTML flagment)生成
    NSString* description = [self descriptionForPathNode:current.imageNode];
    
    // 表示位置、高度、範囲、方向を抽出
    NSNumber* altitude;
    NSString* altMode;
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    if (gpsInfo.altitude && [[controller.values valueForKey:@"mapPassAltitudeToExternalMap"] boolValue]){
        altitude = gpsInfo.altitude;
        altMode = @"absolute";
    }else{
        altitude = @0;
        altMode = @"clampToGround";
    }
    NSNumber* heading = gpsInfo.imageDirection;
    NSNumber* tilt = @60;
    NSNumber* spanLatitude = _mapView.spanLatitude;
    NSNumber* spanLongitude = _mapView.spanLongitude;
    NSNumber* range;
    if (spanLatitude && spanLongitude){
        range = @(MAX(spanLatitude.doubleValue, spanLongitude.doubleValue * fabs(cos(gpsInfo.longitude.doubleValue)))
                  * 111000 * 0.7);
    }else{
        range = @600;
    }
    double deltaLat = range.doubleValue * 0.4 / 111000;
    double compensating = fabs(cos(gpsInfo.latitude.doubleValue / 180 * M_PI));
    double deltaLng = compensating == 0 ? deltaLat : deltaLat / compensating;
    NSNumber* viewPointLat = !gpsInfo.imageDirection ? gpsInfo.latitude :
                             @(gpsInfo.latitude.doubleValue + deltaLat * cos(heading.doubleValue / 180.0 * M_PI));
    NSNumber* viewPointLng = !gpsInfo.imageDirection ? gpsInfo.longitude :
                             @(gpsInfo.longitude.doubleValue + deltaLng * sin(heading.doubleValue / 180.0 * M_PI));
    if (!gpsInfo.imageDirection){
        heading = @0;
        tilt = @45;
        viewPointLat = gpsInfo.latitude;
        viewPointLng = gpsInfo.longitude;
        
    }
    
    //サムネール画像保存
    TemporaryFileController* temporaryFile = [TemporaryFileController sharedController];
    NSString* thumbnailPath = [temporaryFile allocatePathWithSuffix:@".jpg" forCategory:CategoryKML];
    [self saveThumbnailForPlacemarkWithPath:thumbnailPath pathNode:current.imageNode];

    //KMLファイル保存
    NSString* kmlPath = [temporaryFile allocatePathWithSuffix:@".kml" forCategory:CategoryKML];
    NSString* kmlString = [NSString stringWithFormat:format,
                           current.imageNode.name,
                           thumbnailPath, description,
                           altMode,
                           gpsInfo.longitude, gpsInfo.latitude, altitude,
                           viewPointLng, viewPointLat, heading, tilt, range];
    NSError* error;
    [kmlString writeToFile:kmlPath atomically:NO encoding:NSUTF8StringEncoding error:&error];

    // Google EarthでKMLファイルをオープン
    [[NSWorkspace sharedWorkspace] openFile:kmlPath withApplication:@"Google Earth.app"];
}

- (BOOL)validateForOpenMapWithGoogleEarth:(NSMenuItem*)menuItem
{
    return self.mapView.gpsInfo != nil;
}

- (NSString*)descriptionForPathNode:(PathNode*)node
{
    NSMutableString* rc = [NSMutableString string];
    [rc appendString:@"<table align=\"center\" style=\"font-family: sans-serif\">"];
    
    ImageMetadata* meta = [[ImageMetadata alloc] initWithPathNode:node];
    NSArray* filter = @[@0, @5, @8, @11, @13, @14, @15];
    NSArray* summary = [meta summaryWithFilter:filter];
    for (id kv in summary){
        NSString* key = [kv valueForKey:@"key"];
        NSString* value = [kv valueForKey:@"value"];
        if (key){
            [rc appendFormat:@"<tr><td align=\"right\">%@</td><td>%@</td></tr>", key, value ? value : @""];
        }
    }
    
    [rc appendString:@"</table>"];
    return rc;
}

- (BOOL)saveThumbnailForPlacemarkWithPath:(NSString*)path pathNode:(PathNode*)node
{
    // サムネールイメージ取得
    ECGImageRef thumbnail;
    if ([node imageRepresentationType] == IKImageBrowserCGImageRepresentationType){
        thumbnail = (__bridge_retained CGImageRef)[node imageRepresentation];
    }else{
        thumbnail = [node CGImageFromNSImage:[node imageRepresentation]];
    }
    NSImage* image = [[NSImage alloc] initWithCGImage:thumbnail
                                                 size:NSMakeSize(CGImageGetWidth(thumbnail)/2, CGImageGetHeight(thumbnail)/2)];

    // NSImage→TIFF変換
    NSData* tiffData = [image TIFFRepresentation];
    NSBitmapImageRep* tiffRep = [NSBitmapImageRep imageRepWithData:tiffData];
    
    // TIFF→JPEG変換
    NSDictionary* option = @{NSImageCompressionFactor: @0.5};
    NSData* jpegData = [tiffRep representationUsingType:NSJPEGFileType properties:option];
    
    //ファイル出力
    return [jpegData writeToFile:path atomically:NO];
}

@end
