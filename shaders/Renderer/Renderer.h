//
//  Renderer.h
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#import <MetalKit/MetalKit.h>
#import "Compute.h"

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject <MTKViewDelegate> 

@property (retain) id<MTLRenderPipelineState> pipelineState;
@property (retain) Compute* computer;

-(id)initWitMTK:(MTKView *)view size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
