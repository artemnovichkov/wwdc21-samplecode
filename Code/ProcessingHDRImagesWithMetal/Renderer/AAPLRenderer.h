/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the renderer class that performs Metal setup and per-frame rendering.
*/

@import MetalKit;

enum TonemepOperatorType;
enum ExposureControlType;

// Platform independent renderer class
@interface AAPLRenderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView cameraStepCount:(NSUInteger)cameraSteps resolutionScale:(float)resolutionScale;

// Expose the following properties for UI:

// Bloom
@property float bloomIntensity;
@property float bloomThreshold;
@property float bloomRange;

// Exposure
@property enum ExposureControlType exposureType;
@property float manualExposureValue;
@property NSUInteger exposureKeyIndex;

// Tonemapping
@property enum TonemapOperatorType tonemapType;
@property (nonatomic) float tonemapWhitepoint;
@property (nonatomic) float tonemapEDRScalingWeight;

// Camera
@property (readonly) NSUInteger cameraAnimationStepCount;
@property BOOL isCameraAnimating;
@property NSUInteger cameraAnimationFrameIndex;
@property void (^ _Nonnull frameIndexBlock)(NSUInteger index);

// Resolution scale limited to range [minimumResolutionScale, maximumResolutionScale]
@property (nonatomic) float resolutionScale;
@property (readonly) float minimumResolutionScale;
@property (readonly) float maximumResolutionScale;

// Extended Dynamic Range (EDR) (values ignored unless macOS)
@property CGFloat maximumEDRValue;
@property CGFloat maximumEDRPotentialValue;
@property CGFloat maximumEDRReferenceValue;

@property (getter=isPostProcessingEnabled) BOOL postProcessingEnabled;


// Other Helpers:

#ifdef TARGET_MACOS
// Handle change of device and/or display.
- (void)updateWithDevice:(_Nonnull id<MTLDevice>)device andView:(MTKView * _Nonnull)view;
#endif

- (void)updateWithSize:(CGSize)size;

// Renderer will provide average GPU time over the last 5 frames
@property void (^ _Nonnull averageGPUTimeBlock)(CFTimeInterval averageGPUTime);

@end
