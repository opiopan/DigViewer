//
//  LensLibrary.h
//  DigViewer
//
//  Created by opiopan on 2015/04/18.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lens.h"

@interface LensLibrary : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSArray *allLensProfiles;

+ (LensLibrary*)sharedLensLibrary;

- (Lens*)insertNewLensEntity;
- (void)persistChange:(NSError**)error;

@end
