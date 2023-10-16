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


#define TEXTURE_SIZE_MULT 1

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
    
    zoom = 1;
    offsetX = 0;
    offsetY = 0;
    maxIterMult = 1;
    escapeThresholdMult = 1;
    invertColormap = false;
    colormapShift = 0;
    contrastPower = 1;
    
    _keysPressed = [NSMutableSet new];
    
    return self;
}

-(id<MTLTexture>) doCompute
{
    
    if([_keysPressed containsObject:@(kVK_ANSI_W)])
    {
        offsetY -= 0.05 * zoom;
    }
    if ([_keysPressed containsObject:@(kVK_ANSI_S)])
    {
        offsetY += 0.05 * zoom;
    }
    
    if([_keysPressed containsObject:@(kVK_ANSI_A)])
    {
        offsetX -= 0.05 * zoom;
    }
    if ([_keysPressed containsObject:@(kVK_ANSI_D)])
    {
        offsetX += 0.05 * zoom;
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
    
    _commandBuffer = [_commandQueue commandBuffer];
    
    _encoder = [_commandBuffer computeCommandEncoder];
    
    [_encoder setTexture:_texture atIndex:0];
    
    simd_float2 offset = simd_make_float2(offsetX, offsetY);
    
    uint maxIterations = (50 + pow(50 * pow(MAX(0, 1-zoom), 1.5), 1.5)) * maxIterMult;
    float escapeThreshold = 6.0 * escapeThresholdMult;
    
    colormapShift = MIN(MAX(-0.5, colormapShift), 0.5);
    
    [_encoder setBytes:&offset length:sizeof(offset) atIndex:0];
    [_encoder setBytes:&zoom length:sizeof(zoom) atIndex:1];
    [_encoder setBytes:&maxIterations length:sizeof(maxIterations) atIndex:2];
    [_encoder setBytes:&escapeThreshold length:sizeof(escapeThreshold) atIndex:3];
    [_encoder setBytes:&invertColormap length:sizeof(invertColormap) atIndex:4];
    [_encoder setBytes:&colormapShift length:sizeof(colormapShift) atIndex:5];
    [_encoder setBytes:&contrastPower length:sizeof(contrastPower) atIndex:6];

    
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
    CIContext *context = [CIContext contextWithMTLDevice:_device];
    CIImage *ciImage = [[CIImage alloc] initWithMTLTexture:_texture options:@{
        kCIImageColorSpace: (id)_view.colorspace
    }];
    CGAffineTransform transform = CGAffineTransformMake(1, 0, 0, -1, 0, ciImage.extent.size.height);
    ciImage = [ciImage imageByApplyingTransform:transform];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    
    NSURL* path = [NSURL URLWithString:[@"file://" stringByAppendingString: [@"~/Desktop/fractalOutput.PNG" stringByExpandingTildeInPath]]];
    
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)path , (CFStringRef)UTTypePNG.identifier, 1, nil);
    CGImageDestinationAddImage(dest, cgImage, nil);
    CGImageDestinationFinalize(dest);
    NSLog(@"Saved image to %@", path);
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
