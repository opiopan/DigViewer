//
//  DevicePreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/12/01.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import "DevicePreferences.h"
#import "DVRemoteProtcol.h"

@interface DevicePreferences ()
@property (weak) IBOutlet NSButton *cancelPairingButton;
@property NSArray* devices;
@property (nonatomic) NSIndexSet* selectionIndexes;
@end

static NSString* deviceListKey = @"dvremotePairingKeys";

@implementation DevicePreferences {
    NSUserDefaultsController* controller;
}

//-----------------------------------------------------------------------------------------
// シートアピアランス指定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

//-----------------------------------------------------------------------------------------
// 初期化・回収
//-----------------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self){
        controller = [NSUserDefaultsController sharedUserDefaultsController];
        [controller addObserver:self forKeyPath:[@"values." stringByAppendingString:deviceListKey] options:0 context:nil];
    }
    return self;
}

- (void)dealloc
{
    [controller removeObserver:self forKeyPath:[@"values." stringByAppendingString:deviceListKey]];
}

- (void)initializeFromDefaults
{
    [self loadDeviceList];
    self.selectionIndexes = nil;
}

//-----------------------------------------------------------------------------------------
// キー値監視
//-----------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:[@"values." stringByAppendingString:deviceListKey]]){
        [self loadDeviceList];
    }
}

//-----------------------------------------------------------------------------------------
// デバイスリスト更新
//-----------------------------------------------------------------------------------------
- (void)loadDeviceList
{
    NSMutableArray* devices = [NSMutableArray new];
    NSDictionary* list = [controller.values valueForKey:deviceListKey];
    for (NSString* devID in list){
        NSDictionary* device = [list valueForKey:devID];
        NSString* deviceCode = [device valueForKey:DVRCNMETA_DEVICE_CODE];
        NSString* path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPhone.icns";
        if ([deviceCode hasPrefix:@"iPhone"]){
            path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPhone.icns";
        }else if ([deviceCode hasPrefix:@"iPad"]){
            path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPad.icns";
        }else if ([deviceCode hasPrefix:@"iPod"]){
            path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPodTouch.icns";
        }
        NSDictionary* entry = @{@"deviceName": @{@"icon": [[NSImage alloc] initByReferencingFile:path],
                                                 @"name": [device valueForKey:DVRCNMETA_DEVICE_NAME]},
                                @"deviceType": [device valueForKey:DVRCNMETA_DEVICE_TYPE],
                                @"deviceID": devID};
        [devices addObject:entry];
    }
    self.devices = [devices sortedArrayUsingComparator:^(id obj1, id obj2){
        NSString* name1 = [[obj1 valueForKey:@"deviceName"] valueForKey:@"name"];
        NSString* name2 = [[obj2 valueForKey:@"deviceName"] valueForKey:@"name"];
        return [name1 compare:name2 options:NSCaseInsensitiveSearch];
    }];
}

//-----------------------------------------------------------------------------------------
// 選択状態変化
//-----------------------------------------------------------------------------------------
- (void)setSelectionIndexes:(NSIndexSet *)selectionIndexes
{
    _selectionIndexes = selectionIndexes;
    _cancelPairingButton.enabled = _selectionIndexes && _selectionIndexes.count > 0;
}

//-----------------------------------------------------------------------------------------
// ペアリング解除
//-----------------------------------------------------------------------------------------
- (IBAction)onCancelPairing:(id)sender {
    if (_selectionIndexes && _selectionIndexes.count > 0){
        NSDictionary* entry = _devices[_selectionIndexes.firstIndex];
        NSMutableDictionary* devices =
            [NSMutableDictionary dictionaryWithDictionary:[controller.values valueForKey:deviceListKey]];
        [devices removeObjectForKey:[entry valueForKey:@"deviceID"]];
        [controller.values setValue:devices forKey:deviceListKey];
    }
    self.selectionIndexes = nil;
}

@end
