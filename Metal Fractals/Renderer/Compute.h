//
//  Compute.h
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

struct Fractal
{
    float offsetR;
    float offsetI;
    float zoom;
    float maxIterMult;
    float escapeThresholdMult;
    bool invertColorMap;
    float colormapShift;
    float contrastPower;
    
    float cR;
    float cI;
    
    unsigned int pauseFrames;
    unsigned int transitionFrames;
};

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
