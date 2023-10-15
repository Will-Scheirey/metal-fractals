//
//  ViewController.m
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#import "ViewController.h"
#import "Renderer/Renderer.h"
#import <MetalKit/MetalKit.h>

@implementation ViewController {
    MTKView *_view;

    Renderer* _renderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [self.view setFrameSize:NSMakeSize(800, 800)];

    _view = (MTKView *)self.view;
    
    _view.device = MTLCreateSystemDefaultDevice();
    _view.preferredFramesPerSecond = 60;
    
    CGSize size = _view.bounds.size;
    
    _renderer = [[Renderer alloc] initWitMTK:_view size:size];
    
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    
    _view.delegate = _renderer;
}

-(void)keyDown:(NSEvent *)event
{
    NSLog(@"Down");
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
