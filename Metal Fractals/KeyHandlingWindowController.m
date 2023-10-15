//
//  KeyHandlingWindowController.m
//  shaders
//
//  Created by William Scheirey on 10/10/23.
//

#import "KeyHandlingWindowController.h"
#import "Renderer/Compute.h"

extern Compute* computer;

@interface KeyHandlingWindowController ()

@end

@implementation KeyHandlingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void) keyDown:(NSEvent *)event
{
    [computer keyDown:event];
}

-(void) keyUp:(NSEvent *)event
{
    [computer keyUp:event];
}

@end
