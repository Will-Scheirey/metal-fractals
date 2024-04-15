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
#define INITIAL_OFFSET_X 0
#define INITIAL_SCALE 1


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

float4 doMandelbrot(ComplexNumber<float> c, const uint maxIterations, const float escapeThreshold, const bool invertColormap, const float colormapShift, float contrastPower, const float functionWeight, float cR, float cI, const int fractalIndex)
{
    uint numIter = 0;
    ComplexNumber<float> z(c.a, c.b);
    ComplexNumber<float> c1(c.a, c.b);
    c.a = cR;
    c.b = cI;
    
    while (numIter < maxIterations && z.sqmag() < escapeThreshold)
    {
//        z = pow(ComplexNumber<float>(abs(z.a), abs(z.b)), 2) + c;
        
//        z = pow(z, 2) + c;

        
//        z = (pow(z, 2) + c) * functionWeight + (pow(z, 2) + c1) * (1 - functionWeight);

        z = pow(z, 2) + c1;
        
        /*
        if(fractalIndex == 0)
        {
            z = (pow(z, 2) + c);
        }
        else if(fractalIndex == 1)
        {
            z = (pow(z, 2) + c) * functionWeight + (pow(z, 2) + c1) * (1 - functionWeight);
        }
        else
        {
        }
         */
         
//        z = (pow(z, ComplexNumber<float>(2, 0)) + c) * functionWeight + (pow(z, ComplexNumber<float>(3, 0)) + c) * (1 - functionWeight);
//        z =
//        z = pow(cos(z), sinh(z + c));
        

//        z = ComplexNumber<float>(fmod(z.a, z.b), fmod(z.b, z.a)) * z + ComplexNumber<float>(0.0, 0.8);
        numIter++;
    }
    
    if(numIter == maxIterations)
    {
        return float4(0, 0, 0, 1);
    }
    
    float smoothed = log2(log2(z.a * z.a + z.b * z.b) / 2.0) / log(2.0);
    
    float n = numIter + 1 - smoothed;
    
    float i = n / (float)maxIterations;

    return colormap::IDL::Black_White_Linear::colormap(pow(1 * invertColormap - (i + colormapShift) * invertColormap
                                                + (i + colormapShift) * (!invertColormap), contrastPower));
    
    /*
    if(fractalIndex == 1)
    {
        
        float4 color2 = colormap::IDL::Black_White_Linear::colormap(pow(1 * 0 - (i + colormapShift) * 0
                                                                        + (i + colormapShift) * (!0), contrastPower));
        float4 color1 = colormap::IDL::CB_PiYG::colormap(pow(1 * invertColormap - (i + colormapShift) * invertColormap
                                                             + (i + colormapShift) * (!invertColormap), contrastPower));
        
        return color1 * functionWeight + color2 * (1 - functionWeight);
    }
    else if(fractalIndex == 0)
    {
        return colormap::IDL::CB_PiYG::colormap(pow(1 * invertColormap - (i + colormapShift) * invertColormap
                                                               + (i + colormapShift) * (!invertColormap), contrastPower));
    }
    else
    {
        return colormap::IDL::Black_White_Linear::colormap(pow(1 * 0 - (i + colormapShift) * 0
                                                               + (i + colormapShift) * (!0), contrastPower));
    }
     */
}

kernel void mandelbrotShader(texture2d<float, access::write> output [[ texture(0) ]],
                             uint2 pos [[ thread_position_in_grid ]],
                             device const float2 *offset [[ buffer(0)]],
                             device const float *zoom [[ buffer(1) ]],
                             device const uint* maxIterations [[ buffer(2) ]],
                             device const float* escapeThreshold [[ buffer(3) ]],
                             device const bool *invertColormap [[ buffer(4) ]],
                             device const float *colorMapShift [[ buffer(5) ]],
                             device const float *contrastPower [[ buffer(6) ]],
                             device const float *functionWeight [[ buffer(7) ]],
                             device const float *cR [[ buffer(8) ]],
                             device const float *cI [[ buffer(9) ]],
                             device const int *fractalIndex [[ buffer(10) ]]
                             )
{
    
    uint width = output.get_width();
    uint height = output.get_height();
    
    float size = min(width, height);
    
    if(pos.x > width || pos.y > height)
        return;
    
    float2 uv = float2((pos.x/(float)size - width/size/2) * INITIAL_SCALE * (*zoom) - INITIAL_OFFSET_X + offset->x,
                       (pos.y/(float)size - height/size/2) * INITIAL_SCALE * (*zoom) - INITIAL_OFFSET_Y + offset->y);
    
    output.write(doMandelbrot(ComplexNumber<float>(uv.x, uv.y), *maxIterations, *escapeThreshold, *invertColormap, *colorMapShift, *contrastPower, *functionWeight, *cR, *cI, *fractalIndex), pos);
}
