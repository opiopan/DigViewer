//
//  ThumbnailCache.mm
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/05/28.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#import "ThumbnailCache.h"
#import "PathNode.h"
#import "ThumbnailConfigController.h"

#include <memory>
#include <string>
#include <thread>
#include <list>
#include <unordered_map>
#include <optional>
#include "CoreFoundationHelper.h"

static constexpr auto CACHE_SIZE = 300;
static constexpr auto FOLDER_CACHE_SIZE = 150;
static constexpr auto THUMBNAIL_MAX_SIZE = 384.;

//-----------------------------------------------------------------------------------------
// stock images
//-----------------------------------------------------------------------------------------
static ECGImageRef stock_image_unavailable;
static ECGImageRef stock_image_processing;
static ECGImageRef stock_image_corrupted;

//-----------------------------------------------------------------------------------------
// Image cache pool
//-----------------------------------------------------------------------------------------
struct cache_entry{
    void* key;
    __weak id node {nullptr};
    ECGImageRef image{nullptr};
};
using cache_entry_ptr = std::shared_ptr<cache_entry>;

class lru_cache{
    size_t size;
    using pool_type = std::list<cache_entry_ptr>;
    using pool_itr = pool_type::iterator;
    pool_type pool;
    std::unordered_map<void*, pool_itr> index;
    
public:
    lru_cache(size_t size):size{size}{}
    
    std::shared_ptr<cache_entry> get(__weak id key){
        auto keypt = (__bridge void*)key;
        if (index.count(keypt) > 0){
            auto value_itr = index[keypt];
            auto value = *value_itr;
            pool.erase(value_itr);
            pool.push_front(value);
            index[keypt] = pool.begin();
            return value;
        }else{
            return nullptr;
        }
    }
    
    void put(__weak id key, cache_entry_ptr& value){
        value->key = (__bridge void*)key;
        if (pool.size() >= size){
            auto itr = pool.end();
            itr--;
            index.erase((*itr)->key);
            pool.pop_back();
        }
        pool.push_front(value);
        index[(__bridge void*)key] = pool.begin();
    }
    
    void clear(){
        pool.clear();
        index.clear();
    }
};

//-----------------------------------------------------------------------------------------
// Rendering command definition
//-----------------------------------------------------------------------------------------
struct rendering_command{
    cache_entry_ptr image_node;
    cache_entry_ptr folder_node;
    NSString* image_path;
    bool is_valid_command{true};
    bool is_image;
    bool is_raster_image;
    bool is_raw_image;
    void (^completion)(__weak id);
};
using rendering_command_ptr = std::shared_ptr<rendering_command>;

//-----------------------------------------------------------------------------------------
// Rendering functions
//-----------------------------------------------------------------------------------------
struct thumbnail_config{
    bool use_embedded_thumbnail_for_RAW;
    bool use_embedded_thumbnail;
    FolderThumbnailRepresentationType representation_type;
    double folder_icon_size;
    double folder_icon_opacity;
};

static CGImageRef rotate_image(CGImageRef src, int rotation, CGFloat thumbnail_size){
    // create bitmap context presenting rotated image
    CGSize size = CGSizeMake(CGImageGetWidth(src), CGImageGetHeight(src));
    CGFloat destRatio = MIN(thumbnail_size / size.width, thumbnail_size / size.height);
    CGSize destSize = size;
    if (destRatio < 1){
        destSize.width *= destRatio;
        destSize.height *= destRatio;
    }
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context;
    if (rotation >= 5 && rotation <= 8){
        context = CGBitmapContextCreate(NULL, destSize.height, destSize.width, 8, 0,colorSpace, kCGImageAlphaNoneSkipLast);
    }else{
        context = CGBitmapContextCreate(NULL, destSize.width, destSize.height, 8, 0, colorSpace, kCGImageAlphaNoneSkipLast);
    }

    // set transform-matrix up
    switch (rotation){
        case 1:
        case 2:
            /* nothing to do */
            break;
        case 5:
        case 8:
            /* 90 degrees rotation */
            CGContextRotateCTM(context, M_PI / 2.);
            CGContextTranslateCTM (context, 0, -destSize.height);
            break;
        case 3:
        case 4:
            /* 180 degrees rotation */
            CGContextRotateCTM(context, -M_PI);
            CGContextTranslateCTM (context, -destSize.width, -destSize.height);
            break;
        case 6:
        case 7:
            /* 270 degrees rotation */
            CGContextRotateCTM(context, -M_PI / 2.);
            CGContextTranslateCTM (context, -destSize.width, 0);
            break;
    }
    
    //draw image with rotation
    CGContextDrawImage(context, CGRectMake(0, 0, destSize.width, destSize.height), src);
    return CGBitmapContextCreateImage(context);
}

static CGImageRef CGImage_from_NSImage(NSImage* src, CGFloat thumbnail_size){
    if (thumbnail_size == 0){
        thumbnail_size = THUMBNAIL_MAX_SIZE;
    }
    
    NSSize src_size= src.size;
    CGFloat gain = thumbnail_size / MAX(src_size.width, src_size.height);
    NSSize dest_size;
    dest_size.width = src_size.width * gain;
    dest_size.height = src_size.height * gain;
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context(CGBitmapContextCreate(NULL, dest_size.width, dest_size.height, 8, 0,
                                                colorSpace, kCGImageAlphaPremultipliedLast));
    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:gc];
    NSRect target_rect = NSZeroRect;
    target_rect.size = dest_size;
    [src drawInRect:target_rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
           fraction:1.0 respectFlipped:YES hints:nil];
    [NSGraphicsContext restoreGraphicsState];
    return CGBitmapContextCreateImage(context);
}

static CGImageRef render_thumbnail_image(const rendering_command& command, CGFloat thumbnail_size, thumbnail_config& config){
    static NSDictionary* thumbnailOption = nil;
    static NSDictionary* thumbnailOptionUsingEmbedded = nil;
    if (!thumbnailOption){
        thumbnailOptionUsingEmbedded = @{(__bridge NSString*)kCGImageSourceThumbnailMaxPixelSize:@(THUMBNAIL_MAX_SIZE),
                                         (__bridge NSString*)kCGImageSourceCreateThumbnailWithTransform:@(YES)};
        thumbnailOption = @{(__bridge NSString*)kCGImageSourceThumbnailMaxPixelSize:@(THUMBNAIL_MAX_SIZE),
                            (__bridge NSString*)kCGImageSourceCreateThumbnailFromImageAlways:@(YES),
                            (__bridge NSString*)kCGImageSourceCreateThumbnailWithTransform:@(YES)};
    }
    
    CGFloat thumbnail_max_size = thumbnail_size == 0. ? THUMBNAIL_MAX_SIZE : thumbnail_size;
    
    ECGImageRef thumbnail;
    if (command.is_raster_image){
        NSURL* url = [NSURL fileURLWithPath:command.image_path];
        ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
        if (!imageSource.isNULL()){
            int orientation = 1;
            NSDictionary* option = (command.is_raw_image && config.use_embedded_thumbnail_for_RAW) ||
                                   (!command.is_raw_image && command.is_raster_image && config.use_embedded_thumbnail) ||
                                   thumbnail_size != 0 ?
                                   thumbnailOptionUsingEmbedded : thumbnailOption;
            thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)option);
            if (thumbnail.isNULL()){
                thumbnail = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                NSDictionary* meta = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, NULL, 0);
                NSNumber* data = [meta valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
                orientation = data ? data.intValue : 1;
            }
            if (orientation != 1 ||
                CGImageGetWidth(thumbnail) > thumbnail_max_size || CGImageGetHeight(thumbnail) > thumbnail_max_size){
                thumbnail = rotate_image(thumbnail, orientation, thumbnail_max_size);
            }
        }else{
            thumbnail = stock_image_unavailable;
        }
    }else{
        NSImage* image = [[NSImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:command.image_path]];
        if (image){
            thumbnail = CGImage_from_NSImage(image, thumbnail_max_size);
        }else{
            thumbnail = stock_image_unavailable;
        }
    }
    
    return thumbnail.transferOwnership();
}

static CGImageRef composit_folder_image(CGImageRef src, FolderThumbnailRepresentationType type, CGFloat thumbnail_max_size, const thumbnail_config& config){
    // create a bitmap-context to hold the image composited
    CGFloat width = src ? CGImageGetWidth(src) : thumbnail_max_size;
    CGFloat height = src ? CGImageGetHeight(src) : thumbnail_max_size;
    CGFloat normalizedLength = MAX(width, height);
    ECGColorSpaceRef colorSpace(CGColorSpaceCreateDeviceRGB());
    ECGContextRef context(CGBitmapContextCreate(NULL, normalizedLength, normalizedLength, 8, 0,
                                                colorSpace, kCGImageAlphaPremultipliedLast));

    // get folder icon image
    NSImage* folderImage = [NSImage imageNamed:NSImageNameFolder];
    
    if (type == FolderThumbnailIconOnImage){
        // draw source image
        CGContextDrawImage(context, CGRectMake((normalizedLength - width) / 2, (normalizedLength - height) / 2,
                                               CGImageGetWidth(src), CGImageGetHeight(src)), src);
        
        // draw folder image
        NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:gc];
        NSRect targetRect = NSZeroRect;
        targetRect.size.width = targetRect.size.height = normalizedLength * config.folder_icon_size;
        targetRect.origin.x = normalizedLength - targetRect.size.width * 1.11;
        [folderImage drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
                       fraction:config.folder_icon_opacity
                 respectFlipped:YES hints:nil];
        [NSGraphicsContext restoreGraphicsState];
    }else{
        // draw folder image
        NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:gc];
        NSRect targetRect = NSZeroRect;
        targetRect.size.width = targetRect.size.height = normalizedLength;
        [folderImage drawInRect:targetRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];

        // draw source image
        CGFloat minLength = MIN(width, height);
        ECGImageRef clipedImage;
        clipedImage = CGImageCreateWithImageInRect(src, CGRectMake((width - minLength) / 2,(height - minLength) / 2,
                                                                   minLength , minLength));
        CGFloat ratio = 0.55 * (normalizedLength / minLength);
        CGFloat xOffset = (normalizedLength - minLength * ratio) / 2;
        CGFloat yOffset = (normalizedLength - minLength * ratio) / 2 - normalizedLength * 0.05;
        CGContextTranslateCTM (context, xOffset, yOffset);
        CGContextScaleCTM(context, ratio, ratio);
        CGContextDrawImage(context, CGRectMake(0, 0, minLength , minLength), clipedImage);
    }
    
    return CGBitmapContextCreateImage(context);
}

//-----------------------------------------------------------------------------------------
// Cache manager
//-----------------------------------------------------------------------------------------
class cache_manager{
    using wait_queue = std::list<rendering_command_ptr>;
    using wait_queue_itr = wait_queue::iterator;
    std::mutex mutex;
    std::condition_variable cv;
    bool should_stop{false};
    wait_queue queue;
    std::unordered_map<void*, wait_queue_itr> queue_index;
    rendering_command_ptr current;
    lru_cache cache{CACHE_SIZE};
    lru_cache folder_cache{FOLDER_CACHE_SIZE};
    std::thread renderer;
    thumbnail_config rendering_config;
    std::unordered_map<void*, void*> priority_targets;
    
public:
    static thumbnail_config& make_rendering_config(thumbnail_config& config){
        ThumbnailConfigController* controller = [ThumbnailConfigController sharedController];
        config.use_embedded_thumbnail_for_RAW = controller.useEmbeddedThumbnailForRAW;
        config.use_embedded_thumbnail = controller.useEmbeddedThumbnail;
        config.representation_type = controller.representationType;
        config.folder_icon_size = controller.folderIconSize.doubleValue;
        config.folder_icon_opacity = controller.folderIconOpacity.doubleValue;
        return config;
    }
    
    cache_manager(){
        renderer = std::thread([this]{
            std::unique_lock<std::mutex> lock{mutex};
            while (true){
                cv.wait(lock, [this]{return should_stop || queue.size() > 0;});
                if (should_stop){
                    break;
                }
                auto itr = queue.begin();
                if (!(*itr)->is_valid_command){
                    (*itr)->completion((*itr)->image_node->node);
                    if ((*itr)->folder_node){
                        (*itr)->completion((*itr)->folder_node->node);
                    }
                    continue;
                }
                current = *itr;
                queue.erase(itr);
                if (current->is_image){
                    queue_index.erase((__bridge void*)current->image_node->node);
                }else{
                    queue_index.erase((__bridge void*)current->folder_node->node);
                }

                // render thumbnail of image node if necessary
                auto&& image_entry = cache.get(current->image_node->node);
                if (image_entry){
                    current->image_node = image_entry;
                }else{
                    auto config = rendering_config;
                    lock.unlock();
                    auto&& image = render_thumbnail_image(*current, 0, config);
                    lock.lock();
                    if (image){
                        current->image_node->image = image;
                    }else{
                        current->image_node->image = stock_image_corrupted;
                    }
                    cache.put(current->image_node->node, current->image_node);
                    current->completion(current->image_node->node);
                }
                
                // composit thumbnail of folder if necessary
                if (!current->is_image){
                    if (rendering_config.representation_type != FolderThumbnailOnlyImage){
                        auto config = rendering_config;
                        ECGImageRef src = current->image_node->image;
                        lock.unlock();
                        auto&& image = composit_folder_image(src, config.representation_type, THUMBNAIL_MAX_SIZE, config);
                        lock.lock();
                        current->folder_node->image = image;
                        folder_cache.put(current->image_node->node, current->folder_node);
                    }
                    current->completion(current->folder_node->node);
                }
                
                current = nullptr;
            }
        });
    }
    
    ~cache_manager(){
        stop();
    }
    
    void stop(){
        {
            std::lock_guard<std::mutex> lock{mutex};
            should_stop = true;
            cv.notify_all();
        }
        renderer.join();
    }
    
    void set_rendering_config(){
        std::lock_guard<std::mutex> lock{mutex};
        thumbnail_config config;
        make_rendering_config(config);
        rendering_config = config;
        folder_cache.clear();
    }
    
    CGImageRef find_cahce_and_request_rendering(PathNode* node, void (^completion)(__weak id)){
        std::lock_guard<std::mutex> lock{mutex};
        auto need_rendering_as_folder = !node.isImage && rendering_config.representation_type != FolderThumbnailOnlyImage;
        PathNode* image_node = node.imageNode;
        auto cached_entry = need_rendering_as_folder ? folder_cache.get(image_node) : cache.get(image_node);
        if (cached_entry){
            auto image{cached_entry->image};
            return image.transferOwnership();
        }else{
            if ((node.isImage && (!current || current->image_node->node != node) && queue_index.count((__bridge void*)node) == 0) ||
                (!node.isImage && (!current || !current->folder_node || current->folder_node->node != node) && queue_index.count((__bridge void*)node) == 0)){
                auto entry = std::make_shared<rendering_command>();
                entry->image_node = std::make_shared<cache_entry>();
                entry->image_node->node = image_node;
                if (!node.isImage){
                    entry->folder_node = std::make_shared<cache_entry>();
                    entry->folder_node->node = node;
                }
                entry->is_image = node.isImage;
                entry->image_path = image_node.imagePath;
                entry->is_raw_image = image_node.isRawImage;
                entry->is_raster_image = image_node.isRasterImage;
                entry->completion = completion;
                queue.push_back(entry);
                auto itr = queue.end();
                itr--;
                queue_index[(__bridge void*)node] = itr;
                cv.notify_all();
            }
            auto image{stock_image_processing};
            return image.transferOwnership();
        }
    }
    
    void cleare_waiting_queue(){
        std::lock_guard<std::mutex> lock{mutex};
        for (auto itr = queue.begin(); itr != queue.end(); itr++){
            (*itr)->is_valid_command = false;
        }
        queue.clear();
        queue_index.clear();
        priority_targets.clear();
    }
    
    void reschedule_waitaing_queue(NSArrayController* array, NSIndexSet* indexes){
        std::lock_guard<std::mutex> lock{mutex};
        priority_targets.clear();
        NSArray* objects = array.arrangedObjects;
        [indexes enumerateRangesUsingBlock:^(NSRange range, BOOL* end){
            for (auto i = range.location; i < range.location + range.length; i++){
                void* key = (__bridge void*)objects[i];
                priority_targets[key] = key;
            }
        }];
        wait_queue_itr next;
        for (auto itr = queue.begin(); itr != queue.end(); itr = next){
            auto key = (__bridge void*)((*itr)->folder_node ? (*itr)->folder_node->node : (*itr)->image_node->node);
            next = itr;
            next++;
            if (priority_targets.count(key) == 0){
                if ((*itr)->folder_node){
                    [(*itr)->folder_node->node updateThumbnailCounter];
                }else{
                    [(*itr)->image_node->node updateThumbnailCounter];
                }
                queue.erase(itr);
                queue_index.erase(key);
            }
        }
    }
};

//-----------------------------------------------------------------------------------------
// Image cache interface for Objective-C code
//-----------------------------------------------------------------------------------------
@implementation ThumbnailCache{
    std::unique_ptr<cache_manager> _manager;
}

- (id) init{
    self = [super init];
    if (self){
        if (!stock_image_unavailable){
            stock_image_unavailable = CGImage_from_NSImage([PathNode unavailableImage], THUMBNAIL_MAX_SIZE);
        }
        if (!stock_image_processing){
            stock_image_processing = CGImage_from_NSImage([PathNode processingImage], THUMBNAIL_MAX_SIZE);
        }
        if (!stock_image_corrupted){
            stock_image_corrupted = CGImage_from_NSImage([PathNode corruptedImage], THUMBNAIL_MAX_SIZE);
        }
        _manager = std::make_unique<cache_manager>();

        _manager->set_rendering_config();
        ThumbnailConfigController* controller = [ThumbnailConfigController sharedController];
        [controller addObserver:self forKeyPath:@"updateCount" options:0 context:nil];
    }
    return self;
}

- (void) dealloc{
    _manager = nullptr;
    ThumbnailConfigController* controller = [ThumbnailConfigController sharedController];
    [controller removeObserver:self forKeyPath:@"updateCount"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    _manager->set_rendering_config();
}

+ (CGImageRef) getThumbnailImageOf:(PathNode*)node size:(CGFloat)size{
    PathNode* image_node = node.imageNode;
    rendering_command entry;
    entry.image_node = std::make_shared<cache_entry>();
    entry.image_node->node = image_node;
    entry.is_image = node.isImage;
    entry.image_path = image_node.imagePath;
    entry.is_raw_image = image_node.isRawImage;
    entry.is_raster_image = image_node.isRasterImage;
    thumbnail_config config;
    cache_manager::make_rendering_config(config);
    auto&& image = render_thumbnail_image(entry, size, config);
    if (node.isImage || config.representation_type == FolderThumbnailOnlyImage){
        return image;
    }else{
        return composit_folder_image(image, config.representation_type, size, config);
    }
}

- (CGImageRef) getThumbnailImageOf:(PathNode*)node completion:(void (^)(__weak id)) completion{
    if (completion){
        return _manager->find_cahce_and_request_rendering(node, completion);
    }else{
        return [ThumbnailCache getThumbnailImageOf:node size:0];
    }
}

- (void) clearWaitingQueue{
    _manager->cleare_waiting_queue();
}

- (void) rescheduleWaitingQueueWithArrayController:(NSArrayController*)array indexes:(NSIndexSet*)indexes{
    _manager->reschedule_waitaing_queue(array, indexes);
}
@end
