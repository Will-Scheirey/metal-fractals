//
//  Shaders.metal
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#include <metal_stdlib>
#include "ShaderDefinitions.h"
using namespace metal;

constexpr sampler textureSampler (mag_filter::linear,
                                  min_filter::linear);

struct VertexOut {
    float4 color;
    float4 pos [[position]];
    
    float2 textureCoordinate;
};

vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]], 
                              unsigned int vid [[vertex_id]],
                              constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])

{
    Vertex in = vertexArray[vid];
    float2 viewportSize = float2(*viewportSizePointer);
    
    VertexOut vOut;
    vOut.pos = float4(in.pos / viewportSize / 2.0, 0, 1);
    vOut.textureCoordinate = in.textureCoordinate;
    
    return vOut;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]], texture2d<half> colorTexture [[ texture(0) ]])
{
    half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}
