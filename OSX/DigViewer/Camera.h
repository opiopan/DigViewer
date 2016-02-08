//
//  Camera.h
//  DigViewer
//
//  Created by opiopan on 2015/07/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Lens;

@interface Camera : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *lens;
@end

@interface Camera (CoreDataGeneratedAccessors)

- (void)addLensObject:(Lens *)value;
- (void)removeLensObject:(Lens *)value;
- (void)addLens:(NSSet *)values;
- (void)removeLens:(NSSet *)values;

@end
