//
//  InspectorViewController.h
//  DigViewer
//
//  Created by opiopan on 2014/02/16.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GPSMapView.h"

@interface InspectorViewController : NSViewController

@property (assign) int viewSelector;

@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSView *gpsPlaceHolder;
@property (weak) IBOutlet NSArrayController* imageArrayController;
@property (weak) IBOutlet NSTableColumn* keyColumn;
@property (weak) IBOutlet NSTableColumn *gpsKeyColumn;
@property (weak) IBOutlet GPSMapView *mapView;
@property (strong) NSArray* summary;
@property (strong) NSArray* gpsInfo;

- (IBAction)openMapWithBrowser:(id)sender;
- (BOOL)validateForOpenMapWithBrowser:(NSMenuItem*)menuItem;
- (IBAction)openMapWithMapApp:(id)sender;
- (BOOL)validateForOpenMapWithMapApp:(NSMenuItem*)menuItem;
- (IBAction)moveToPhotograhingPlace:(id)sender;
- (BOOL)validateForMoveToPhotograhingPlace:(NSMenuItem*)menuItem;

@end
