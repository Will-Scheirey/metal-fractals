//
//  Compute.h
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Compute : NSObject

@property (retain) id<MTLComputePipelineState> pipelineState;
@property (assign) BOOL deviceSupportsNonuniformThreadgroups;

-(id)initWitMTK:(MTKView *)view size:(CGSize)size;
-(id<MTLTexture>) doCompute;
-(void) updateSize:(NSSize)size;

-(void) keyDown:(NSEvent *)event;
-(void) keyUp:(NSEvent *)event;


@end

NS_ASSUME_NONNULL_END
