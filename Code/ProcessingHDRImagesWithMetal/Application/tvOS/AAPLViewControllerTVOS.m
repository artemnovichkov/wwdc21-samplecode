/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the tvOS view controller.
*/

#import <MetalKit/MetalKit.h>
#import "AAPLViewControllerTVOS.h"
#import "AAPLRenderer.h"
#import "UIOptionEnums.h"
#import "UIDefaults.h"

@implementation AAPLViewControllerTVOS
{
    MTKView * _view;
    AAPLRenderer* _renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView*)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

    NSAssert(_view.device, @"Metal is not supported on this device");

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view cameraStepCount:kDefaultCameraStepCount resolutionEquivalent:kDefaultResolutionEquivalent];

    NSAssert(_renderer, @"Renderer failed initialization");

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;

    _renderer.bloomIntensity = kDefaultBloomIntensity;
    _renderer.bloomThreshold = kDefaultBloomThreshold;
    _renderer.bloomRange = kDefaultBloomRange;

    _renderer.exposureType = kDefaultExposureControlType;
    _renderer.manualExposureValue = kDefaultManualExposure;
    _renderer.exposureKeyIndex = kDefaultExposureKeyIndex;

    _renderer.tonemapType = kDefaultTonemapOperatorType;
    _renderer.tonemapWhitepoint = kDefaultTonemapWhitePoint;

    _renderer.isCameraAnimating = kDefaultIsCameraAnimationEnabled;
    _renderer.cameraAnimationFrameIndex = kDefaultCameraFrameIndex;
    _renderer.frameIndexBlock = ^(NSUInteger index) { return; };
}

@end
