//
//  DevicePreferences.m
//  DigViewer
//
//  Created by opiopan on 2015/12/01.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import "DevicePreferences.h"
#import "DVRemoteProtcol.h"
#import "DVRemoteServer.h"

@interface DevicePreferences ()
@property (weak) IBOutlet NSButton *cancelPairingButton;
@property NSArray* devices;
@property (nonatomic) NSIndexSet* selectionIndexes;
@end

static NSString* deviceListKey = @"dvremotePairingKeys";
static NSString* connectedDevicesKey = @"connectedDevices";

@implementation DevicePreferences {
    NSUserDefaultsController* controller;
    __weak DVRemoteServer* dvr_server;
}

//-----------------------------------------------------------------------------------------
// シートアピアランス指定
//-----------------------------------------------------------------------------------------
- (BOOL) isResizable
{
    return NO;
}

- (NSImage *) imageForPreferenceNamed: (NSString *) prefName
{
    if (@available(macOS 11.0, *)) {
        return [NSImage imageWithSystemSymbolName:@"ipad.and.iphone" accessibilityDescription:nil];
    } else {
        return [[NSBundle mainBundle] imageForResource:@"DevicePreferences.png"];
    }
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
        dvr_server = [DVRemoteServer sharedServer];
        [dvr_server addObserver:self forKeyPath:connectedDevicesKey options:0 context:nil];
    }
    return self;
}

- (void)dealloc
{
    [dvr_server removeObserver:self forKeyPath:connectedDevicesKey];
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
    if ([keyPath isEqualToString:[@"values." stringByAppendingString:deviceListKey]] ||
        [keyPath isEqualToString:connectedDevicesKey]){
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
    NSArray<NSString*>* connectedDevices = [dvr_server connectedDevices];
    for (NSString* devID in list){
        NSDictionary* device = [list valueForKey:devID];
        NSString* deviceCode = [device valueForKey:DVRCNMETA_DEVICE_CODE];
        NSString* deviceType = [device valueForKey:DVRCNMETA_DEVICE_TYPE];
        NSImage* icon = nil;
        BOOL isConnected = [connectedDevices indexOfObjectPassingTest:^BOOL(NSString* value, NSUInteger index, BOOL* stop){
            return [value isEqualToString:devID];
        }] != NSNotFound;
        if (@available(macOS 11.0, *)) {
            if ([deviceType hasPrefix:@"iPad"]){
                icon = [NSImage imageWithSystemSymbolName:@"ipad" accessibilityDescription:nil];
            }else if ([deviceType hasPrefix:@"iPod"]){
                icon = [NSImage imageWithSystemSymbolName:@"ipodtouch" accessibilityDescription:nil];
            }else{
                icon = [NSImage imageWithSystemSymbolName:@"iphone" accessibilityDescription:nil];
            }
        } else {
            NSString* path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPhone.icns";
            if ([deviceCode hasPrefix:@"iPhone"]){
                path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPhone.icns";
            }else if ([deviceCode hasPrefix:@"iPad"]){
                path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPad.icns";
            }else if ([deviceCode hasPrefix:@"iPod"]){
                path = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebariPodTouch.icns";
            }
            icon = [[NSImage alloc] initByReferencingFile:path];
        }
        NSDictionary* entry = @{@"deviceName": @{@"icon": icon,
                                                 @"name": [device valueForKey:DVRCNMETA_DEVICE_NAME]},
                                @"deviceType": deviceType,
                                @"deviceID": devID,
                                @"isConnected": @(isConnected)};
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
        [dvr_server discardSessionWithDeviceID:[entry valueForKey:@"deviceID"]];
        [controller.values setValue:devices forKey:deviceListKey];
    }
    self.selectionIndexes = nil;
}

@end

//-----------------------------------------------------------------------------------------
// Value transformer from connection status to description string
//-----------------------------------------------------------------------------------------
@interface ConnectionStatusStringTransformer : NSValueTransformer
@end

@implementation ConnectionStatusStringTransformer

+ (Class)transformedValueClass
{
    return NSString.class;
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if ([value boolValue]){
        return NSLocalizedString(@"DEVCON_CONNECTED", nil);
    }else{
        return NSLocalizedString(@"DEVCON_DISCONNECTED", nil);
    }
}

@end

//-----------------------------------------------------------------------------------------
// Value transformer from connection status to text color
//-----------------------------------------------------------------------------------------
@interface ConnectionStatusColorTransformer : NSValueTransformer
@end

@implementation ConnectionStatusColorTransformer

+ (Class)transformedValueClass
{
    return NSColor.class;
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if ([value boolValue]){
        return NSColor.labelColor;
    }else{
        return NSColor.secondaryLabelColor;
    }
}

@end
