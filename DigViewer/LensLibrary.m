//
//  LensLibrary.m
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "LensLibrary.h"

static NSURL* _storeDirectory;
static LensLibrary* _sharedLensLibrary;

@implementation LensLibrary

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize allLensProfiles = _allLensProfiles;

//-----------------------------------------------------------------------------------------
// シングルトンパタンの実装
//-----------------------------------------------------------------------------------------
+(LensLibrary *)sharedLensLibrary
{
    if (!_storeDirectory){
        NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                       inDomains:NSUserDomainMask] lastObject];
        _storeDirectory = [appSupportURL URLByAppendingPathComponent:@"com.opiopan.DigViewer"];
    }
    if (_storeDirectory && !_sharedLensLibrary){
        _sharedLensLibrary = [[LensLibrary alloc] init];
    }
    return _sharedLensLibrary;
}

//-----------------------------------------------------------------------------------------
// Core Data用プロパティの実装
//-----------------------------------------------------------------------------------------
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LensLibrary" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = NSLocalizedString(@"There was an error creating or loading the lens library.", nil);
    
    // レンズライブラリ格納先ディレクトリの作成
    NSDictionary *properties = [_storeDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason =
                [NSString stringWithFormat:NSLocalizedString(@"Expected a folder for the lens library, found a file (%@).", nil),
                                           [_storeDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[_storeDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // レンズライブラリ初期化
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [_storeDirectory URLByAppendingPathComponent:@"LensLibrary.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // エラーメッセージ表示
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = NSLocalizedString(@"Failed to initialize the lens library", nil);
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

//-----------------------------------------------------------------------------------------
// レンズプロファイルリスト属性の実装
//-----------------------------------------------------------------------------------------
- (NSArray *)allLensProfiles
{
    if (!_allLensProfiles){
        [self updateAllLensProfiles];
    }
    return _allLensProfiles;
}

- (void)updateAllLensProfiles
{
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Lens"];
    NSError* error = nil;
    _allLensProfiles = [self.managedObjectContext executeFetchRequest:request error:&error];
}

//-----------------------------------------------------------------------------------------
// 新規レンズプロファイルの挿入
//-----------------------------------------------------------------------------------------
-(Lens *)insertNewLensEntity
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"Lens" inManagedObjectContext:self.managedObjectContext];
}

//-----------------------------------------------------------------------------------------
// 更新内容の保存
//-----------------------------------------------------------------------------------------
- (void)persistChange:(NSError *__autoreleasing *)error
{
    [self.managedObjectContext save:error];
    [self updateAllLensProfiles];
}

@end
