//
//  BrowseContextArray.m
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/04.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import "BrowseContextArray.h"

static NSString* kContextName = @"name";
static NSString* kContextPath = @"path";
static NSString* kContextPresentationViewType = @"viewType";
static NSString* kDefaultContextName = @"Default";

//-----------------------------------------------------------------------------------------
// Array element implementation
//-----------------------------------------------------------------------------------------
@interface BrowseContextImp : NSObject<BrowseContext>
@property (nonatomic) NSString* name;
@property (nonatomic) NSArray* path;
@property (nonatomic) NSString* pathString;
@property (nonatomic) int presentationViewType;
@property (nonatomic, readonly) BOOL isCurrent;
- (void) willChangeIsCurrent;
- (void) didChangeIsCurrent;
@end

@implementation BrowseContextImp{
    __weak BrowseContextArray* _holder;
}

- (id)initWithHolder: (BrowseContextArray*) holder
{
    self = [super init];
    if (self){
        _holder = holder;
        _presentationViewType = 0;
    }
    return self;
}

- (void) setPath:(NSArray *)path
{
    _path = path;
    NSMutableString* pathString = [NSMutableString string];
    for (NSString* flagment in path){
        [pathString appendString:@"/"];
        [pathString appendString:flagment];
    }
    self.pathString = [NSString stringWithString:pathString];
}

- (BOOL) isCurrent
{
    return self == _holder.currentContext;
}

- (void) willChangeIsCurrent
{
    [self willChangeValueForKey:@"isCurrent"];
    [self willChangeValueForKey:@"isCurrentString"];
}

- (void) didChangeIsCurrent
{
    [self didChangeValueForKey:@"isCurrent"];
    [self didChangeValueForKey:@"isCurrentString"];
}

- (NSString*) isCurrentString
{
    if (self.isCurrent){
        return @"⚫︎";
    }else{
        return @"";
    }
}


@end

//-----------------------------------------------------------------------------------------
// Array implementation
//-----------------------------------------------------------------------------------------
@implementation BrowseContextArray

- (id) initWithArray:(NSArray*) array currentPath:(NSArray*) path
{
    self = [super init];
    if (self){
        _array = [NSMutableArray array];
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
            id name = [obj objectForKey:kContextName];
            id path = [obj objectForKey:kContextPath];
            if ([name isKindOfClass:[NSString class]] && [path isKindOfClass:[NSArray class]]){
                BrowseContextImp* element = [[BrowseContextImp alloc] initWithHolder:self];
                element.name = name;
                element.path = path;
                id viewType = [obj objectForKey:kContextPresentationViewType];
                if ([viewType isKindOfClass:[NSNumber class]]){
                    element.presentationViewType = (int)[(NSNumber*)viewType integerValue];
                }else{
                    element.presentationViewType = 0;
                }
                [_array addObject:element];
            }
        }];
        if (_array.count == 0){
            BrowseContextImp* element = [[BrowseContextImp alloc] initWithHolder:self];
            element.name =  kDefaultContextName;
            element.path = path;
            element.presentationViewType = 0;
            [_array addObject:element];
        }
        _currentContext = _array[0];
    }
    return self;
}

+ (BrowseContextArray*) arrayWithArray:(NSArray *)array currentPath:(NSArray*) path
{
    return [[BrowseContextArray alloc] initWithArray:array currentPath:path];
}

- (void) changeCurrentContextWithName: (NSString*) name
{
    BrowseContextImp* found = nil;
    for (int i = 0; i < _array.count; i++){
        BrowseContextImp* context = _array[i];
        if ([context.name isEqualToString:name]){
            found = context;
            break;
        }
    }
    if (found){
        BrowseContextImp* old = (BrowseContextImp*)_currentContext;
        [old willChangeIsCurrent];
        [found willChangeIsCurrent];
        _currentContext = found;
        [old didChangeIsCurrent];
        [found didChangeIsCurrent];
    }
}

- (void) updateCurrentContextWithPath: (NSArray*) path presentationViewType:(int)type
{
    _currentContext.path = path;
    _currentContext.presentationViewType = type;
}

- (NSArray*) arrayForSave
{
    NSMutableArray* array = [NSMutableArray array];
    [_array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop){
        [array addObject:@{
            kContextName : ((BrowseContextImp*)obj).name,
            kContextPath : ((BrowseContextImp*)obj).path,
            kContextPresentationViewType : [NSNumber numberWithInt:((BrowseContextImp*)obj).presentationViewType],
        }];
    }];
    return array;
}

- (id<BrowseContext>) forkCurrentContextWithName:(NSString*)name
{
    BrowseContextImp* newContext = nil;
    if (_currentContext){
        newContext = [[BrowseContextImp new] initWithHolder:self];
        newContext.name = name;
        newContext.path = _currentContext.path;
        newContext.presentationViewType = _currentContext.presentationViewType;
    }
    return newContext;
}

@end