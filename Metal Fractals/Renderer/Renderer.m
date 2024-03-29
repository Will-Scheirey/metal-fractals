//
//  Renderer.m
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#import "Renderer.h"
#import "ShaderDefinitions.h"
#import <MetalKit/MetalKit.h>

@implementation Renderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _commandBuffer;
    id<MTLRenderCommandEncoder> _encoder;
    id<MTLBuffer> _vertexBuffer;
    
    vector_uint2 _viewportSize;
}
  
-(id<MTLRenderPipelineState>) buildRenderPipelineWithDevice:(id<MTLDevice>)device withView:(MTKView*)view
{
    MTLRenderPipelineDescriptor* pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    id<MTLLibrary> library = [device newDefaultLibrary];
    
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertexShader"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;

    NSError* err;
    id<MTLRenderPipelineState>rpswd = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&err];
    if(err.code != 0)
    {
        NSLog(@"Error: %@", err);
    }
    return rpswd;
}

-(void) makeVertexBufferWithSize:(CGSize)size {
    //size.width = MAX(size.width, size.height);
    //size.height = size.width;
    
    const Vertex quadVertices[] =
    {
        // Pixel positions, Texture coordinates
        { {  size.width * 2,  -size.height * 2 },  { 1.f, 1.f } },
        { { -size.width * 2,  -size.height * 2 },  { 0.f, 1.f } },
        { { -size.width * 2,   size.height * 2 },  { 0.f, 0.f } },

        { {  size.width * 2,  -size.height * 2 },  { 1.f, 1.f } },
        { { -size.width * 2,   size.height * 2 },  { 0.f, 0.f } },
        { {  size.width * 2,   size.height * 2 },  { 1.f, 0.f } },
    };
    
    _vertexBuffer = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:0];
}

- (nonnull id)initWitMTK:(nonnull MTKView *)view size:(CGSize)size {
    self = [super init];
    
    _device = view.device;
    _commandQueue = [_device newCommandQueue];
    _commandBuffer = [_commandQueue commandBuffer];
    
    [self makeVertexBufferWithSize:size];
    
    self.pipelineState = [self buildRenderPipelineWithDevice:_device withView:view];
    
    self.computer = [[Compute alloc] initWitMTK:view size:size];
    
    return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view { 
    _commandBuffer = [_commandQueue commandBuffer];
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    
//    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    
    _encoder = [_commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    
    
    [_encoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0, 2.0 }];
    
    [_encoder setCullMode:MTLCullModeNone];

    
    [_encoder setRenderPipelineState:_pipelineState];
    
    [_encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [_encoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:1];
    
    [_encoder setFragmentTexture:[_computer doCompute] atIndex:0];

    [_encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    [_encoder endEncoding];
    [_commandBuffer presentDrawable:view.currentDrawable];
    [_commandBuffer commit];

}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    [self makeVertexBufferWithSize:size];
    [_computer updateSize:size];
}


@end
