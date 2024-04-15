//
//  Compute.m
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#import "Compute.h"
#import "ShaderDefinitions.h"
#include <Carbon/Carbon.h>
#import <MetalKit/MetalKit.h>
#import <CoreImage/CoreImage.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#define ifKey(x) if([_keysPressed containsObject:@(x)])


#define TEXTURE_SIZE_MULT 1

float easeInSine(float x)
{
    return 1 - cos(x * M_PI_2);
}

float easeOutSine(float x) {
  return sin((x * M_PI_2));
}

float easeInOutSine(float x) {
    return -(cos(M_PI * x) - 1) / 2;
}

float easeInOutBack(float x)  {
    float c1 = 1.70158 * 0.5;
    float c2 = c1 * 1.525;

    return x < 0.5
      ? (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
      : (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;
}

Compute* computer;

// With help from https://eugenebokhan.io/introduction-to-metal-compute-part-three

@implementation Compute
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _commandBuffer;
    id<MTLComputeCommandEncoder> _encoder;
    id<MTLTexture> _texture;
    MTKView* _view;
    
    float zoom;
    float offsetX;
    float offsetY;
    float maxIterMult;
    float escapeThresholdMult;
    bool invertColormap;
    float colormapShift;
    float contrastPower;
    float functionWeight;
    float cR;
    float cI;
    
    float cMove;
    
    int totalFrames;
    
    struct Fractal fractals[14];
    int currentFractalIndex;
    int currentFractalFrameNum;
    
    bool doAnimation;
    
    int frameNum;
    
    MTLPixelFormat _format;
    
    NSMutableSet* _keysPressed;
}

-(id<MTLComputePipelineState>) buildComputePipelineWithDevice:(id<MTLDevice>)device
{
    id<MTLLibrary> library = [device newDefaultLibrary];
    
    _deviceSupportsNonuniformThreadgroups = [library.device supportsFamily:MTLGPUFamilyMetal3];
    
    id<MTLFunction> func = [library newFunctionWithName:@"mandelbrotShader"];

    NSError* err;
    id<MTLComputePipelineState>pipelineState = [device newComputePipelineStateWithFunction:func error:&err];
    if(err.code != 0)
    {
        NSLog(@"Error: %@", err);
    }
    return pipelineState;
}

-(id<MTLTexture>) textureWithDimensions:(NSUInteger)width height:(NSUInteger)height
{
    MTLTextureDescriptor* descriptor = [MTLTextureDescriptor new];
    descriptor.pixelFormat = _format;
    descriptor.textureType = MTLTextureType2D;
    
    descriptor.width = width * TEXTURE_SIZE_MULT;
    descriptor.height = height * TEXTURE_SIZE_MULT;
    descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
    
    return [_device newTextureWithDescriptor:descriptor];
}

- (nonnull id)initWitMTK:(nonnull MTKView *)view size:(CGSize)size {
    self = [super init];
    
    _device = view.device;
    _commandQueue = [_device newCommandQueue];
    _commandBuffer = [_commandQueue commandBuffer];
    _format = view.colorPixelFormat;
    _view = view;
    
    self.pipelineState = [self buildComputePipelineWithDevice:_device];
    
    [self updateSize:size];
    
    
    computer = self;
    currentFractalIndex = 0;
    
    int i = 0;
    
    /*
     fractals[i].offsetR = -0.025511;
     fractals[i].offsetI = -0.112444;
     fractals[i].zoom = 3.752134;
     fractals[i].maxIterMult = 40.5;
     fractals[i].escapeThresholdMult = 1;
     fractals[i].invertColorMap = true;
     fractals[i].colormapShift = 0.5;
     fractals[i].contrastPower = 1.203526;
     fractals[i].pauseFrames = 48;
     fractals[i].transitionFrames = 48 * 2 * 4;
     
     i++;
     
     fractals[i].offsetR = -0.400705;
     fractals[i].offsetI = -0.596176;
     fractals[i].zoom = 0.003860;
     fractals[i].maxIterMult = 40.5;
     fractals[i].escapeThresholdMult = 1;
     fractals[i].invertColorMap = true;
     fractals[i].colormapShift = 0.5;
     fractals[i].contrastPower = 1.203526;
     fractals[i].pauseFrames = 24;
     fractals[i].transitionFrames = 48 * 8;
     
     i++;
     
     fractals[i].offsetR = -0.400705;
     fractals[i].offsetI = -0.596176;
     fractals[i].zoom = 0.003860;
     fractals[i].maxIterMult = 40.5;
     fractals[i].escapeThresholdMult = 1;
     fractals[i].invertColorMap = false;
     fractals[i].colormapShift = 0.5;
     fractals[i].contrastPower = 1.203526;
     fractals[i].pauseFrames = 12 * 4;
     fractals[i].transitionFrames = 48 * 40;
     
     i++;
     
     fractals[i].offsetR = -0.735381;
     fractals[i].offsetI = -0.094162;
     fractals[i].zoom = 3.346763;
     fractals[i].maxIterMult = 1.55;
     fractals[i].escapeThresholdMult = 1.149416;
     fractals[i].invertColorMap = false;
     fractals[i].colormapShift = 0.5;
     fractals[i].contrastPower = 1.700320;
     fractals[i].pauseFrames = 1000000000;
     fractals[i].transitionFrames = 24 * 6 * 4;
     */
    
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 2.597190;
    fractals[i].maxIterMult = 1.199969;
    fractals[i].escapeThresholdMult = 0.1;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96;
    fractals[i].pauseFrames = 96;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    i++;
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 0.75;
    fractals[i].maxIterMult = 1.199969;
    fractals[i].escapeThresholdMult = 0.145516;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96*2;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    i++;
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 0.351723;
    fractals[i].maxIterMult = 0.95;
    fractals[i].escapeThresholdMult = 0.5;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    i++;
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 0.267090;
    fractals[i].maxIterMult = 0.886907;
    fractals[i].escapeThresholdMult = 5;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96 * 2;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    i++;
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 0.267090;
    fractals[i].maxIterMult = 0.886907;
    fractals[i].escapeThresholdMult = 100;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96 * 3;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    i++;
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 1.5;
    fractals[i].maxIterMult = 5.502456;
    fractals[i].escapeThresholdMult = 603.881763;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96 * 8;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    i++;
    
    fractals[i].offsetR = 0;
    fractals[i].offsetI = 0;
    fractals[i].zoom = 3;
    fractals[i].maxIterMult = 13.2290863;
    fractals[i].escapeThresholdMult = 1.0000;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 96;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = -0.064410;
    fractals[i].cI = 0.67000;
    
    i++;
    
    fractals[i].offsetR = -0.128274;
    fractals[i].offsetI = -0.202694;
    fractals[i].zoom = 0.3;
    fractals[i].maxIterMult = 13.2290863;
    fractals[i].escapeThresholdMult = 1.0000;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 48;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = -0.064410;
    fractals[i].cI = 0.67000;
    
    i++;
    
    fractals[i].offsetR = -0.128274;
    fractals[i].offsetI = -0.202694;
    fractals[i].zoom = 0.112567;
    fractals[i].maxIterMult = 132.290863;
    fractals[i].escapeThresholdMult = 1.0000;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 48 * 5;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = -0.064410;
    fractals[i].cI = 0.67000;
    
    i++;
    
    fractals[i].offsetR = -0.129682;
    fractals[i].offsetI = -0.202731;
    fractals[i].zoom = 0.009718;
    fractals[i].maxIterMult = 132.290863;
    fractals[i].escapeThresholdMult = 1.0000;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 48 * 10;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = -0.064535;
    fractals[i].cI = 0.67000;
    
    i++;
    
    fractals[i].offsetR = -0.129682;
    fractals[i].offsetI = -0.202731;
    fractals[i].zoom = 0.009718;
    fractals[i].maxIterMult = 55.67818;
    fractals[i].escapeThresholdMult = 1.041853;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 48 * 10;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = -0.064778;
    fractals[i].cI = 0.669989;
    
    i++;
    
    fractals[i].offsetR = -0.129682;
    fractals[i].offsetI = -0.202731;
    fractals[i].zoom = 0.2;
    fractals[i].maxIterMult = 55.67818;
    fractals[i].escapeThresholdMult = 1.041853;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 48 * 10;
    fractals[i].pauseFrames = 0;
    fractals[i].cR = -0.064778;
    fractals[i].cI = 0.669989;
    
    i++;
    
    fractals[i].offsetR = 0;
    fractals[i].offsetI = 0;
    fractals[i].zoom = 3;
    fractals[i].maxIterMult = 55.67818;
    fractals[i].escapeThresholdMult = 1.041853;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.203526;
    fractals[i].transitionFrames = 48 * 15;
    fractals[i].pauseFrames = 96;
    fractals[i].cR = -0.064778;
    fractals[i].cI = 0.669989;
    
    i++;
    
    fractals[i].offsetR = 0.0;
    fractals[i].offsetI = 0.0;
    fractals[i].zoom = 2.597190;
    fractals[i].maxIterMult = 1.199969;
    fractals[i].escapeThresholdMult = 0.1;
    fractals[i].invertColorMap = true;
    fractals[i].colormapShift = 0.500;
    fractals[i].contrastPower = 1.003656;
    fractals[i].transitionFrames = 96 * 3;
    fractals[i].pauseFrames = 96 * 2;
    fractals[i].cR = (-0.4) + 0.190511;
    fractals[i].cI = (-0.59) + 1.267301;
    
    NSLog(@"Number of fractals: %d", i + 1);
    
    totalFrames = 0;
    
    for (int n = 0; n <= i; n++)
    {
        totalFrames += fractals[n].transitionFrames + fractals[n].pauseFrames;
    }
    
    totalFrames -= fractals[i].transitionFrames;
    
    NSLog(@"Total number of frames: %d", totalFrames);
    
    NSLog(@"Total time: %d:%0.2d", totalFrames/24 / 60, totalFrames/24 / 60 % 60);


    doAnimation = false;
     

    offsetX = -(-0.325544);
    offsetY = -(-0.084141);
    zoom = 31.701315;
    maxIterMult = 1.110314;
    escapeThresholdMult = 200000;
    invertColormap = false;
    colormapShift = 0.245000;
    contrastPower = 1.00000;
    cR = -0.064535;
    cI = 0.670000;
    
    frameNum = 0;
    
    cMove = 0.0001;
    
    _keysPressed = [NSMutableSet new];
    
    functionWeight = 1;
    
    return self;
}

-(id<MTLTexture>) doCompute
{
//    functionWeight += 0.001;
    
    if([_keysPressed containsObject:@(kVK_ANSI_W)])
    {
        offsetY -= 0.025 * zoom;
    }
    if ([_keysPressed containsObject:@(kVK_ANSI_S)])
    {
        offsetY += 0.025 * zoom;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_A)])
    {
        offsetX -= 0.025 * zoom;
    }
    if ([_keysPressed containsObject:@(kVK_ANSI_D)])
    {
        offsetX += 0.025 * zoom;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_Q)])
    {
        zoom *= 1.05;
    }
    if ([_keysPressed containsObject:@(kVK_ANSI_E)])
    {
        zoom *= 0.95;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_Equal)])
    {
        maxIterMult *= 1.01;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_Minus)])
    {
        maxIterMult *= 0.99;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_RightBracket)])
    {
        escapeThresholdMult *= 1.01;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_LeftBracket)])
    {
        escapeThresholdMult *= 0.99;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_J)])
    {
        colormapShift -= 0.005;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_L)])
    {
        colormapShift += 0.005;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_P)])
    {
        contrastPower *= 1.01;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_O)])
    {
        contrastPower *= 0.99;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_R)])
    {
        functionWeight = 0;
    }
    if([_keysPressed containsObject:@(kVK_UpArrow)])
    {
        cR += cMove;
    }
    if([_keysPressed containsObject:@(kVK_DownArrow)])
    {
        cR -= cMove;
    }
    if([_keysPressed containsObject:@(kVK_RightArrow)])
    {
        cI += cMove;
    }
    if([_keysPressed containsObject:@(kVK_LeftArrow)])
    {
        cI -= cMove;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_Z)])
    {
        functionWeight -= 0.01;
    }
    if([_keysPressed containsObject:@(kVK_ANSI_X)])
    {
        functionWeight += 0.01;
    }
    ifKey(kVK_ANSI_Period)
    {
        cMove *= 1.1;
    }
    ifKey(kVK_ANSI_Comma)
    {
        cMove *= 0.9;
    }

    
    functionWeight = MAX(0, MIN(functionWeight, 1));
    
    /*

     */
    
//    NSLog(@"%d frames for index %d", currentFractalFrameNum, currentFractalIndex);

    
    _commandBuffer = [_commandQueue commandBuffer];
    
    _encoder = [_commandBuffer computeCommandEncoder];
    
    [_encoder setTexture:_texture atIndex:0];
    
    if(doAnimation)
    {
        
        float weight = currentFractalFrameNum > fractals[currentFractalIndex].pauseFrames ? (float)(currentFractalFrameNum - fractals[currentFractalIndex].pauseFrames) / fractals[currentFractalIndex].transitionFrames : 0;
        
        /*
        if(currentFractalIndex == 10)
            weight = easeInOutBack(weight);
        if(currentFractalIndex == 0)
        {
            weight = weight;
        }
        else if(currentFractalIndex == 1)
        {
            weight = easeInSine(weight);
        }
        else if(currentFractalIndex == 2)
        {
//            weight = easeOutSine(weight);
        }
         */
        
        float weightPower;
        
        if(currentFractalIndex == 0)
            weightPower = cos(weight * M_PI_2);
        else
            weightPower = 2;
        
        weightPower = 1;

        
        float functionWeight = 1 - weight;
        
//        NSLog(@"Weight: %f", weight);
        
        simd_float2 offset = simd_make_float2(fractals[currentFractalIndex].offsetR * (1 - pow(weight, weightPower)) + fractals[currentFractalIndex + 1].offsetR * pow(weight, weightPower),
                                              fractals[currentFractalIndex].offsetI * (1 - pow(weight, weightPower)) + fractals[currentFractalIndex + 1].offsetI * pow(weight, weightPower));
        
        uint maxIterations = 50 * (fractals[currentFractalIndex].maxIterMult * (1 - weight) + fractals[currentFractalIndex + 1].maxIterMult * weight);
        float escapeThreshold = 6.0 * (fractals[currentFractalIndex].escapeThresholdMult * (1 - weight) + fractals[currentFractalIndex + 1].escapeThresholdMult * weight);
        
//        colormapShift = MIN(MAX(-0.5, fractals[currentFractalIndex].colormapShift * (1 - weight) + fractals[currentFractalIndex + 1].colormapShift * weight), 0.5);
        
        float zoom = fractals[currentFractalIndex].zoom * (1 - pow(weight, weightPower)) + fractals[currentFractalIndex + 1].zoom * pow(weight, weightPower);
        float contrastPower = fractals[currentFractalIndex].contrastPower * (1 - weight) + fractals[currentFractalIndex + 1].contrastPower * weight;
        
        float cR = fractals[currentFractalIndex].cR * (1 - weight) + fractals[currentFractalIndex + 1].cR * weight;
        float cI = fractals[currentFractalIndex].cI * (1 - weight) + fractals[currentFractalIndex + 1].cI * weight;
        
        /*
        NSLog(@"--- Fractal Index %d ---", currentFractalIndex);
        NSLog(@"Position: %f + %fi", cR, cI);
        NSLog(@"escapeThreshold: %f", escapeThreshold);
        NSLog(@"maxIterations: %u", maxIterations);
        NSLog(@"Offset: %f, %f", offsetX, offsetY);
        NSLog(@"Zoom: %f", zoom);
        NSLog(@"Contrast power: %f", contrastPower);
        NSLog(@"Colormap shift: %f", colormapShift);
        NSLog(@"Inverted ? %@", invertColormap ? @"YES" : @"NO");
         */
        
        [_encoder setBytes:&offset length:sizeof(offset) atIndex:0];
        [_encoder setBytes:&zoom length:sizeof(zoom) atIndex:1];
        [_encoder setBytes:&maxIterations length:sizeof(maxIterations) atIndex:2];
        [_encoder setBytes:&escapeThreshold length:sizeof(escapeThreshold) atIndex:3];
        [_encoder setBytes:&fractals[currentFractalIndex].invertColorMap length:sizeof(fractals[currentFractalIndex].invertColorMap) atIndex:4];
        [_encoder setBytes:&colormapShift length:sizeof(colormapShift) atIndex:5];
        [_encoder setBytes:&contrastPower length:sizeof(contrastPower ) atIndex:6];
        [_encoder setBytes:&functionWeight length:sizeof(functionWeight) atIndex:7];
        [_encoder setBytes:&cR length:sizeof(cR) atIndex:8];
        [_encoder setBytes:&cI length:sizeof(cI) atIndex:9];
        [_encoder setBytes:&currentFractalIndex length:sizeof(currentFractalIndex) atIndex:10];
        
        
        currentFractalFrameNum += 1;

        if(currentFractalFrameNum > fractals[currentFractalIndex].transitionFrames + fractals[currentFractalIndex].pauseFrames)
        {
            currentFractalIndex += 1;
            currentFractalFrameNum = 0;
        }
        
        if(currentFractalIndex == 13 && currentFractalFrameNum >= fractals[currentFractalIndex].pauseFrames)
        {
            NSLog(@"Finished!");
            exit(0);
        }
        
        NSLog(@"Saving frame %d / %d. (%0.2f%% Finished)", frameNum, totalFrames, (float)frameNum / totalFrames * 100);
        [self saveTextureToImage];
        frameNum++;
    }
    else
    {
        simd_float2 offset = simd_make_float2(offsetX, offsetY);
        
        uint maxIterations = (50 + pow(50 * pow(MAX(0, 1-1), 1.5), 1.5)) * maxIterMult;
        float escapeThreshold = 6.0 * escapeThresholdMult;
        
        colormapShift = MIN(MAX(-0.5, colormapShift), 0.5);
        
        [_encoder setBytes:&offset length:sizeof(offset) atIndex:0];
        [_encoder setBytes:&zoom length:sizeof(zoom) atIndex:1];
        [_encoder setBytes:&maxIterations length:sizeof(maxIterations) atIndex:2];
        [_encoder setBytes:&escapeThreshold length:sizeof(escapeThreshold) atIndex:3];
        [_encoder setBytes:&invertColormap length:sizeof(invertColormap) atIndex:4];
        [_encoder setBytes:&colormapShift length:sizeof(colormapShift) atIndex:5];
        [_encoder setBytes:&contrastPower length:sizeof(contrastPower) atIndex:6];
        [_encoder setBytes:&functionWeight length:sizeof(functionWeight) atIndex:7];
        [_encoder setBytes:&cR length:sizeof(cR) atIndex:8];
        [_encoder setBytes:&cI length:sizeof(cI) atIndex:9];
        [_encoder setBytes:&currentFractalIndex length:sizeof(currentFractalIndex) atIndex:10];
        
        NSLog(@"Position: %f + %fi", cR, cI);
        NSLog(@"escapeThresholdMult: %f", escapeThresholdMult);
        NSLog(@"maxIterMult: %f", maxIterMult);
        NSLog(@"Offset: %f, %f", offsetX, offsetY);
        NSLog(@"Zoom: %f", zoom);
        NSLog(@"Contrast power: %f", contrastPower);
        NSLog(@"Colormap shift: %f", colormapShift);
        NSLog(@"Inverted ? %@", invertColormap ? @"YES" : @"NO");
        }

    
    MTLSize gridSize = MTLSizeMake(_texture.width, _texture.height, 1);
    
    MTLSize threadGroupSize = MTLSizeMake(32, 32, 1);
    
    [_encoder setComputePipelineState:_pipelineState];
    
    if(_deviceSupportsNonuniformThreadgroups)
    {
        [_encoder dispatchThreads:gridSize threadsPerThreadgroup:threadGroupSize];
    }
    else
    {
     
        MTLSize threadGroupCount = MTLSizeMake((gridSize.width + threadGroupSize.width - 1) / threadGroupSize.width,
                                               (gridSize.height + threadGroupSize.height - 1) / threadGroupSize.height, 1);
        [_encoder dispatchThreads:threadGroupCount threadsPerThreadgroup:threadGroupSize];
    }

    [_encoder endEncoding];
    [_commandBuffer commit];
    
    return _texture;
}

-(void) saveTextureToImage
{
    @autoreleasepool {
        CIContext *context = [CIContext contextWithMTLDevice:_device];
        CIImage *ciImage = [[CIImage alloc] initWithMTLTexture:_texture options:@{
            kCIImageColorSpace: (id)_view.colorspace
        }];
        CGAffineTransform transform = CGAffineTransformMake(1, 0, 0, -1, 0, ciImage.extent.size.height);
        ciImage = [ciImage imageByApplyingTransform:transform];
        CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
        
        NSURL* path = [NSURL URLWithString:[@"file://" stringByAppendingString: [[NSString stringWithFormat:@"~/Desktop/HUA/Fractals/output%05d.PNG", frameNum ] stringByExpandingTildeInPath]]];
        
        
        CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)path , (CFStringRef)UTTypePNG.identifier, 1, nil);
        CGImageDestinationAddImage(dest, cgImage, nil);
        CGImageDestinationFinalize(dest);
        
//        CGRelease
        CGImageRelease(cgImage);
        CFRelease(dest);
        
//        CGRelease(dest);
        
//        NSLog(@"Saved image to %@", path);
    }
}

-(void) saveTextureToImage:(int)scaleFactor
{
    CGSize initialSize = CGSizeMake(_texture.width, _texture.height);
    _texture = [self textureWithDimensions:_texture.width * scaleFactor height:_texture.height * scaleFactor];
    [self doCompute];
    
    [self saveTextureToImage];
    
    _texture = [self textureWithDimensions:initialSize.width height:initialSize.height];
}

-(void) keyDown:(NSEvent *)event
{
    [_keysPressed addObject:@(event.keyCode)];
}

-(void) keyUp:(NSEvent *)event
{
    [_keysPressed removeObject:@(event.keyCode)];
    
    if(event.keyCode == kVK_Space)
    {
        CGSize initialSize = CGSizeMake(_texture.width, _texture.height);
        _texture = [self textureWithDimensions:_texture.width * 4 height:_texture.height * 4];
        [self doCompute];
        
        [self saveTextureToImage];
        
        _texture = [self textureWithDimensions:initialSize.width height:initialSize.height];
    }
    else if(event.keyCode == kVK_ANSI_I)
    {
        invertColormap = !invertColormap;
    }
    else if (event.keyCode == kVK_ANSI_K)
    {
        colormapShift = 0;
        contrastPower = 1;
    }
    else if (event.keyCode == kVK_ANSI_0)
    {
        offsetX = 0;
        offsetY = 0;
        zoom = 1;
    }
}

-(void) updateSize:(NSSize)size
{
    _texture = [self textureWithDimensions:size.width height:size.height];
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    

}


@end
