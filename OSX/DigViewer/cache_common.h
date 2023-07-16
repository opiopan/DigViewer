//
//  cache_common.h
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/07/15.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#pragma once

#include <memory>
#include <list>
#include <unordered_map>

//-----------------------------------------------------------------------------------------
// LRU algorithm
//-----------------------------------------------------------------------------------------
template <typename KEY, typename VALUE>
class lru_cache{
public:
    using value_ptr = std::shared_ptr<VALUE>;
protected:
    size_t size;
    using pool_type = std::list<value_ptr>;
    using pool_itr = typename pool_type::iterator;
    pool_type pool;
    std::unordered_map<KEY, pool_itr> index;
    
public:
    lru_cache(size_t size):size{size}{}
    
    value_ptr get(const KEY& key){
        if (index.count(key) > 0){
            auto value_itr = index[key];
            auto value = *value_itr;
            pool.erase(value_itr);
            pool.push_front(value);
            index[key] = pool.begin();
            return value;
        }else{
            return nullptr;
        }
    }
    
    void put(const KEY& key, const value_ptr& value){
        if (pool.size() >= size){
            auto itr = pool.end();
            itr--;
            index.erase((*itr)->key);
            pool.pop_back();
        }
        pool.push_front(value);
        index[key] = pool.begin();
    }
    
    void clear(){
        pool.clear();
        index.clear();
    }
};
