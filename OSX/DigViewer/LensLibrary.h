//
//  LensLibrary.h
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lens.h"
#import "Camera.h"
#import "Condition.h"

@interface LensLibrary : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext* managedObjectContext;
@property (readonly, strong, nonatomic) NSArray* allLensProfiles;
@property (readonly, strong, nonatomic) NSArray* allCameraProfiles;
@property (readonly, strong, nonatomic) NSDate* storeModificationDate;
@property (readonly, strong, nonatomic) NSData* storeData;

+ (LensLibrary*)sharedLensLibrary;
+ (void)updateLensLibraryWithData:(NSData*)data;

- (Lens*)insertNewLensEntity;
- (Camera*)insertNewCameraEntity;
- (NSArray*)findCameraByName:(NSString*)name;
- (Condition*)insertNewConditionEntity;
- (void)removeConditionRecurse:(Condition*)condition;
- (void)persistChange:(NSError**)error;

@end
