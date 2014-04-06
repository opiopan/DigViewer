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
    int _viewSelector;
}

- (id)init
{
    self = [super initWithNibName:@"InspectorView" bundle:nil];
    if (self) {
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
    
    // Google API Keyの変更を監視するするobserverを登録
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.googleMapsApiKey"
                                                                 options:nil context:nil];
    // モデル変更を検知するobserverを登録
    [self.imageArrayController addObserver:self forKeyPath:@"selectionIndexes" options:nil context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.imageArrayController && [keyPath isEqualToString:@"selectionIndexes"]){
        [self reflectMetadata];
    }else if (object == [NSUserDefaultsController sharedUserDefaultsController] &&
              [keyPath isEqualToString:@"values.googleMapsApiKey"]){
        [self reflectGoogleMapsApiKey];
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

- (void)reflectGoogleMapsApiKey
{
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSString* key = [[controller values] valueForKey:@"googleMapsApiKey"];
    if ([self.view superview] && ![self.mapView.apiKey isEqualToString:key]){
        self.mapView.apiKey = key;
    }
}

- (int)viewSelector
{
    return _viewSelector;
}

- (void)setViewSelector:(int)viewSelector
{
    _viewSelector = viewSelector;
    [self.tabView selectTabViewItemAtIndex:_viewSelector];
    [self.view.window recalculateKeyViewLoop];

    //マップビューを初期化
    if (_viewSelector == 1){
        [self reflectGoogleMapsApiKey];
        [self reflectMetadata];
    }
}

@end
