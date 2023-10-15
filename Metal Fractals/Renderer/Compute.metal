//
//  Compute.metal
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#include <metal_stdlib>

#include "Colormaps/colormaps.metal"
#include "ComplexNumber.metal"

#define INITIAL_OFFSET_Y 0
#define INITIAL_OFFSET_X 0.625
#define INITIAL_SCALE 2.5


#define MAX_ITERATIONS 100
#define ESCAPE_THRESHOLD 4.0

using namespace metal;

float3 HUEtoRGB(float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R,G,B));
}

float3 HSLtoRGB(float3 HSL)
{
   float3 RGB = HUEtoRGB(HSL.x);
   float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
   return (RGB - 0.5) * C + HSL.z;
}

struct VertexOut {
    float4 color;
    float4 pos [[position]];
};

float3 doMandelbrot(ComplexNumber<float> c, const uint maxIterations, const float escapeThreshold)
{
    uint numIter = 0;
    ComplexNumber<float> z(c.a, c.b);
    
    while (numIter < maxIterations && z.sqmag() < escapeThreshold)
    {
        z = z * z + c;
//        z = pow(z, 3) + icos(isinh(z) * c);
//        z = z * z + ComplexNumber<float>(0.0, 0.8);
        numIter++;
    }
    
    if(numIter == maxIterations)
        return float3(0);
    
    
    
    float smoothed = log2(log2(z.a * z.a + z.b * z.b) / 2.0) / log(2.0);
    
    float n = numIter + 1 - smoothed;
    
    float i = n / (float)maxIterations;
    
    return colormap::MATLAB::copper::colormap(i).xyz;
}

kernel void mandelbrotShader(texture2d<float, access::write> output [[ texture(0) ]],
                             uint2 pos [[ thread_position_in_grid ]],
                             device const float2 *offset [[ buffer(0)]],
                             device const float *zoom [[ buffer(1) ]],
                             device const uint* maxIterations [[ buffer(2) ]],
                             device const float* escapeThreshold [[ buffer(3) ]])
{
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    float size = min(width, height);
    
    if(pos.x > width || pos.y > height)
        return;
    
    float2 uv = float2((pos.x/(float)size - width/size/2) * INITIAL_SCALE * (*zoom) - INITIAL_OFFSET_X + offset->x,
                       (pos.y/(float)size - height/size/2) * INITIAL_SCALE * (*zoom) - INITIAL_OFFSET_Y + offset->y);
        
    output.write(float4(doMandelbrot(ComplexNumber<float>(uv.x, uv.y), *maxIterations, *escapeThreshold), 1), pos);
}
