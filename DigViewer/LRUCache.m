//
//  LRUCache.m
//  DigViewerRemote
//
//  Created by opiopan on 2015/10/10.
//  Copyright © 2015年 opiopan. All rights reserved.
//

#import "LRUCache.h"


//-----------------------------------------------------------------------------------------
// CacheEntry: キャッシュの要素
//-----------------------------------------------------------------------------------------
@interface CacheEntry : NSObject
@property CacheEntry* next;
@property CacheEntry* prev;
@property NSString* key;
@property id value;
@end
@implementation CacheEntry
@end


//-----------------------------------------------------------------------------------------
// LRUCacheの実装
//-----------------------------------------------------------------------------------------
@implementation LRUCache {
    NSMutableDictionary* _index;
    CacheEntry* _head;
    CacheEntry* _tail;
    int _count;
    int _maxCount;
}

+ (LRUCache *)cacheWithSize:(int)size
{
    LRUCache* cache = [LRUCache new];
    cache->_index = [NSMutableDictionary dictionary];
    cache->_maxCount = size;
    cache->_count = 0;
    cache->_head = nil;
    cache->_tail = nil;
    return cache;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    CacheEntry* entry = [_index valueForKey:key];
    if (!entry){
        entry = [CacheEntry new];
        entry.key = key;
        entry.value = value;
        entry.next = nil;
        entry.prev = nil;
        [_index setValue:entry forKey:key];
        [self addCacheEntry:entry];
        if (_count > _maxCount){
            [_index removeObjectForKey:_head.key];
            [self removeCacheEntry:_head];
        }
    }
}

- (id)valueForKey:(NSString *)key
{
    id value = nil;
    CacheEntry* entry = [_index valueForKey:key];
    if (entry){
        value = entry.value;
        [self removeCacheEntry:entry];
        [self addCacheEntry:entry];
    }
    return value;
}

- (void)addCacheEntry:(CacheEntry*)entry
{
    if (_tail){
        entry.prev = _tail;
        _tail.next = entry;
        _tail = entry;
    }else{
        _head = entry;
        _tail = entry;
    }
    _count++;
}

- (void)removeCacheEntry:(CacheEntry*)entry
{
    if (entry.prev){
        entry.prev.next = entry.next;
    }else{
        _head = entry.next;
    }
    if (entry.next){
        entry.next.prev = entry.prev;
    }else{
        _tail = entry.prev;
    }
    entry.next = nil;
    entry.prev = nil;
    _count--;
}

@end
