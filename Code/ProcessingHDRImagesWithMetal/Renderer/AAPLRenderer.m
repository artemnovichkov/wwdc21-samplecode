/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

#import "AAPLRenderer.h"
#import "AAPLMathUtilities.h"
#import "AAPLUtility.hpp"
#import "AAPLShaderTypes.h"
#import "UIOptionEnums.h"

#import "UIDefaults.h"

#define VEC3(x, y, z) vector_float3_make(x, y, z)
#define VEC4(x, y, z, w) vector_float4_make(x, y, z, w)

// The max number of uniform buffers in flight
static const NSUInteger kMaxBuffersInFlight = 3;

// Update to set desired frame rate (generally 30 or 60, in frames per second)
static const float kDesiredFrameRate = 60.f;

// The app's animation path is fixed, but these values ensure the number of steps in the path is reasonable.
static const NSUInteger kCameraAnimationMinStepCount = 100ul;
static const NSUInteger kCameraAnimationMaxStepCount = 10000ul;

// GPU time reported will be the average of the last n frames, controlled by this constant.
static const NSUInteger kGPUDurationHistorySize = 5ul;

// Supported resolution scale range. No super small resolutions or super sampling supported.
static const float kMinimumResolutionScale = .1f;
static const float kMaximumResolutionScale = 1.f;

// Target for luminance calculation is fixed at 1/8 the number of pixels of native resolution.
static const float kLogLuminanceTargetScale = .25f;

// ----------------
// MARK: Bloom Data

/*
 While bloom isn't a complicated algorithm, it has the potential to require a good amount of book keeping.

 This particular implementation downsamples 3 times on iOS/tvOS and 4 times on macOS before upsampling.
 */

// For separable gaussian passes
typedef enum _BlurDirection
{
    kBlurDirectionX = 0ul,
    kBlurDirectionY,
    kBlurDirectionCount
} BlurDirection;
static const NSString * kDirectionStrings[] = {@"Horizontal", @"Vertical"};

typedef struct _BloomPass
{
    float srcTexelScale;
    BlurDirection direction;
    uint32_t srcBloomTextureIdx;
    uint32_t dstBloomTextureIdx;
} BloomPass;


static const float kBloomCoefficient0 = 1.f/2.f;
static const float kBloomCoefficient1 = 1.f/4.f;
static const float kBloomCoefficient2 = 1.f/8.f;

#if defined(TARGET_IOS) || defined (TARGET_TVOS)

static const float kBloomTargetScales[] = {kBloomCoefficient0, kBloomCoefficient1, kBloomCoefficient2};
// Excludes bloom setup/init and bloom composite passes
static const BloomPass kBloomPasses[] =
{
    {1.f/kBloomCoefficient0, kBlurDirectionY, 0ul, 1ul},

    {1.f/kBloomCoefficient0, kBlurDirectionX, 1ul, 2ul},
    {1.f/kBloomCoefficient1, kBlurDirectionY, 2ul, 3ul},

    {1.f/kBloomCoefficient1, kBlurDirectionX, 3ul, 4ul},
    {1.f/kBloomCoefficient2, kBlurDirectionY, 4ul, 5ul},

    {1.f/kBloomCoefficient2, kBlurDirectionX, 5ul, 4ul},
    {1.f/kBloomCoefficient1, kBlurDirectionY, 4ul, 3ul},

    {1.f/kBloomCoefficient1, kBlurDirectionX, 3ul, 2ul},
    {1.f/kBloomCoefficient0, kBlurDirectionY, 2ul, 1ul},
};
#else // TARGET_MACOS

static const float kBloomCoefficient3 = 1.f/16.f;
static const float kBloomTargetScales[] = {kBloomCoefficient0, kBloomCoefficient1, kBloomCoefficient2, kBloomCoefficient3};

// Excludes bloom setup/init and bloom composite passes
static const BloomPass kBloomPasses[] =
{
    {1.f/kBloomCoefficient0, kBlurDirectionY, 0ul, 1ul},

    {1.f/kBloomCoefficient0, kBlurDirectionX, 1ul, 2ul},
    {1.f/kBloomCoefficient1, kBlurDirectionY, 2ul, 3ul},

    {1.f/kBloomCoefficient1, kBlurDirectionX, 3ul, 4ul},
    {1.f/kBloomCoefficient2, kBlurDirectionY, 4ul, 5ul},

    {1.f/kBloomCoefficient2, kBlurDirectionX, 5ul, 6ul},
    {1.f/kBloomCoefficient3, kBlurDirectionY, 6ul, 7ul},

    {1.f/kBloomCoefficient3, kBlurDirectionX, 7ul, 6ul},
    {1.f/kBloomCoefficient2, kBlurDirectionY, 6ul, 5ul},

    {1.f/kBloomCoefficient2, kBlurDirectionX, 5ul, 4ul},
    {1.f/kBloomCoefficient1, kBlurDirectionY, 4ul, 3ul},

    {1.f/kBloomCoefficient1, kBlurDirectionX, 3ul, 2ul},
    {1.f/kBloomCoefficient0, kBlurDirectionY, 2ul, 1ul},
};
#endif // #if defined(TARGET_IOS) || defined (TARGET_TVOS)

static const uint32_t kBloomPassCount = sizeof(kBloomPasses) / sizeof(kBloomPasses[0]);
static const uint32_t kBloomTargetScaleCount = sizeof(kBloomTargetScales) / sizeof(kBloomTargetScales[0]);

// Because the blur implementation is using separable gaussian, we need kBlurDirectionCount targets per bloom pass.
static const uint32_t kBloomTargetCount = kBlurDirectionCount * kBloomTargetScaleCount;

#pragma mark -
#pragma mark Renderer Implementation

// --
@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    id<MTLTexture> _sceneLinearColorTexture;
    id<MTLTexture> _sceneDepthTexture;

    MTLPixelFormat _sceneColorPixelFormat;
    MTLPixelFormat _sceneDepthPixelFormat;
    MTLPixelFormat _drawableFormat;

    // Pipeline states
    id<MTLRenderPipelineState> _geometryPipeline;

    // Depth States
    id<MTLDepthStencilState> _depthStateLess;
    id<MTLDepthStencilState> _depthStateDisabled;

    // Uniform data for each frame in flight
    id<MTLBuffer> _dynamicUniformBuffers[kMaxBuffersInFlight];
    uint8_t _currentUniformIndex;

    //----------------
    // Projection bits
    float _nearPlane;
    float _farPlane;
    float _FOVy;
    float _aspect;
    matrix_float4x4 _projectionMatrix;

    // -------
    // Skydome
    id<MTLTexture> _skyDomeTexture;
    id<MTLRenderPipelineState> _skyDomePipeline;
    vector_float3 _skyDomeOffsets;

    //---------------------------
    // Geometry for a basic scene

    // Sphere
    id <MTLBuffer> _sphereVertexBuffer;
    uint32_t _numSphereVerts;

    //-------------
    // Post process
    vector_float2 _fullResolutionTexelOffset;

    //
    id<MTLRenderPipelineState> _bloomInitPipelineVariants[kExposureControlTypeCount];
    id<MTLRenderPipelineState> _bloomBlurPipelines[kBlurDirectionCount];

    id<MTLTexture> _bloomTargets[kBloomTargetCount];
    MTLPixelFormat _bloomPixelFormat;

    // --
    id<MTLRenderPipelineState> _compositePipelineVariants[kExposureControlTypeCount][kTonemapOperatorTypeCount];

    //
    id<MTLRenderPipelineState> _logLuminancePipeline;
    id<MTLTexture> _logLuminanceTexture;
    MTLPixelFormat _logLuminanceFormat;

    //
    NSUInteger _cameraStepCount;
    CGSize _currentViewSize;

    //
    vector_float4 _tonemapParameters;

    // Reporting average GPU time
    CFTimeInterval _sceneBloomPostDuration;
    CFTimeInterval _averageLuminanceDuration;
    CFTimeInterval _durationHistory[kGPUDurationHistorySize];
    NSUInteger _currentDurationHistoryIndex;

    BOOL _postProcessingEnabled;
}

#pragma mark -
#pragma mark Properties and Exposed Methods

/// Initialize with the MetalKit view with the Metal device used to render.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
                             cameraStepCount:(NSUInteger)cameraSteps
                             resolutionScale:(float)resolutionScale
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;
        _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
        _currentUniformIndex = 0u;

        // No real need to make this configurable in any way, so we'll just hack constants in here.
        _nearPlane = 1.f;
        _farPlane = 1000.f;
        _FOVy = radians_from_degrees(45.f);

#if defined(TARGET_IOS) || defined(TARGET_TVOS)

        _sceneColorPixelFormat = MTLPixelFormatRG11B10Float;
        _sceneDepthPixelFormat = MTLPixelFormatDepth16Unorm;
        _logLuminanceFormat = MTLPixelFormatR16Float;
        _bloomPixelFormat = MTLPixelFormatRG11B10Float;

        if ([_device supportsFamily:MTLGPUFamilyApple3])
        {
            _drawableFormat = MTLPixelFormatBGR10_XR;
        }
        else
        {
            _drawableFormat = MTLPixelFormatBGRA8Unorm;
        }

        // The iOS/tvOS targets of this sample do not support disabling post processing.
        _postProcessingEnabled = YES;

#elif defined(TARGET_MACOS)

        _sceneColorPixelFormat = MTLPixelFormatRGBA16Float;
        _sceneDepthPixelFormat = MTLPixelFormatDepth16Unorm;
        _logLuminanceFormat = MTLPixelFormatR16Float;
        _bloomPixelFormat = MTLPixelFormatRG11B10Float;

        _drawableFormat = MTLPixelFormatRGBA16Float;

#endif

        _maximumEDRValue = 1.0;
        _cameraStepCount = CLAMP(kCameraAnimationMinStepCount, kCameraAnimationMaxStepCount, cameraSteps);
        _resolutionScale = CLAMP(kMinimumResolutionScale, kMaximumResolutionScale, resolutionScale);

        [self loadMetal:mtkView];
        [self onSizeUpdated:mtkView.drawableSize];

        // Don't let the drawable resize, sample manage this manually.
#if defined(TARGET_IOS) || defined(TARGET_TVOS)
        mtkView.autoResizeDrawable = NO;
#endif

        _currentDurationHistoryIndex = 0ul;
        for ( uint32_t currHistIdx = 0ul; currHistIdx < kGPUDurationHistorySize; ++currHistIdx)
        {
            _durationHistory[currHistIdx] = 0.0;
        }

        _frameIndexBlock = ^(NSUInteger f) { return; };
        _averageGPUTimeBlock = ^(CFTimeInterval t) { return; };

    }

    return self;
}

// --
- (void)setTonemapWhitepoint:(float)tonemapWhitepoint
{
    _tonemapWhitepoint = tonemapWhitepoint;
}

// --
- (NSUInteger)cameraAnimationStepCount
{
    return _cameraStepCount;
}

// --
- (float)minimumResolutionScale
{
    return kMinimumResolutionScale;
}

// --
- (float)maximumResolutionScale
{
    return kMaximumResolutionScale;
}

// --
- (void)setResolutionScale:(float)resolutionScale
{
    _resolutionScale = CLAMP(kMinimumResolutionScale, kMaximumResolutionScale, resolutionScale);
    [self onSizeUpdated:_currentViewSize];
}

// --
#ifdef TARGET_MACOS
- (void)updateWithDevice:(id<MTLDevice>)device andView:(MTKView *)view
{
    _device = device;
    [self loadMetal:view];
    [self onSizeUpdated:view.bounds.size];
}
#endif

// --
- (void)updateWithSize:(CGSize)size
{
    [self onSizeUpdated:size];
}


#pragma mark -
#pragma mark Initialization

/// Create the Metal render state objects including shaders and render state pipeline objects.
- (void) loadMetal:(nonnull MTKView *)mtkView
{
    //------------------------
    // MARK: Configure MTKView

    // Depends on device and HDR-ness. Should at least do wide color if possible
    // Tonemapping will 'compress' linear scene values into this format.
    mtkView.colorPixelFormat = _drawableFormat;

    // More HDR/wide color considerations to be had here
    mtkView.sampleCount = 1;

    // Load environment map
    NSError *error;
    _skyDomeTexture = texture_from_radiance_file(@"kloppenheim_06_4k.hdr", _device, &error);

    if(!_skyDomeTexture)
    {
        NSLog(@"Error when creating environment map: %@", error);
    }

    //-----------------------------
    // MARK: Create Pipeline States

    // Load all the shader files with a .metal file extension in the project.
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    //---------------
    // MARK: -- Scene

    MTLRenderPipelineDescriptor* pipeDesc = [MTLRenderPipelineDescriptor new];

    pipeDesc.label = @"Geometry Pipeline";
    pipeDesc.sampleCount = mtkView.sampleCount;
    pipeDesc.vertexFunction = [defaultLibrary newFunctionWithName:@"GeometryVertex"];
    pipeDesc.fragmentFunction = [defaultLibrary newFunctionWithName:@"GeometryFragment"];
    pipeDesc.colorAttachments[0].pixelFormat = _sceneColorPixelFormat;
    pipeDesc.depthAttachmentPixelFormat = _sceneDepthPixelFormat;

    // The geometry pass is the only pass that actually requires a vertex descriptor, so we'll create that here:
    pipeDesc.vertexDescriptor = [MTLVertexDescriptor new];

    pipeDesc.vertexDescriptor.attributes[AAPLVertexAttributeIndexPosition].format = MTLVertexFormatFloat3;
    pipeDesc.vertexDescriptor.attributes[AAPLVertexAttributeIndexPosition].bufferIndex = 0;
    pipeDesc.vertexDescriptor.attributes[AAPLVertexAttributeIndexPosition].offset = offsetof(AAPLVertex, position);

    pipeDesc.vertexDescriptor.attributes[AAPLVertexAttributeIndexNormal].format = MTLVertexFormatFloat3;
    pipeDesc.vertexDescriptor.attributes[AAPLVertexAttributeIndexNormal].bufferIndex = 0;
    pipeDesc.vertexDescriptor.attributes[AAPLVertexAttributeIndexNormal].offset = offsetof(AAPLVertex, normal);
    pipeDesc.vertexDescriptor.layouts[0].stride = sizeof(AAPLVertex);
    pipeDesc.vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

    _geometryPipeline = [_device newRenderPipelineStateWithDescriptor:pipeDesc error:&error];
    NSAssert(_geometryPipeline, @"Error when creating geometry pipeline state: %@", error);

    // Rendering the sky dome

    pipeDesc = [MTLRenderPipelineDescriptor new];
    pipeDesc.label = @"Sky Dome Pipeline";
    pipeDesc.sampleCount = mtkView.sampleCount;
    pipeDesc.vertexFunction = [defaultLibrary newFunctionWithName:@"SkyDomeVertex"];
    pipeDesc.fragmentFunction = [defaultLibrary newFunctionWithName:@"SkyDomeFragment"];
    pipeDesc.colorAttachments[0].pixelFormat = _sceneColorPixelFormat;
    pipeDesc.depthAttachmentPixelFormat = _sceneDepthPixelFormat;

    _skyDomePipeline = [_device newRenderPipelineStateWithDescriptor:pipeDesc error:&error];
    NSAssert(_skyDomePipeline, @"Error when creating sky dome pipeline state: %@", error);

    //----------------------
    // MARK: -- Post Process

    // Will reuse this a few times
    id<MTLFunction> fsqVertexFunc = [defaultLibrary newFunctionWithName:@"FSQVertex"];

    // MARK: ---- Scene Exposure

    pipeDesc = [MTLRenderPipelineDescriptor new];
    pipeDesc.label = @"Log Luminance";
    pipeDesc.colorAttachments[0].pixelFormat = _logLuminanceFormat;
    pipeDesc.sampleCount = 1;
    pipeDesc.vertexFunction = fsqVertexFunc;
    pipeDesc.fragmentFunction = [defaultLibrary newFunctionWithName:@"LogLuminanceFragment"];

    _logLuminancePipeline = [_device newRenderPipelineStateWithDescriptor:pipeDesc error:&error];
    NSAssert(_logLuminancePipeline, @"Error when creating log luminance pipeline state: %@", error);

    // MARK: ---- Bloom

    id<MTLRenderPipelineState> (^genBloomPipelineState)(NSString *, NSString *, NSString *, id<MTLDevice>, MTLPixelFormat) = ^id<MTLRenderPipelineState>(NSString * label, NSString * vertexFuncName, NSString * fragmentFuncName, id<MTLDevice> dev, MTLPixelFormat pf)
    {
        MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineDescriptor.label = label;
        pipelineDescriptor.colorAttachments[0].pixelFormat = pf;
        pipelineDescriptor.sampleCount = 1;
        pipelineDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:vertexFuncName];;
        pipelineDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:fragmentFuncName];
        pipeDesc.vertexDescriptor = nil;

        NSError *error = nil;
        id<MTLRenderPipelineState> res = [dev newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        NSAssert(res, @"Error when creating render pipeline state: %@", error);

        return res;
    };

    _bloomBlurPipelines[kBlurDirectionX] = genBloomPipelineState(@"Bloom Blur X", @"BloomVertex", @"BloomBlurX", _device, _bloomPixelFormat);
    _bloomBlurPipelines[kBlurDirectionY] = genBloomPipelineState(@"Bloom Blur Y", @"BloomVertex", @"BloomBlurY", _device, _bloomPixelFormat);

    // Bloom Setup - variants for exposure
    for (uint32_t exposureControlTypeIdx = 0; exposureControlTypeIdx < kExposureControlTypeCount; ++exposureControlTypeIdx)
    {
        MTLFunctionConstantValues * constantValues = [MTLFunctionConstantValues new];
        uint32_t currValue = exposureControlTypeIdx;
        [constantValues setConstantValue:&currValue type:MTLDataTypeUInt atIndex:AAPLFunctionConstantIndexExposureType];

        MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineDescriptor.label = [@"Bloom Setup: " stringByAppendingString:string_for_exposure_control_type(exposureControlTypeIdx)];
        pipelineDescriptor.colorAttachments[0].pixelFormat = _bloomPixelFormat;
        pipelineDescriptor.sampleCount = 1;
        pipelineDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"BloomVertex"];

        id<MTLFunction> fragFunc = [defaultLibrary newFunctionWithName:@"BloomSetup" constantValues:constantValues error:&error];
        NSAssert(fragFunc, @"Error when creating BloomInit function variant: %@", error);

        pipelineDescriptor.fragmentFunction = fragFunc;

        // App doesn't send vertex data for these calls
        pipeDesc.vertexDescriptor = nil;

        id<MTLRenderPipelineState> bloomInitPipeline =  [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        NSAssert(bloomInitPipeline, @"Error when creating BloomSetup pipeline variant: %@", error);

        _bloomInitPipelineVariants[exposureControlTypeIdx] = bloomInitPipeline;
    }

    // MARK: ---- Post Process Composite

    // Generate variants for exposure modes and tonemap operators
    for (uint32_t exposureControlTypeIdx = 0; exposureControlTypeIdx < kExposureControlTypeCount; ++exposureControlTypeIdx)
    {
        for (uint32_t tonemapOperatorTypeIdx = 0; tonemapOperatorTypeIdx < kTonemapOperatorTypeCount; ++tonemapOperatorTypeIdx)
        {
            MTLFunctionConstantValues * constantValues = [MTLFunctionConstantValues new];
            [constantValues setConstantValue:&exposureControlTypeIdx type:MTLDataTypeUInt atIndex:AAPLFunctionConstantIndexExposureType];
            [constantValues setConstantValue:&tonemapOperatorTypeIdx type:MTLDataTypeUInt atIndex:AAPLFunctionConstantIndexTonemapType];

            MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
            pipelineDescriptor.label = [NSString stringWithFormat:@"Post Process Composite: [%@, %@]", string_for_exposure_control_type(exposureControlTypeIdx), string_for_tonemap_operator_type(tonemapOperatorTypeIdx)];
            pipelineDescriptor.colorAttachments[0].pixelFormat = _drawableFormat;
            pipelineDescriptor.sampleCount = 1;
            pipelineDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"FSQVertex"];

            id<MTLFunction> fragFunc = [defaultLibrary newFunctionWithName:@"PostProcessComposite"
                                                            constantValues:constantValues error:&error];
            NSAssert(fragFunc, @"Error when creating composite function variant: %@", error);

            pipelineDescriptor.fragmentFunction = fragFunc;

            pipeDesc.vertexDescriptor = nil;

            id<MTLRenderPipelineState> renderPipeline =
                [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
            NSAssert(renderPipeline, @"Error when creating composite pipeline variant: %@", error);

            _compositePipelineVariants[exposureControlTypeIdx][tonemapOperatorTypeIdx] = renderPipeline;
        }
    }

    //--------------------------
    // MARK: Create depth states

    // Standard depth test; test for less, write to depth buffer if true
    MTLDepthStencilDescriptor * depthStencilDesc = [MTLDepthStencilDescriptor new];
    depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDesc.depthWriteEnabled = YES;
    _depthStateLess = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];

    // Disable depth writes for post
    depthStencilDesc = nil;
    depthStencilDesc = [MTLDepthStencilDescriptor new];
    depthStencilDesc.depthWriteEnabled = NO;
    _depthStateDisabled = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];

    //---------------------------
    // MARK: Create vertex buffer

    // Create the vertex buffer for the scene, a sphere
    AAPLVertex* sphereVerts = generate_sphere_data(&_numSphereVerts);
    _sphereVertexBuffer = [_device newBufferWithBytes:sphereVerts
                                               length:_numSphereVerts * sizeof(AAPLVertex)
                                              options:MTLResourceOptionCPUCacheModeDefault];
    delete_sphere_data(sphereVerts);

    //-----------------------------
    // MARK: Create uniform buffers

    // Create and allocate the dynamic uniform buffer objects.
    for(NSUInteger i = 0; i < kMaxBuffersInFlight; i++)
    {
        _dynamicUniformBuffers[i] = [_device newBufferWithLength:sizeof(AAPLUniforms)
                                                         options:MTLResourceStorageModeShared];
        _dynamicUniformBuffers[i].label = [NSString stringWithFormat:@"UniformBuffer %lu", i];
    }

    //---------------------------
    // MARK: Create command queue

    _commandQueue = [_device newCommandQueue];
}

#pragma mark -
#pragma mark Update

// Helper method updates resolution dependent data
- (void)onSizeUpdated:(CGSize)size
{
    // Update Projection Matrix.
    _aspect = (float)size.width/size.height;
    _projectionMatrix = matrix_perspective_left_hand(_FOVy, _aspect, _nearPlane, _farPlane);

    // Update skydome constants.
    _skyDomeOffsets.y = _farPlane * tan(_FOVy * .5f);
    _skyDomeOffsets.x = _skyDomeOffsets.y * _aspect;
    _skyDomeOffsets.z = _farPlane;

    // Recompute the final render target sizes based upon resolution equivalent and aspect ratio.
    float resultWidth = size.width * _resolutionScale;
    float resultHeight = size.height * _resolutionScale;

    // Cache resolution for future computation.
    _currentViewSize = size;

    MTLTextureDescriptor * texDesc;
    texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_sceneDepthPixelFormat
                                                                 width:resultWidth
                                                                height:resultHeight
                                                             mipmapped:NO];
    texDesc.usage = MTLTextureUsageRenderTarget;


    //  The renderer will not reuse depth, it marks them as memoryless on Apple Silicon devices.
    //  Otherwise the texture must use private memory.
    texDesc.storageMode = MTLStorageModePrivate;

#if TARGET_MACOS
    if(@available( macOS 11, * ))
    {
        // On macOS, the MTLGPUFamilyApple1 enum is only avaliable on macOS 11.  On macOS 11 check
        // if running on an Apple Silicon GPU to use a memoryless render target.
        if([_device supportsFamily:MTLGPUFamilyApple1])
        {
            texDesc.storageMode = MTLStorageModeMemoryless;
        }
    }
#else
    texDesc.storageMode = MTLStorageModeMemoryless;
#endif

    _sceneDepthTexture = [_device newTextureWithDescriptor:texDesc];

    [self onPostProcessingToggle];
}

- (BOOL)isPostProcessingEnabled
{
    return _postProcessingEnabled;
}

- (void)setPostProcessingEnabled:(BOOL)enabled
{
    _postProcessingEnabled = enabled;
    [self onPostProcessingToggle];
}

- (void)onPostProcessingToggle
{
    if(_postProcessingEnabled)
    {
        float resultWidth = _currentViewSize.width * _resolutionScale;
        float resultHeight = _currentViewSize.height * _resolutionScale;

        MTLTextureDescriptor * texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_sceneColorPixelFormat
                                                                                            width:resultWidth
                                                                                           height:resultHeight
                                                                                        mipmapped:NO];
        texDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        texDesc.storageMode = MTLStorageModePrivate;
        _sceneLinearColorTexture = [_device newTextureWithDescriptor:texDesc];

        texDesc = nil;
        texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_logLuminanceFormat
                                                                     width:_currentViewSize.width * kLogLuminanceTargetScale
                                                                    height:_currentViewSize.height * kLogLuminanceTargetScale
                                                                 mipmapped:YES];
        texDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        texDesc.storageMode = MTLStorageModePrivate;
        _logLuminanceTexture = [_device newTextureWithDescriptor:texDesc];


        // Create the collection of MTLTexture objects for the bloom chain.
        // - Due to separable gaussian, two needed for each downsample level.
        // - However, these will be recycled for the upsample phase of bloom.
        for (uint32_t bloomTargetScaleIdx = 0; bloomTargetScaleIdx < kBloomTargetScaleCount; ++bloomTargetScaleIdx)
        {
            for (uint32_t blurDirectionIdx = 0; blurDirectionIdx < kBlurDirectionCount; ++blurDirectionIdx)
            {
                texDesc = nil;

                const float currBloomTargetScale = kBloomTargetScales[bloomTargetScaleIdx];
                const float currWidth = fmax(1.0, floor(resultWidth) * currBloomTargetScale);
                const float currHeight = fmax(1.0, floor(resultHeight) * currBloomTargetScale);
                const uint32_t bloomTargetIdx = bloomTargetScaleIdx * kBlurDirectionCount + blurDirectionIdx;

                texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_bloomPixelFormat
                                                                             width:currWidth
                                                                            height:currHeight
                                                                         mipmapped:NO];
                texDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
                texDesc.storageMode = MTLStorageModePrivate;
                _bloomTargets[bloomTargetIdx] = [_device newTextureWithDescriptor:texDesc];
            }
        }

        // Since render target sizes have changed, so have the texel offset values.
        _fullResolutionTexelOffset.x = 1.0 / resultWidth;
        _fullResolutionTexelOffset.y = 1.0 / resultHeight;
    }
    else
    {
        // Release render targets only used for post processing.
        _sceneLinearColorTexture = nil;
        _logLuminanceTexture = nil;

        for (uint32_t bloomTargetIdx = 0; bloomTargetIdx < kBloomTargetCount; ++bloomTargetIdx)
        {
            _bloomTargets[bloomTargetIdx] = nil;
        }
    }
}

/// Called whenever view changes orientation or layout is changed.
- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Update the aspect ratio and projection matrix since the view orientation or size has changed.
    [self onSizeUpdated:size];
}

/// Main update function for objects in the scene and shader uniforms. Called once per frame.
- (void) updateState
{
    AAPLUniforms * uniforms = (AAPLUniforms*)[_dynamicUniformBuffers[_currentUniformIndex] contents];

    // Handle camera animation.
    if (_isCameraAnimating)
    {
        _cameraAnimationFrameIndex = ++_cameraAnimationFrameIndex % _cameraStepCount;
    }

    // Callback allows for UI updates.
    _frameIndexBlock(_cameraAnimationFrameIndex);

    // Handle GPU duration history updates.
    _currentDurationHistoryIndex = (_currentDurationHistoryIndex + 1) % kGPUDurationHistorySize;
    _durationHistory[_currentDurationHistoryIndex] = _sceneBloomPostDuration + _averageLuminanceDuration;

    CFTimeInterval averageTime = 0.0;
    for (uint32_t currHistIdx = 0; currHistIdx < kGPUDurationHistorySize; ++currHistIdx)
    {
        averageTime += _durationHistory[currHistIdx];
    }

    averageTime /= (CFTimeInterval)kGPUDurationHistorySize;

    _averageGPUTimeBlock(averageTime);

    // Update world matrices for scene objects
    const float kObjectDistanceScale = 3.f;
    const float kOffsetIncrement = 360.f / OBJECT_COUNT;

    float offset = 0.f;
    for (uint objIdx = 0; objIdx < OBJECT_COUNT; ++objIdx)
    {
        uniforms->World[objIdx] = matrix4x4_translation(VEC3(sin(radians_from_degrees(offset)) * kObjectDistanceScale,
                                                             0,
                                                             cos(radians_from_degrees(offset)) * kObjectDistanceScale));
        offset += kOffsetIncrement;
    }

    // Update the view and view inverse matrices.
    const float kCurrTheta = (_cameraAnimationFrameIndex / (float)_cameraStepCount) * (2.f * M_PI);
    const vector_float3 kCameraPosition = VEC3(10.f * sin(-kCurrTheta), 2 * sin(kCurrTheta), 10.f * cos(-kCurrTheta));
    const vector_float3 kCameraLookDir = VEC3(0.f, 0.f, 0.f);
    const vector_float3 kCameraUpDir = VEC3(0.f, 1.f, 0.f);
    uniforms->View = matrix_look_at_left_hand(kCameraPosition, kCameraLookDir, kCameraUpDir);
    uniforms->ViewInv = matrix_invert(uniforms->View);

    // Update the perspective matrix
    uniforms->Perspective = _projectionMatrix;

    // Sky dome
    uniforms->skyDomeOffsets = _skyDomeOffsets;

    if(_postProcessingEnabled)
    {
        uniforms->fullResolutionTexelOffset = _fullResolutionTexelOffset;

        uniforms->bloomParameters =
            VEC4(_bloomThreshold - _bloomRange, _bloomThreshold + _bloomRange, _bloomIntensity, 1.f);

        uniforms->manualExposureValue = _manualExposureValue;
        uniforms->exposureKey = kExposureKeys[_exposureKeyIndex];

        uniforms->tonemapWhitePoint = _tonemapWhitepoint;

        // Take advantage of Extended Dynamic Range to scale the luminance.
        float EDRHeadroom = (_maximumEDRValue - 1.0);

        uniforms->luminanceScale = 1.0 + EDRHeadroom * _tonemapEDRScalingWeight;
    }
}

#pragma mark -
#pragma mark Render

/// Main render function. Called once per frame.
- (void) drawInMTKView:(nonnull MTKView *)view
{    
    [self updateState];

    // Wait to ensure only AAPLMaxBuffersInFlight are getting processed by any stage in the Metal
    // pipeline (App, Metal, Drivers, GPU, etc).
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    // Create a command buffer for the current frame.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = [NSString stringWithFormat:@"Scene CommandBuffer %lu", _cameraAnimationFrameIndex];

    // Add completion hander which signals _inFlightSemaphore when Metal and the GPU has fully
    // finished processing the commands encoded this frame.  This indicates when the dynamic
    // buffers, written to this frame, will no longer be needed by Metal and the GPU, meaning the
    // buffer contents can be changed without corrupting rendering.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    __weak AAPLRenderer * weakSelf = self;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb)
    {
        AAPLRenderer * strongSelf = weakSelf;
        dispatch_semaphore_signal(block_sema);
        strongSelf->_sceneBloomPostDuration = cb.GPUEndTime - cb.GPUStartTime;
    }];


    if(_postProcessingEnabled)
    {
        [self encodeSceneRenderingWithCommandBuffer:commandBuffer];


        // Note about calculating exposure:
        //   When logically laid out, scene exposure calculation happens prior to bloom setup; afterall,
        //   bloom setup takes exposure into account.  However, for efficiency, the renderer encodes
        //   exposure calculations after the frame presents to ensure ideal overlap and GPU utilization.
        //   The bloom filter uses the resulting value for the next frame.
        //
        //  [self encodeSceneExposureCalculation:commandbuffer];


        [self encodeBloomSetupWithCommandBuffer:commandBuffer];
        [self encodeBloomSamplingFiltersWithCommandBuffer:commandBuffer];
        [self encodeBloomCompositeAndToneMappingWithCommandBuffer:commandBuffer view:view];

        [commandBuffer presentDrawable:view.currentDrawable afterMinimumDuration:1.f / kDesiredFrameRate];

        [commandBuffer commit];

        // As mentioned in the section above, although logically incorrect, the renderer calculates
        //   exposure one frame behind, enabling enable better GPU utilization.
        [self encodeSceneExposureCalculationWithCommandBuffer:commandBuffer];
    }
    else
    {
        _sceneLinearColorTexture = view.currentDrawable.texture;
        if(_sceneLinearColorTexture)
        {
            [self encodeSceneRenderingWithCommandBuffer:commandBuffer];
        }

        [commandBuffer presentDrawable:view.currentDrawable afterMinimumDuration:1.f / kDesiredFrameRate];

        [commandBuffer commit];
    }


    _currentUniformIndex = ++_currentUniformIndex % kMaxBuffersInFlight;
}

- (void)encodeSceneRenderingWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    MTLRenderPassDescriptor * rpd = [MTLRenderPassDescriptor renderPassDescriptor];
    rpd.colorAttachments[0] = [MTLRenderPassColorAttachmentDescriptor new];
    rpd.colorAttachments[0].texture = _sceneLinearColorTexture;
    rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
    rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.f, 0.f, 0.f, 1.0);

    rpd.depthAttachment = [MTLRenderPassDepthAttachmentDescriptor new];
    rpd.depthAttachment.texture = _sceneDepthTexture;
    rpd.depthAttachment.loadAction = MTLLoadActionClear;
    rpd.depthAttachment.storeAction = MTLStoreActionDontCare;
    rpd.depthAttachment.clearDepth = 1.f;

    id<MTLRenderCommandEncoder> rce = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
    rce.label = @"Forward pass";
    [rce setDepthStencilState:_depthStateLess];
    [rce setCullMode:MTLCullModeBack];

    // Sky Dome
    [rce setRenderPipelineState:_skyDomePipeline];
    [rce setVertexBuffer:_dynamicUniformBuffers[_currentUniformIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
    [rce setFragmentTexture:_skyDomeTexture atIndex:0];
    [rce drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    // Some reflective spheres
    [rce setRenderPipelineState:_geometryPipeline];
    [rce setVertexBuffer:_sphereVertexBuffer offset:0 atIndex:AAPLBufferIndexVertices];
    [rce setVertexBuffer:_dynamicUniformBuffers[_currentUniformIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
    [rce setFragmentBuffer:_dynamicUniformBuffers[_currentUniformIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
    [rce drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numSphereVerts instanceCount:OBJECT_COUNT];

    [rce endEncoding];
}

- (void)encodeBloomSetupWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{

    MTLRenderPassDescriptor * rpd = [MTLRenderPassDescriptor renderPassDescriptor];
    rpd.colorAttachments[0] = [MTLRenderPassColorAttachmentDescriptor new];
    rpd.colorAttachments[0].texture = _bloomTargets[0];
    rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
    rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

    id<MTLRenderCommandEncoder> rce = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
    rce.label = [@"Bloom Setup: " stringByAppendingString:string_for_exposure_control_type(_exposureType)];

    // Texel offset for the target being read from
    float srcTexelScale = 1.f;
    [rce setVertexBytes:&srcTexelScale length:sizeof(srcTexelScale) atIndex:AAPLBufferIndexBytes];

    [rce setDepthStencilState:_depthStateDisabled];
    [rce setCullMode:MTLCullModeBack];
    [rce setRenderPipelineState:_bloomInitPipelineVariants[_exposureType]];
    [rce setFragmentTexture:_sceneLinearColorTexture atIndex:0];

    if (_exposureType == kExposureControlTypeKey)
    {
        [rce setFragmentTexture:_logLuminanceTexture atIndex:1];
    }

    [rce setFragmentBuffer:_dynamicUniformBuffers[_currentUniformIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
    [rce drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [rce endEncoding];
}

- (void)encodeBloomSamplingFiltersWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    // The final dst index will be the src index for bloom composite.
    uint32_t dstBloomTextureIdx = 0;
    for (uint32_t bloomPassIdx = 0; bloomPassIdx < kBloomPassCount; ++bloomPassIdx)
    {
        const float srcTexelScale = kBloomPasses[bloomPassIdx].srcTexelScale;
        const BlurDirection direction = kBloomPasses[bloomPassIdx].direction;
        const uint32_t srcBloomTextureIdx = kBloomPasses[bloomPassIdx].srcBloomTextureIdx;
        dstBloomTextureIdx = kBloomPasses[bloomPassIdx].dstBloomTextureIdx;

        MTLRenderPassDescriptor * rpd = [MTLRenderPassDescriptor renderPassDescriptor];
        rpd.colorAttachments[0] = [MTLRenderPassColorAttachmentDescriptor new];
        rpd.colorAttachments[0].texture = _bloomTargets[dstBloomTextureIdx];
        rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
        rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
        rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

        id<MTLRenderCommandEncoder> rce = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
        rce.label = [NSString stringWithFormat:@"Bloom Blur: %@ - From %d to %d",
                     (direction == kBlurDirectionX) ? @"X" : @"Y", srcBloomTextureIdx, dstBloomTextureIdx];

        // Texel offset for the target being read from.
        [rce setVertexBytes:&srcTexelScale length:sizeof(srcTexelScale) atIndex:AAPLBufferIndexBytes];

        [rce setDepthStencilState:_depthStateDisabled];
        [rce setCullMode:MTLCullModeBack];

        [rce setRenderPipelineState:_bloomBlurPipelines[direction]];
        [rce setFragmentTexture:_bloomTargets[srcBloomTextureIdx] atIndex:0];

        [rce setFragmentBuffer:_dynamicUniformBuffers[_currentUniformIndex] offset:0 atIndex:AAPLBufferIndexUniforms];
        [rce drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [rce endEncoding];
    }
}

- (void)encodeBloomCompositeAndToneMappingWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                       view:(MTKView*)view
{
    MTLRenderPassDescriptor *viewRenderPassDescriptor = view.currentRenderPassDescriptor;
    if (viewRenderPassDescriptor)
    {
        viewRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.23, 0.23, 0.23, 1.0);

        id<MTLRenderCommandEncoder> rce = [commandBuffer renderCommandEncoderWithDescriptor:viewRenderPassDescriptor];
        rce.label =
            [NSString stringWithFormat:@"Bloom Composite + Tonemapping(%@)", string_for_tonemap_operator_type(_tonemapType)];

        [rce setDepthStencilState:_depthStateDisabled];
        [rce setCullMode:MTLCullModeBack];
        [rce setRenderPipelineState:_compositePipelineVariants[_exposureType][_tonemapType]];

        [rce setFragmentTexture:_sceneLinearColorTexture atIndex:0];


        const uint32_t srcBloomTextureIdx = kBloomPasses[kBloomPassCount-1].srcBloomTextureIdx;
        [rce setFragmentTexture:_bloomTargets[srcBloomTextureIdx] atIndex:1];

        if (_exposureType == kExposureControlTypeKey)
        {
           [rce setFragmentTexture:_logLuminanceTexture atIndex:2];
        }

        [rce setFragmentBuffer:_dynamicUniformBuffers[_currentUniformIndex] offset:0 atIndex:AAPLBufferIndexUniforms];

        [rce drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [rce endEncoding];
    }
}

- (void)encodeSceneExposureCalculationWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    if (_exposureType == kExposureControlTypeKey)
    {
        // To improve parallelism, each frame uses the average luminance result from the prior frame
        //  This decouples rendering the current frame from computing the average luminance value.
        id<MTLCommandBuffer> averageLuminanceCommandBuffer = [_commandQueue commandBuffer];
        averageLuminanceCommandBuffer.label = [NSString stringWithFormat:@"Avg Luminance CommandBuffer %lu", _cameraAnimationFrameIndex];

        __weak AAPLRenderer * weakSelf = self;
        [averageLuminanceCommandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb)
        {
            AAPLRenderer * strongSelf = weakSelf;
            strongSelf->_averageLuminanceDuration = cb.GPUEndTime - cb.GPUStartTime;
            return;
        }];

        MTLRenderPassDescriptor * rpd = [MTLRenderPassDescriptor renderPassDescriptor];
        rpd.colorAttachments[0].texture = _logLuminanceTexture;
        rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
        rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
        rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

        // Calculate a per-pixel log luminance value.
        id<MTLRenderCommandEncoder> rce = [averageLuminanceCommandBuffer renderCommandEncoderWithDescriptor:rpd];
        rce.label = @"Log Luminance";

        [rce setDepthStencilState:_depthStateDisabled];
        [rce setCullMode:MTLCullModeBack];
        [rce setRenderPipelineState:_logLuminancePipeline];
        [rce setFragmentTexture:_sceneLinearColorTexture atIndex:0];
        [rce drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [rce endEncoding];

        // Generate mips -> caluclates average log luminance.
        id<MTLBlitCommandEncoder> bce = [averageLuminanceCommandBuffer blitCommandEncoder];
        bce.label = @"Mipmap Gen: Avg Luminance";
        [bce generateMipmapsForTexture:_logLuminanceTexture];
        [bce endEncoding];

        [averageLuminanceCommandBuffer commit];
    }
}
@end
