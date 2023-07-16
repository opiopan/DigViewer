//
//  DataCache.mm
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/07/15.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "DataCache.h"

#include <string>
#include <thread>
#include <vector>
#include <stdexcept>
#include "cache_common.h"

static constexpr auto CACHE_SIZE = 16;
static constexpr auto PROCESSING_NUM = 8;

//-----------------------------------------------------------------------------------------
// image data cache
//-----------------------------------------------------------------------------------------
struct cache_entry{
    std::string key;
    NSData* data{nullptr};
};
using data_lru_cache = lru_cache<std::string, cache_entry>;
using cache_entry_ptr = data_lru_cache::value_ptr;

//-----------------------------------------------------------------------------------------
// cache manager interface
//-----------------------------------------------------------------------------------------
class cache_manager{
public:
    virtual void get_data(const std::string& identifier, DataCacheCompletion completion) = 0;
    virtual void add_data(cache_entry_ptr entry) = 0;
    virtual void return_thread_to_freepool(const std::string& identifier) = 0;
};

//-----------------------------------------------------------------------------------------
// image data instancing thread
//-----------------------------------------------------------------------------------------
class instancing_thread{
    struct processing_ctx{
        cache_entry_ptr entry{nullptr};
        std::vector<DataCacheCompletion> completion_handlers;
    };
    
    enum class thread_status{free, running};
    
    const unsigned long threadid;
    std::mutex mutex;
    std::condition_variable cv;
    std::thread instanciator;
    bool should_stop{false};
    thread_status status{thread_status::free};
    processing_ctx context;
    cache_manager& manager;
    
public:
    instancing_thread(unsigned long threadid, cache_manager& manager): threadid(threadid), manager(manager){
        instanciator = std::thread([this]{
            std::unique_lock lock{mutex};
            while (true){
                cv.wait(lock, [this]{return status == thread_status::running || should_stop;});
                if (should_stop){
                    break;
                }
                lock.unlock();
                __block NSData* image_data = nil;
                if (@available(macOS 10.15, *)) {
                    NSString* identifier = [NSString stringWithUTF8String:context.entry->key.c_str()];
                    PHFetchResult<PHAsset*>* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
                    if (assets.count > 0){
                        PHImageRequestOptions* options = [PHImageRequestOptions new];
                        options.synchronous = YES;
                        options.networkAccessAllowed = YES;
                        [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:assets[0] options:options
                                                                                  resultHandler:^(NSData* data, NSString* dataUTI,
                                                                                                  CGImagePropertyOrientation orientation,
                                                                                                  NSDictionary* info){
                            image_data = data;
                        }];
                    }
                }
                context.entry->data = image_data;
                this->manager.add_data(context.entry);
                lock.lock();
                for (auto itr = context.completion_handlers.begin(); itr != context.completion_handlers.end(); itr++){
                    auto completion = *itr;
                    dispatch_async(dispatch_get_main_queue(), ^{completion(image_data);});
                }
                auto entry = context.entry;
                context.entry = nullptr;
                context.completion_handlers.clear();
                status = thread_status::free;
                lock.unlock();
                this->manager.return_thread_to_freepool(entry->key);
                lock.lock();
            }
        });
    }
    
    ~instancing_thread(){
        stop();
    }
    
    void stop(){
        {
            std::lock_guard lock{mutex};
            should_stop = true;
            cv.notify_all();
        }
        instanciator.join();
    }
    
    void instanciate_data(cache_entry_ptr entry, DataCacheCompletion completion){
        std::lock_guard lock{mutex};
        if (status != thread_status::free){
            NSLog(@"Instancing image data thread [%ld] is not free", threadid);
            throw std::runtime_error("may be logical bug");
        }
        status = thread_status::running;
        context.entry = entry;
        context.completion_handlers.push_back(completion);
        cv.notify_all();
    }
    
    void add_completion_handler(DataCacheCompletion completion){
        std::lock_guard lock{mutex};
        if (status == thread_status::running){
            context.completion_handlers.push_back(completion);
        }else{
            // It is theoretically possible to reach this route with an extremely low probability.
            // Unfortunately, if this route is entered, it will behave as if it cannot instantiate the image data.
            dispatch_async(dispatch_get_main_queue(), ^{completion(nil);});
        }
    }
};

//-----------------------------------------------------------------------------------------
// cahce manager implementation
//-----------------------------------------------------------------------------------------
class cache_manager_imp : public cache_manager{
    struct command {
        std::string identifier;
        DataCacheCompletion completion;
    };
    using command_ptr = std::shared_ptr<command>;
    using command_queue = std::list<command_ptr>;
    using command_queue_itr = command_queue::iterator;
    std::mutex mutex;
    std::condition_variable cv;
    bool should_stop{false};
    command_queue queue;
    data_lru_cache cache{CACHE_SIZE};
    std::vector<std::unique_ptr<instancing_thread>> threads;
    std::list<unsigned long> free_threads;
    std::unordered_map<std::string, unsigned long> running_threads;
    std::thread coordinator;
    
public:
    cache_manager_imp(){
        for (auto i = 0; i < PROCESSING_NUM; i++){
            auto thread{std::make_unique<instancing_thread>(i, *this)};
            threads.push_back(std::move(thread));
            free_threads.push_back(i);
        }
        coordinator = std::thread([this]{
            std::unique_lock lock{mutex};
            while (true){
                cv.wait(lock, [this]{return (queue.size() > 0 && free_threads.size() > 0) || should_stop;});
                if (should_stop){
                    break;
                }
                auto cmd = queue.front();
                queue.pop_front();
                auto entry = cache.get(cmd->identifier);
                if (entry){
                    NSData* data = entry->data;
                    auto completion = cmd->completion;
                    dispatch_async(dispatch_get_main_queue(), ^{completion(data);});
                }else if (running_threads.count(cmd->identifier) > 0){
                    threads[running_threads[cmd->identifier]]->add_completion_handler(cmd->completion);
                }else{
                    auto threadid = free_threads.front();
                    free_threads.pop_front();
                    running_threads[cmd->identifier] = threadid;
                    auto entry = std::make_shared<cache_entry>();
                    entry->key = cmd->identifier;
                    threads[threadid]->instanciate_data(entry, cmd->completion);
                }
            }
        });
    }
    
    ~cache_manager_imp(){
        stop();
    }
    
    void stop(){
        {
            std::lock_guard lock{mutex};
            should_stop = true;
            cv.notify_all();
        }
        coordinator.join();
    }
    
    void get_data(const std::string& identifier, DataCacheCompletion completion) override{
        std::lock_guard lock{mutex};
        auto entry = cache.get(identifier);
        if (entry){
            if ([NSThread isMainThread]){
                completion(entry->data);
            }else{
                NSData* data = entry->data;
                dispatch_async(dispatch_get_main_queue(), ^{completion(data);});
            }
        }else{
            auto cmd = std::make_shared<command>();
            cmd->identifier = identifier;
            cmd->completion = completion;
            queue.push_back(cmd);
            cv.notify_all();
        }
    }
    
    void add_data(cache_entry_ptr entry) override{
        std::lock_guard lock{mutex};
        cache.put(entry->key, entry);
    }
    
    void return_thread_to_freepool(const std::string& identifier) override{
        std::lock_guard lock{mutex};
        auto threadid = running_threads[identifier];
        running_threads.erase(identifier);
        free_threads.push_back(threadid);
        cv.notify_all();
    }
};

//-----------------------------------------------------------------------------------------
// Image data cache accessor
//-----------------------------------------------------------------------------------------
@implementation DataCache{
    std::unique_ptr<cache_manager_imp> _manager;
}

- (id) init
{
    self = [super init];
    if (self){
        _manager = std::make_unique<cache_manager_imp>();
    }
    return self;
}

- (void) dealloc{
    _manager = nullptr;
}

- (void) getNSdataOf:(NSString*)localIdentifier completion:(DataCacheCompletion)completion
{
    auto identifier{std::string(localIdentifier.UTF8String)};
    _manager->get_data(identifier, completion);
}

@end
