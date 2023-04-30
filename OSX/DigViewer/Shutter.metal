//
//  Shutter.metal
//  DigViewer
//
//  Created by Hiroshi Murayama on 2023/04/29.
//  Copyright © 2023 Hiroshi Murayama <opiopan@gmail.com>. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h>

extern "C" { namespace coreimage {
    float4 shutter(sampler from, sampler to, float time, float scale){
        float2 fc = from.coord();
        float4 f = from.sample(fc);
        float2 tc = from.coord();
        float4 t = to.sample(tc);
        float2 size = from.size() * scale;
        float nX = (size.x - fc.x) / size.x;
        return nX > time ? f : t;
    }
}}
