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
@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    DVRemoteServer* server = [DVRemoteServer sharedServer];
    server.delegate = self;
    [server establishServer];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[TemporaryFileController sharedController] cleanUpAllCategories];
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
    [[NSPreferences sharedPreferences] showPreferencesPanel];
}

- (IBAction)openFolder:(id)sender
{
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    if ([openPanel runModal] == NSFileHandlingPanelOKButton){
        NSDocumentController* controller = [NSDocumentController sharedDocumentController];
        [controller openDocumentWithContentsOfURL:openPanel.URL display:YES
                                completionHandler:^(NSDocument* document, BOOL alreadyOpened, NSError* error){}];
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
// DVremoveへサーバー情報を返却
//-----------------------------------------------------------------------------------------
static NSData* pngFromNSImage(NSImage* image);
- (void)dvrServer:(DVRemoteServer *)server needSendServerInfoToClient:(DVRemoteSession *)session
{
    TemporaryFileController* tmpFileController = [TemporaryFileController sharedController];
    NSString* infoFile = [tmpFileController allocatePathWithSuffix:@".plist" forCategory:@"serverInfo"];

    // system_profilerで動作環境の情報を取得
    NSString* cmd = [NSString stringWithFormat:@"system_profiler -xml SPHardwareDataType > %@", infoFile];
    system(cmd.UTF8String);
    NSArray* info = [NSArray arrayWithContentsOfFile:infoFile];
    
    // キー情報抽出
    NSDictionary* mainDict = [info[0] valueForKey:@"_items"][0];
    NSString* machineID = [mainDict valueForKey:@"machine_model"];
    NSString* serialNumber = [mainDict valueForKey:@"serial_number"];
    NSString* cpu = [NSString stringWithFormat:@"%@ %@",
                     [mainDict valueForKey:@"current_processor_speed"],
                     [mainDict valueForKey:@"cpu_type"]];
    NSString* memorySize = [mainDict valueForKey:@"physical_memory"];
    
    // ServerInformation.framework バンドルから詳細情報を抽出
    NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/ServerInformation.framework"];
    NSString* plistPath = [bundle pathForResource:@"SIMachineAttributes" ofType:@"plist"];
    NSDictionary* machineDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSDictionary* machineEntry = [machineDict valueForKey:machineID];
    NSString* machineImagePath = [machineEntry valueForKey:@"hardwareImageName"];
    NSString* description = [[machineEntry valueForKey:@"_LOCALIZABLE_"] valueForKey:@"description"];
    
    // iconファイル特定
    NSString* iconDir = [machineImagePath stringByDeletingLastPathComponent];
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

    // モデル名をWebサービスより取得
    NSString* urlString = [NSString stringWithFormat:@"http://support-sp.apple.com/sp/product?cc=%@",
                           [serialNumber substringFromIndex:serialNumber.length - 4]];
    NSURL* url = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* urlSession = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];
    NSURLSessionTask* task = [urlSession dataTaskWithURL:url
                                    completionHandler:^(NSData* data, NSURLResponse* response, NSError* error){
        if (data != nil){
            ModelNameExtractor* extractor = [ModelNameExtractor new];
            [extractor extractFromData:data];
            
            // 返却データを組立て
            NSMutableDictionary* serverInfo = [NSMutableDictionary dictionary];
            [serverInfo setValue:extractor.modelName forKey:DVRCNMETA_MACHINE_NAME];
            [serverInfo setValue:cpu forKey:DVRCNMETA_CPU];
            [serverInfo setValue:memorySize forKey:DVRCNMETA_MEMORY_SIZE];
            [serverInfo setValue:description forKey:DVRCNMETA_DESCRIPTION];
            InfoPlistController* infoPlist = [InfoPlistController new];
            [serverInfo setValue:infoPlist.version forKey:DVRCNMETA_DV_VERSION];
            
            NSMutableDictionary* rd = [NSMutableDictionary dictionary];
            [rd setValue:serverInfo forKey:DVRCNMETA_SERVER_INFO];
            
            NSImage* icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
            [rd setValue:pngFromNSImage(icon) forKey:DVRCNMETA_SERVER_ICON];
            NSImage* image = [[NSImage alloc] initWithContentsOfFile:machineImagePath];
            [rd setValue:pngFromNSImage(image) forKey:DVRCNMETA_SERVER_IMAGE];
            
            // クライアントに返却
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [server sendServerInfo:rd bySession:session];
            });
        }
    }];
    [task resume];
    
    // クリーンナップ
    [tmpFileController cleanUpForCategory:@"serverInfo"];
}

@end

//-----------------------------------------------------------------------------------------
// PNGデータ変換
//-----------------------------------------------------------------------------------------
static NSData* pngFromNSImage(NSImage* image)
{
    NSData* data = [image TIFFRepresentation];
    NSBitmapImageRep* tiffRep = [NSBitmapImageRep imageRepWithData:data];
    NSData* pngData = [tiffRep representationUsingType:NSPNGFileType properties:@{}];
    return pngData;
}