//
//  BrowseContextArray.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/04.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol  BrowseContext
@required
@property (nonatomic) NSString* name;
@property (nonatomic) NSString* pathString;
@property (nonatomic) NSArray* path;
@property (nonatomic, readonly) BOOL isCurrent;
@end

@interface BrowseContextArray : NSObject
@property (nonatomic, readonly) NSMutableArray* array;
@property (nonatomic, readonly) id<BrowseContext> currentContext;
+ (BrowseContextArray*) arrayWithArray:(NSArray*)array currentPath:(NSArray*) path;
- (void) changeCurrentContextWithName:(NSString*)name;
- (void) updateCurrentContextWithPath:(NSArray*)path;
- (NSArray*) arrayForSave;
- (id<BrowseContext>) forkCurrentContextWithName:(NSString*)name;
@end

NS_ASSUME_NONNULL_END
