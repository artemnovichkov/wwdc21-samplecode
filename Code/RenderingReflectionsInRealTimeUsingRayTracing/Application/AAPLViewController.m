/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of view controller.
*/

#import "AAPLViewController.h"

#import <CoreImage/CoreImage.h>

@implementation AAPLViewController
{
    MTKView *_view;

    AAPLRenderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self _configureBackdrop:_configBackdrop];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();
    _view.preferredFramesPerSecond = 30;

    NSAssert(_view.device, @"Metal is not supported on this device");

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];

    NSAssert(_renderer, @"Renderer failed initialization");

    if(!_view.device.supportsRaytracing)
    {
        NSLog(@"No support for raytracing.  Falling back to full rasterization mode.");
        _renderModeControl.intValue = (NSUInteger)RMNoRaytracing;
        _renderModeControl.enabled = NO;
    }

    [_renderer mtkView:_view drawableSizeWillChange:[_view convertSizeToBacking:_view.bounds.size]];

    _view.delegate = _renderer;

}

- (IBAction)onRenderModeSegmentedControlAction:(id)sender
{
    if ( sender == _renderModeControl )
    {
        _renderer.renderMode = (RenderMode)_renderModeControl.indexOfSelectedItem;
    }
}

- (IBAction)onSpeedSliderAction:(id)sender
{
    if ( sender == _speedSlider )
    {
        float newValue = _speedSlider.floatValue;
        [_renderer setCameraPanSpeedFactor:newValue];
    }
}

- (void)_configureBackdrop:(NSView *)view
{
    view.wantsLayer = YES;
    view.layer.borderWidth = 1.0f;
    view.layer.cornerRadius = 8.0f;
}

@end
