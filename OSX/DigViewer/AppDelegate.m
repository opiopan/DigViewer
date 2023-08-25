//
//  AppDelegate.m
//  DigViewer
//
//  Created by opiopan on 2015/04/05.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "AppDelegate.h"
#import "AppPreferences.h"
#import "TemporaryFileController.h"
#import "Document.h"
#import "DocumentWindowController.h"
#import "InfoPlistController.h"
#import "PairingWindowController.h"
#import "MacProductName.h"
#include <stdlib.h>

//-----------------------------------------------------------------------------------------
// アップルのWebサービスが返却するXMLからモデル名を抽出するための専用オブジェクト
//-----------------------------------------------------------------------------------------
@interface ModelNameExtractor : NSObject <NSXMLParserDelegate>
@property NSString* modelName;
- (void)extractFromData:(NSData*)data;
@end

@implementation ModelNameExtractor {
    BOOL _isInTarget;
}

- (void)extractFromData:(NSData *)data
{
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    [parser parse];
}

-(void) parserDidStartDocument:(NSXMLParser *)parser
{
    _isInTarget = NO;
}

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"configCode"]){
        _isInTarget = YES;
    }
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (_isInTarget){
        _modelName = string;
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
{
    _isInTarget = NO;
}

@end

//-----------------------------------------------------------------------------------------
// AppDelegateの実装
//-----------------------------------------------------------------------------------------
static NSString* serverEnableKey = @"dvremoteEnable";
static NSString* openDocsKey = @"openDocsOnAppExit";

@implementation AppDelegate {
    PairingWindowController* _pairingWindowController;
    NSUserDefaultsController* _controller;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _controller = [NSUserDefaultsController sharedUserDefaultsController];
    [_controller addObserver:self forKeyPath:[@"values." stringByAppendingString:serverEnableKey] options:0 context:nil];
    
    NSArray<NSString*>* docs = [_controller.values valueForKey:openDocsKey];
    if (docs.count > 0){
        [docs enumerateObjectsUsingBlock:^(NSString* path, NSUInteger idx, BOOL *stop) {
            NSURL* url = [NSURL fileURLWithPath:path];
            NSDocumentController* controller = [NSDocumentController sharedDocumentController];
            [controller openDocumentWithContentsOfURL:url display:YES
                                    completionHandler:^(NSDocument* document, BOOL alreadyOpened, NSError* error){
                if (error){
                    NSLog(@"Cannot open folder: %@, %@", path, error.description);
                }
            }];
        }];
    }else{
        [self openFolder:self];
    }
    
    DVRemoteServer* server = [DVRemoteServer sharedServer];
    server.delegate = self;
    [self dvrServer:server needSendServerInfoToClient:nil];
    AppDelegate* __weak weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf setupDVRemoteServer];
    });
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [_controller removeObserver:self forKeyPath:[@"values." stringByAppendingString:serverEnableKey]];
    [[TemporaryFileController sharedController] cleanUpAllCategories];
    
    NSMutableArray* docs = [NSMutableArray array];
    [sender.orderedDocuments enumerateObjectsUsingBlock:^(NSDocument* document, NSUInteger idx, BOOL *stop) {
        [docs addObject:document.fileURL.path];
    }];
    [_controller.values setValue:docs forKey:openDocsKey];
    return NSTerminateNow;
}

- (IBAction)showPreferences:(id)sender
{
    [NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
    [[NSPreferences sharedPreferences] showPreferencesPanel];
}

- (IBAction)showMapPreferences:(id)sender
{
    [NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
    [(AppPreferences*)[NSPreferences sharedPreferences] showPreferencesPanelWithInitialSheet:AppPreferenceSheetMap];
}

- (IBAction)openFolder:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = YES;
    if ([openPanel runModal] == NSModalResponseOK){
        NSDocumentController* controller = [NSDocumentController sharedDocumentController];
        [controller openDocumentWithContentsOfURL:openPanel.URL display:YES
                                completionHandler:^(NSDocument* document, BOOL alreadyOpened, NSError* error){
            if (error){
                [NSApp presentError:error];
            }
        }];
    }
}

//-----------------------------------------------------------------------------------------
// キー値監視
//-----------------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:[@"values." stringByAppendingString:serverEnableKey]]){
        [self setupDVRemoteServer];
    }
}

//-----------------------------------------------------------------------------------------
// DVRemoteServer起動・停止
//-----------------------------------------------------------------------------------------
- (void)setupDVRemoteServer
{
    if ([[_controller.values valueForKey:serverEnableKey] boolValue]){
        [[DVRemoteServer sharedServer] establishServer];
    }else{
        [[DVRemoteServer sharedServer] shutdownServer];
    }
}

//-----------------------------------------------------------------------------------------
// DVRemoteServerDelegateプロトコルの実装
//-----------------------------------------------------------------------------------------
- (void)dvrServer:(DVRemoteServer *)server needMoveToNeighborImageOfDocument:(NSString *)documentName
    withDirection:(DVRCommand)direction
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        for (NSWindowController* windowController in document.windowControllers){
            if ([windowController.class isSubclassOfClass:[DocumentWindowController class]]){
                if (direction == DVRC_MOVE_NEXT_IMAGE){
                    [((DocumentWindowController*)windowController) moveToNextImage:self];
                }else{
                    [((DocumentWindowController*)windowController) moveToPreviousImage:self];
                }
            }
        }
    }
}

- (void)dvrServer:(DVRemoteServer *)server needMoveToNode:(NSArray *)nodeID inDocument:(NSString *)documentName
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        PathNode* node = [document.root nearestNodeAtPortablePath:nodeID];
        for (NSWindowController* windowController in document.windowControllers){
            if ([windowController.class isSubclassOfClass:[DocumentWindowController class]]){
                [((DocumentWindowController*)windowController) moveToImageNode:node];
            }
        }
    }
}

- (void)dvrServer:(DVRemoteServer *)server needSendThumbnail:(NSArray *)id forDocument:(NSString *)documentName
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        [document sendThumbnail:id];
    }
}

- (void)dvrServer:(DVRemoteServer *)server needSendFullimage:(NSArray *)nodeId
      forDocument:(NSString *)documentName withSize:(CGFloat)maxSize
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        [document sendFullImage:nodeId withSize:maxSize];
    }
}

- (void)dvrServer:(DVRemoteServer *)server needSendFolderItms:(NSArray *)nodeId forDocument:(NSString *)documentName
        bySession:(DVRemoteSession *)session
{
    NSDocumentController* controller = [NSDocumentController sharedDocumentController];
    Document* document = [controller documentForURL:[NSURL fileURLWithPath:documentName]];
    if (document){
        [document sendNodeListInFolder:nodeId bySession:session];
    }
}

//-----------------------------------------------------------------------------------------
// DVremoteの認証
//-----------------------------------------------------------------------------------------
static NSString* pairingKeysName = @"dvremotePairingKeys";

- (void)dvrServer:(DVRemoteServer *)server needPairingForClient:(DVRemoteSession *)session withAttributes:(NSDictionary *)attrs
{
    if (_pairingWindowController){
        [server discardSession:session];
        return;
    }
    
    UInt32 key = arc4random();
    NSString* keyString = @(key).stringValue;
    NSMutableDictionary* args = [NSMutableDictionary dictionaryWithDictionary:attrs];
    [args setValue:keyString forKey:DVRCNMETA_PAIRCODE];
    [server sendPairingKey:args bySession:session];
    
    int hash = key % 10000;
    NSString* deviceName = [attrs valueForKey:DVRCNMETA_DEVICE_NAME];
    NSString* deviceType = [attrs valueForKey:DVRCNMETA_DEVICE_TYPE];
    NSString* deviceID = [attrs valueForKey:DVRCNMETA_DEVICE_ID];
    _pairingWindowController = [PairingWindowController new];
    _pairingWindowController.modelName = deviceName;
    _pairingWindowController.modelType = deviceType;
    _pairingWindowController.keyHash = hash;
    _pairingWindowController.deviceID = deviceID;
    session.deviceID = deviceID;
    [_pairingWindowController startPairingWithCompletionHandler:^(BOOL isOK){
        if (isOK){
            NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
            NSMutableDictionary* keyes =
                [NSMutableDictionary dictionaryWithDictionary:[controller.values valueForKey:pairingKeysName]];
            [keyes setValue:args forKey:deviceID];
            session.deviceID = deviceID;
            [server completeAuthenticationAsResult:YES ofSession:session];
            [controller.values setValue:keyes forKey:pairingKeysName];
        }else{
            [server discardSession:session];
        }
        self->_pairingWindowController = nil;
    }];
}

- (void)dvrServer:(DVRemoteServer *)server needCancelPairingForClient:(DVRemoteSession *)session
{
    if ([_pairingWindowController.deviceID isEqualToString:session.deviceID]){
        PairingWindowController* windowController = _pairingWindowController;
        dispatch_after(0, dispatch_get_main_queue(), ^{
            [windowController closeWindow];
        });
    }
}

- (void)dvrServer:(DVRemoteServer *)server needAuthenticateClient:(DVRemoteSession *)session withAttributes:(NSDictionary *)attrs
{
    NSString* deviceID = [attrs valueForKey:DVRCNMETA_DEVICE_ID];
    NSString* charengedKey = [attrs valueForKey:DVRCNMETA_PAIRCODE];
    NSUserDefaultsController* controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSDictionary* keys = [controller.values valueForKey:pairingKeysName];
    NSDictionary* values = [keys valueForKey:deviceID];
    NSString* key = [values valueForKey:DVRCNMETA_PAIRCODE];
    if ([key isEqualToString:charengedKey]){
        session.deviceID = deviceID;
        [server completeAuthenticationAsResult:YES ofSession:session];
    }else{
        [server completeAuthenticationAsResult:NO ofSession:session];
    }
}

//-----------------------------------------------------------------------------------------
// DVremoveへサーバー情報を返却
//-----------------------------------------------------------------------------------------
static NSDictionary* systemProperties(NSString* key);
static NSDictionary* ioregProperties(void);
static NSData* pngFromNSImage(NSImage* image);
- (void)dvrServer:(DVRemoteServer *)server needSendServerInfoToClient:(DVRemoteSession *)session
{
    // キー情報抽出
    NSString* cpu;
    int coreNum = 0;
    NSString* memory;
    NSString* gpu;
    int gpuCoreNum = 0;

    NSDictionary* mainDict = systemProperties(@"SPHardwareDataType");
    NSString* machineID = [mainDict valueForKey:@"machine_model"];
    if ([mainDict valueForKey:@"cpu_type"]){
        //
        // Intel Mac
        //
        cpu = [NSString stringWithFormat:@"%@ %@",
               [mainDict valueForKey:@"current_processor_speed"],
               [mainDict valueForKey:@"cpu_type"]];
        coreNum = [[mainDict valueForKey:@"number_processors"] intValue] * [[mainDict valueForKey:@"packages"] intValue];
        NSString* memorySize = [mainDict valueForKey:@"physical_memory"];
        NSDictionary* memDict = [[systemProperties(@"SPMemoryDataType") valueForKey:@"_items"] objectAtIndex:0];
        memory = [NSString stringWithFormat:@"%@ %@ %@", memorySize,
                  [memDict valueForKey:@"dimm_type"], [memDict valueForKey:@"dimm_speed"]];
        NSDictionary* gpuDict = systemProperties(@"SPDisplaysDataType");
        NSString* vramSize = [gpuDict valueForKey:@"spdisplays_vram"];
        if (!vramSize){
            vramSize = [gpuDict valueForKey:@"spdisplays_vram_shared"];
        }
        gpu = [NSString stringWithFormat:@"%@ (%@)", [gpuDict valueForKey:@"sppci_model"], vramSize];
    }else{
        //
        // Apple Silicon Mac
        //
        cpu = [mainDict valueForKey:@"chip_type"];
        NSString* corenum_info = [mainDict valueForKey:@"number_processors"];
        coreNum = [corenum_info stringByReplacingOccurrencesOfString:@"(\\w+)\\s(\\d+):(\\d+):(\\d)"
                                                          withString:@"$2"
                                                             options:NSRegularExpressionSearch
                                                               range:NSMakeRange(0, corenum_info.length)].intValue;
        memory = [mainDict valueForKey:@"physical_memory"];
        NSDictionary* gpuDict = systemProperties(@"SPDisplaysDataType");
        gpu = [gpuDict valueForKey:@"sppci_model"];
        gpuCoreNum = [[gpuDict valueForKey:@"sppci_cores"] intValue];
    }

    NSDictionary* osDict = systemProperties(@"SPSoftwareDataType");
    NSString* osVersion = [osDict valueForKey:@"os_version"];

    // ServerInformation.framework バンドルから詳細情報を抽出
    NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ServerInformation.framework"];
    NSString* plistPath = [bundle pathForResource:@"SIMachineAttributes" ofType:@"plist"];
    NSDictionary* machineDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary* machineEntry = [machineDict valueForKey:machineID];
    NSString* machineImagePath = [machineEntry valueForKey:@"hardwareImageName"];
    NSString* description = [[machineEntry valueForKey:@"_LOCALIZABLE_"] valueForKey:@"description"];
    
    // iconファイル特定
    NSString* iconDir = machineImagePath ? [machineImagePath stringByDeletingLastPathComponent] :
                                           @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources";
    NSString* iconPath = nil;
    if ([machineID hasPrefix:@"MacBook"]){
        iconPath = [iconDir stringByAppendingPathComponent:@"SidebarLaptop.icns"];
    }else if ([machineID hasPrefix:@"Macmini"]){
        iconPath = [iconDir stringByAppendingPathComponent:@"SidebarMacMini.icns"];
    }else if ([machineID hasPrefix:@"iMac"]){
        iconPath = [iconDir stringByAppendingPathComponent:@"SidebariMac.icns"];
    }else if ([machineID hasPrefix:@"MacPro6"]){
        iconPath = [iconDir stringByAppendingPathComponent:@"SidebarMacProCylinder.icns"];
    }else if ([machineID hasPrefix:@"MacPro"]){
        iconPath = [iconDir stringByAppendingPathComponent:@"SidebarMacPro.icns"];
    }else{
        iconPath = [iconDir stringByAppendingPathComponent:@"SidebarLaptop.icns"];
    }

    // identifying the product name
    NSString* product_name = [MacProductName productNameOfIdentifier:machineID];
    if (!product_name){
        NSDictionary* ioreg = ioregProperties();
        product_name = [[NSString alloc] initWithData:[ioreg valueForKey:@"product-name"] encoding:NSUTF8StringEncoding];
    }
    
    // 返却データを組立て
    NSMutableDictionary* serverInfo = [NSMutableDictionary dictionary];
    [serverInfo setValue:product_name forKey:DVRCNMETA_MACHINE_NAME];
    [serverInfo setValue:cpu forKey:DVRCNMETA_CPU];
    [serverInfo setValue:@(coreNum).stringValue forKey:DVRCNMETA_CPU_CORE_NUM];
    [serverInfo setValue:memory forKey:DVRCNMETA_MEMORY_SIZE];
    [serverInfo setValue:gpu forKey:DVRCNMETA_GPU];
    if (gpuCoreNum > 0){
        [serverInfo setValue:@(gpuCoreNum).stringValue forKey:DVRCNMETA_GPU_CORE_NUM];
    }
    [serverInfo setValue:osVersion forKey:DVRCNMETA_OS_VERSION];
    [serverInfo setValue:description forKey:DVRCNMETA_DESCRIPTION];
    InfoPlistController* infoPlist = [InfoPlistController new];
    [serverInfo setValue:[infoPlist.version substringFromIndex:8] forKey:DVRCNMETA_DV_VERSION];
    
    NSMutableDictionary* rd = [NSMutableDictionary dictionary];
    [rd setValue:serverInfo forKey:DVRCNMETA_SERVER_INFO];
    
    NSImage* icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
    [rd setValue:pngFromNSImage(icon) forKey:DVRCNMETA_SERVER_ICON];
    OSType code = UTGetOSTypeFromString((CFStringRef)CFSTR("root"));
    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(code)];
    [rd setValue:pngFromNSImage(image) forKey:DVRCNMETA_SERVER_IMAGE];
    
    // クライアントに返却
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [server sendServerInfo:rd bySession:session];
    });
}

//-----------------------------------------------------------------------------------------
// Go to the official web site
//-----------------------------------------------------------------------------------------
- (IBAction)gotoWebSite:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"https://opiopan.github.io/DigViewer"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)gotoGitHub:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"https://github.com/opiopan/DigViewer"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end


//-----------------------------------------------------------------------------------------
// Retrieve system information
//-----------------------------------------------------------------------------------------
static NSDictionary* systemProperties(NSString* key)
{
    TemporaryFileController* tmpFileController = [TemporaryFileController sharedController];
    NSString* infoFile = [tmpFileController allocatePathWithSuffix:@".plist" forCategory:@"serverInfo"];
    NSString* cmd = [NSString stringWithFormat:@"system_profiler -xml %@ > %@", key, infoFile];
    system(cmd.UTF8String);
    NSArray* info = [NSArray arrayWithContentsOfFile:infoFile];
    [tmpFileController cleanUpForCategory:@"serverInfo"];

    return [info[0] valueForKey:@"_items"][0];
}

static NSDictionary* ioregProperties(void)
{
    TemporaryFileController* tmpFileController = [TemporaryFileController sharedController];
    NSString* infoFile = [tmpFileController allocatePathWithSuffix:@".plist" forCategory:@"ioregInfo"];
    NSString* cmd = [NSString stringWithFormat:@"/usr/sbin/ioreg -abr -k 'product-name' > %@", infoFile];
    system(cmd.UTF8String);
    NSArray* info = [NSArray arrayWithContentsOfFile:infoFile];
    [tmpFileController cleanUpForCategory:@"serverInfo"];
    
    return info[0];
}

//-----------------------------------------------------------------------------------------
// PNGデータ変換
//-----------------------------------------------------------------------------------------
static NSData* pngFromNSImage(NSImage* image)
{
    CGFloat scale = [NSScreen mainScreen].backingScaleFactor;
    NSImageRep* rep = [image bestRepresentationForRect:NSMakeRect(0, 0, 512.0 / scale, 512.0 / scale) context:nil hints:nil];
    NSImage* repImage = [NSImage new];
    [repImage addRepresentation:rep];
    NSData* data = [repImage TIFFRepresentation];
    NSBitmapImageRep* tiffRep = [NSBitmapImageRep imageRepWithData:data];
    NSData* pngData = [tiffRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return pngData;
}
