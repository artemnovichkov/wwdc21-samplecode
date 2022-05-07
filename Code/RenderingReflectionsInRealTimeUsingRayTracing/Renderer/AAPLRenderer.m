/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of renderer class which performs Metal setup and per frame rendering
*/

#import <ModelIO/ModelIO.h>
#import "AAPLMathUtilities.h"

#import "AAPLRenderer.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "AAPLShaderTypes.h"
#import "AAPLMesh.h"

static const NSUInteger kMaxBuffersInFlight = 3;
static const NSUInteger kMaxModelInstances = 2;

static const size_t kAlignedInstanceTransformsStructSize = (sizeof(AAPLInstanceTransform) & ~0xFF) + 0x100;

typedef struct ModelInstanceTransform
{
    vector_float3 position;
    float rotationRad;
} ModelInstanceTransform;

typedef struct ThinGBuffer
{
    id<MTLTexture> positionTexture;
    id<MTLTexture> directionTexture;
} ThinGBuffer;

@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;

    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    id<MTLBuffer> _lightDataBuffer;
    id<MTLBuffer> _cameraDataBuffers[kMaxBuffersInFlight];
    id<MTLBuffer> _instanceTransformBuffer;

    id<MTLRenderPipelineState> _pipelineState;
    id<MTLRenderPipelineState> _pipelineStateNoRT;
    id<MTLRenderPipelineState> _pipelineStateReflOnly;
    id<MTLRenderPipelineState> _gbufferPipelineState;
    id<MTLRenderPipelineState> _skyboxPipelineState;
    id<MTLDepthStencilState> _depthState;

    MTLVertexDescriptor *_mtlVertexDescriptor;

    uint8_t _cameraBufferIndex;
    matrix_float4x4 _projectionMatrix;

    NSArray< AAPLMesh* >* _meshes;
    AAPLMesh* _skybox;
    id<MTLTexture> _irradianceMap;

    ModelInstanceTransform _modelInstanceTransforms[kMaxModelInstances];
    id<MTLAccelerationStructure> _instanceAccelerationStructure;
    NSArray< id<MTLAccelerationStructure> >* _primitiveAccelerationStructures;

    id<MTLTexture> _rtReflectionMap;
    id<MTLComputePipelineState> _rtReflectionKernel;

    ThinGBuffer _thinGBuffer;

    NSSet< id<MTLResource> >* _sceneResources;
    id<MTLBuffer> _sceneArgumentBuffer;

    float _cameraAngle;
    float _cameraPanSpeedFactor;
    RenderMode _renderMode;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if(self)
    {
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
        [self setModelInstanceTransforms];
        _projectionMatrix = [self projectionMatrixWithAspect:view.bounds.size.width / (float)view.bounds.size.height];
        [self loadMetalWithView:view];
        [self loadAssets];
        [self buildSceneArgumentBuffer];

        // Call last to ensure everything else is built
        [self resizeRTReflectionMapTo:[view convertSizeToBacking:view.bounds.size]];
        [self buildRTAccelerationStructures];
        _cameraPanSpeedFactor = 0.5f;

    }

    return self;
}

- (void)setModelInstanceTransforms
{
    NSAssert(kMaxModelInstances == 2, @"Expected 2 Model Instances");

    _modelInstanceTransforms[0].position = (vector_float3){20.0, -5.0, -40.0};
    _modelInstanceTransforms[0].rotationRad = 135 * M_PI / 180.0f;

    _modelInstanceTransforms[1].position = (vector_float3){-13.0, -5.0, -20.0};
    _modelInstanceTransforms[1].rotationRad = 235 * M_PI / 180.0f;
}

- (void)resizeRTReflectionMapTo:(CGSize)size
{
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRG11B10Float
                                                                                    width:size.width
                                                                                   height:size.height
                                                                                mipmapped:YES];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
    _rtReflectionMap = [_device newTextureWithDescriptor:desc];

    desc.pixelFormat = MTLPixelFormatRGBA16Float;
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
    _thinGBuffer.positionTexture = [_device newTextureWithDescriptor:desc];
    _thinGBuffer.directionTexture = [_device newTextureWithDescriptor:desc];
}

#pragma mark - Build Pipeline States

/// Load Metal state objects and initialize renderer dependent view properties
- (void)loadMetalWithView:(nonnull MTKView *)view;
{
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    CGColorSpaceRef colorspace = CGColorSpaceCreateWithName( kCGColorSpaceDisplayP3 );
    view.colorspace = colorspace;
    CGColorSpaceRelease( colorspace );
    view.sampleCount = 1;

    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    // Positions.
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;

    // Texture coordinates.
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 0;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Normals.
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatHalf4;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 8;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Tangents
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTangent].format = MTLVertexFormatHalf4;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTangent].offset = 16;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Bitangents
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeBitangent].format = MTLVertexFormatHalf4;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeBitangent].offset = 24;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeBitangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Position Buffer Layout
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 12;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepRate = 1;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    // Generic Attribute Buffer Layout
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 32;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepRate = 1;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    NSError* error;
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    {
        id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

        MTLFunctionConstantValues* functionConstants = [MTLFunctionConstantValues new];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];

        {
            BOOL enableRaytracing = YES;
            [functionConstants setConstantValue:&enableRaytracing type:MTLDataTypeBool atIndex:100];
            id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader" constantValues:functionConstants error:nil];

            pipelineStateDescriptor.label = @"RT Pipeline";
            pipelineStateDescriptor.sampleCount = view.sampleCount;
            pipelineStateDescriptor.vertexFunction = vertexFunction;
            pipelineStateDescriptor.fragmentFunction = fragmentFunction;
            pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
            pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
            pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

            _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        }

        {
            BOOL enableRaytracing = NO;
            [functionConstants setConstantValue:&enableRaytracing type:MTLDataTypeBool atIndex:100];
            id<MTLFunction> fragmentFunctionNoRT = [defaultLibrary newFunctionWithName:@"fragmentShader" constantValues:functionConstants error:nil];

            pipelineStateDescriptor.label = @"No RT Pipeline";
            pipelineStateDescriptor.fragmentFunction = fragmentFunctionNoRT;

            _pipelineStateNoRT = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_pipelineStateNoRT, @"Failed to create No RT pipeline state: %@", error);
        }

        {
            pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"reflectionShader"];
            pipelineStateDescriptor.label = @"Reflection Viewer Pipeline";

            _pipelineStateReflOnly = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_pipelineStateNoRT, @"Failed to create Reflection Viewer pipeline state: %@", error);
        }

        {
            id<MTLFunction> gBufferFragmentFunction = [defaultLibrary newFunctionWithName:@"gBufferFragmentShader"];
            pipelineStateDescriptor.label = @"ThinGBufferPipeline";
            pipelineStateDescriptor.fragmentFunction = gBufferFragmentFunction;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatRGBA16Float;

            _gbufferPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_gbufferPipelineState, @"Failed to create GBuffer pipeline state: %@", error);
        }

        {
            id<MTLFunction> skyboxVertexFunction = [defaultLibrary newFunctionWithName:@"skyboxVertex"];
            id<MTLFunction> skyboxFragmentFunction = [defaultLibrary newFunctionWithName:@"skyboxFragment"];
            pipelineStateDescriptor.label = @"SkyboxPipeline";
            pipelineStateDescriptor.vertexFunction = skyboxVertexFunction;
            pipelineStateDescriptor.fragmentFunction = skyboxFragmentFunction;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatInvalid;

             _skyboxPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_skyboxPipelineState, @"Failed to create Skybox Render Pipeline State: %@", error );
        }
    }

    if(_device.supportsRaytracing)
    {
        id<MTLFunction> rtReflectionFunction = [defaultLibrary newFunctionWithName:@"rtReflection"];

        _rtReflectionKernel = [_device newComputePipelineStateWithFunction:rtReflectionFunction error:&error];
        NSAssert(_rtReflectionKernel, @"Failed to create RT reflection compute pipeline state: %@", error);

        _renderMode = RMMetalRaytracing;
    }
    else
    {
        _renderMode = RMNoRaytracing;
    }

    {
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = YES;

        _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    for(int i = 0; i < kMaxBuffersInFlight; i++)
    {
        _cameraDataBuffers[i] = [_device newBufferWithLength:sizeof(AAPLCameraData)
                                                 options:MTLResourceStorageModeShared];

        _cameraDataBuffers[i].label = [NSString stringWithFormat:@"CameraDataBuffer %d", i];
    }

    NSUInteger instanceBufferSize = kAlignedInstanceTransformsStructSize * kMaxModelInstances;
    _instanceTransformBuffer = [_device newBufferWithLength:instanceBufferSize
                                                    options:MTLResourceStorageModeShared];
    _instanceTransformBuffer.label = @"InstanceTransformBuffer";


    _lightDataBuffer = [_device newBufferWithLength:sizeof(AAPLLightData) options:MTLResourceStorageModeShared];
    _lightDataBuffer.label = @"LightDataBuffer";

    _commandQueue = [_device newCommandQueue];

    [self setStaticState];
}

#pragma mark - Asset Loading

/// Create and load assets into Metal objects including meshes and textures
- (void)loadAssets
{
    NSError *error;

    // Create a Model I/O vertexDescriptor to format/layout the Model I/O mesh vertices to
    // fit the Metal render pipeline's vertex descriptor layout
    MDLVertexDescriptor *modelIOVertexDescriptor =
        MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);

    // Indicate how each Metal vertex descriptor attribute maps to each ModelIO  attribute
    modelIOVertexDescriptor.attributes[AAPLVertexAttributePosition].name  = MDLVertexAttributePosition;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeNormal].name    = MDLVertexAttributeNormal;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTangent].name   = MDLVertexAttributeTangent;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeBitangent].name = MDLVertexAttributeBitangent;

    NSURL *modelFileURL = [[NSBundle mainBundle] URLForResource:@"Models/firetruck.obj"
                                                  withExtension:nil];

    NSAssert(modelFileURL, @"Could not find model (%@) file in bundle creating specular texture", modelFileURL.absoluteString);

    _meshes = [AAPLMesh newMeshesFromURL:modelFileURL
                 modelIOVertexDescriptor:modelIOVertexDescriptor
                             metalDevice:_device
                                   error:&error];

    NSAssert(_meshes, @"Could not create meshes from model file %@: %@", modelFileURL.absoluteString, error);

    NSDictionary *textureLoaderOptions =
    @{
      MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
      MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
      };

    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];

    _irradianceMap = [textureLoader newTextureWithName:@"IrradianceMap" scaleFactor:1.0 bundle:nil options:textureLoaderOptions error:&error];
    NSAssert(_irradianceMap, @"Could not load IrradianceMap: %@", error);

    _skybox = [AAPLMesh newSkyboxMeshOnDevice:_device];
    NSAssert( _skybox, @"Could not create skybox model" );
}

#pragma mark - Encode Argument Buffer for Scene resources

/// Convenience method to creating MTLArgumentDescriptor objects for readonly access.
- (MTLArgumentDescriptor *)argumentDescriptorWithIndex:(NSUInteger)index dataType:(MTLDataType)dataType
{
    MTLArgumentDescriptor* argumentDescriptor = [MTLArgumentDescriptor argumentDescriptor];
    argumentDescriptor.index = index;
    argumentDescriptor.dataType = dataType;
    argumentDescriptor.access = MTLArgumentAccessReadOnly;
    return argumentDescriptor;
}

/// Build an argument buffer with all resources for the scene.   The raytracing shaders will access meshes, submeshes and materials
/// through this arugument buffer to apply correct lighting to calculated reflections.
- (void)buildSceneArgumentBuffer
{
    // This structure is built to match the raytraced scene structure so the raytracing shader
    // can navigate it. In particular, each submesh is represented as a "geometry" in the primitive
    // acceleration structure.

    // MTLArgumentDescriptor objects describe the layout of data and therefore must match the
    // structures in AAPLArgumentBufferTypes.h.

    NSMutableSet< id<MTLResource> >* sceneResources = [NSMutableSet new];

//    struct MeshGenerics
//    {
//        float2 tc;
//        half4 normal;
//        half4 tangent;
//        half4 bitangent;
//    };

//    struct Material
//    {
//        texture2d< float > texture;
//    };

    MTLArgumentDescriptor* textureArgument = [self argumentDescriptorWithIndex:0 dataType:MTLDataTypeTexture];

    id<MTLArgumentEncoder> materialEncoder = [_device newArgumentEncoderWithArguments:@[
        textureArgument
    ]];

//    struct Submesh
//    {
//        // Positions and generic vertex attributes stored in container mesh.
//        uint32_t* indices; // indices are into the container mesh's position and generics arrays
//        Material* materials;
//    };

//    struct Mesh
//    {
//        packed_float3* positions;
//        MeshGenerics* generics;
//        Submesh* submeshes;
//    };

    MTLArgumentDescriptor* indicesArgument = [self argumentDescriptorWithIndex:0 dataType:MTLDataTypePointer];
    MTLArgumentDescriptor* materialsArgument = [self argumentDescriptorWithIndex:1 dataType:MTLDataTypePointer];
    MTLArgumentDescriptor* materialDataArgument = [self argumentDescriptorWithIndex:2 dataType:MTLDataTypePointer];
    id<MTLArgumentEncoder> submeshEncoder = [_device newArgumentEncoderWithArguments:@[
        indicesArgument, materialsArgument, materialDataArgument
    ]];

    // Meshes

    MTLArgumentDescriptor* positionsArgument = [self argumentDescriptorWithIndex:0 dataType:MTLDataTypePointer];
    MTLArgumentDescriptor* genericsArgument = [self argumentDescriptorWithIndex:1 dataType:MTLDataTypePointer];
    MTLArgumentDescriptor* submeshesArgument = [self argumentDescriptorWithIndex:2 dataType:MTLDataTypePointer];

    id<MTLArgumentEncoder> meshEncoder = [_device newArgumentEncoderWithArguments:@[
       positionsArgument, genericsArgument, submeshesArgument
    ]];

    id<MTLBuffer> meshBuffer = [_device newBufferWithLength:meshEncoder.encodedLength * _meshes.count options:MTLResourceStorageModeManaged];
    for ( NSUInteger i = 0; i < _meshes.count; ++i )
    {
        AAPLMesh* mesh = _meshes[i];
        [meshEncoder setArgumentBuffer:meshBuffer offset:i * meshEncoder.encodedLength];

        MTKMesh* metalKitMesh = mesh.metalKitMesh;
        [meshEncoder setBuffer:metalKitMesh.vertexBuffers[0].buffer offset:metalKitMesh.vertexBuffers[0].offset atIndex:0];
        [meshEncoder setBuffer:metalKitMesh.vertexBuffers[1].buffer offset:metalKitMesh.vertexBuffers[1].offset atIndex:1];

        // Build submeshes into a buffer and reference it through a pointer in the mesh:

        NSUInteger submeshArgumentBufferLength = submeshEncoder.encodedLength * mesh.submeshes.count;
        id<MTLBuffer> submeshArgumentBuffer = [_device newBufferWithLength:submeshArgumentBufferLength
                                                                   options:MTLResourceStorageModeManaged];

        for ( NSUInteger j = 0; j < mesh.submeshes.count; ++j )
        {
            AAPLSubmesh* submesh = mesh.submeshes[j];
            [submeshEncoder setArgumentBuffer:submeshArgumentBuffer offset:(submeshEncoder.encodedLength * j)];

            MTKMeshBuffer* indexBuffer = submesh.metalKitSubmmesh.indexBuffer;
            [submeshEncoder setBuffer:indexBuffer.buffer offset:indexBuffer.offset atIndex:0];

            // Build materials into a buffer and reference it through a pointer in the submesh:

            NSUInteger materialsArgumentBufferLength = materialEncoder.encodedLength * submesh.textures.count;
            id<MTLBuffer> materialsArgumentBuffer = [_device newBufferWithLength:materialsArgumentBufferLength
                                                                         options:MTLResourceStorageModeManaged];

            for (NSUInteger m = 0; m < submesh.textures.count; ++m)
            {
                [materialEncoder setArgumentBuffer:materialsArgumentBuffer offset:(materialEncoder.encodedLength * m)];
                [materialEncoder setTexture:submesh.textures[m] atIndex:0];
            }
            [materialsArgumentBuffer didModifyRange:NSMakeRange(0, materialsArgumentBuffer.length)];
            [sceneResources addObjectsFromArray:submesh.textures];
            [sceneResources addObject:materialsArgumentBuffer];

            // end materials

            [submeshEncoder setBuffer:materialsArgumentBuffer offset:0 atIndex:1];

            // Material Data

            [submeshEncoder setBuffer:submesh.materialData offset:0 atIndex:2];
            [sceneResources addObject:submesh.materialData];
        }
        [submeshArgumentBuffer didModifyRange:NSMakeRange(0, submeshArgumentBuffer.length)];
        [sceneResources addObject:submeshArgumentBuffer];

        // end submeshes

        [meshEncoder setBuffer:submeshArgumentBuffer offset:0 atIndex:2];
    }

    [meshBuffer didModifyRange:NSMakeRange(0, meshBuffer.length)];
    [sceneResources addObject:meshBuffer];

//    struct Instance
//    {
//        Mesh* mesh;
//        float4x4 transform;
//    };

    MTLArgumentDescriptor* meshArgument = [self argumentDescriptorWithIndex:0 dataType:MTLDataTypePointer];
    MTLArgumentDescriptor* transformArgument = [self argumentDescriptorWithIndex:1 dataType:MTLDataTypeFloat4x4];

    id<MTLArgumentEncoder> instanceEncoder = [_device newArgumentEncoderWithArguments:@[
        meshArgument, transformArgument
    ]];

    id<MTLBuffer> instanceBuffer = [_device newBufferWithLength:instanceEncoder.encodedLength * kMaxModelInstances options:MTLResourceStorageModeManaged];

    for ( NSUInteger i = 0; i < kMaxModelInstances; ++i )
    {
        [instanceEncoder setArgumentBuffer:instanceBuffer offset:(instanceEncoder.encodedLength * i)];
        [instanceEncoder setBuffer:meshBuffer offset:0 atIndex:0]; // essentially mesh[0]
        matrix_float4x4* pm = (matrix_float4x4 *)[instanceEncoder constantDataAtIndex:1];

        vector_float3 rotationAxis = {0, 1, 0};
        matrix_float4x4 rotationMatrix = matrix4x4_rotation( _modelInstanceTransforms[i].rotationRad, rotationAxis );
        matrix_float4x4 translationMatrix = matrix4x4_translationv( _modelInstanceTransforms[i].position );
        *pm = matrix_multiply(translationMatrix, rotationMatrix);
    }

    [instanceBuffer didModifyRange:NSMakeRange(0, instanceBuffer.length)];

    [sceneResources addObject:instanceBuffer];

//    struct Scene
//    {
//        Instance* instances;
//    };

    MTLArgumentDescriptor* instancesArgument = [self argumentDescriptorWithIndex:0 dataType:MTLDataTypePointer];
    id<MTLArgumentEncoder> sceneEncoder = [_device newArgumentEncoderWithArguments:@[instancesArgument]];
    id<MTLBuffer> sceneBuffer = [_device newBufferWithLength:sceneEncoder.encodedLength options:MTLResourceStorageModeManaged];

    [sceneEncoder setArgumentBuffer:sceneBuffer offset:0];
    [sceneEncoder setBuffer:instanceBuffer offset:0 atIndex:0];

    [sceneBuffer didModifyRange:NSMakeRange(0, sceneBuffer.length)];
    [sceneResources addObject:sceneBuffer];

    _sceneResources = sceneResources;
    _sceneArgumentBuffer = sceneBuffer;

}

#pragma mark - Build Acceleration Structures

- (id<MTLAccelerationStructure>)allocateAndBuildAccelerationStructureWithDescriptor:(MTLAccelerationStructureDescriptor *)descriptor
{
    MTLAccelerationStructureSizes sizes = [_device accelerationStructureSizesWithDescriptor:descriptor];
    id<MTLBuffer> scratch = [_device newBufferWithLength:sizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];
    id<MTLAccelerationStructure> accelStructure = [_device newAccelerationStructureWithSize:sizes.accelerationStructureSize];

    id<MTLCommandBuffer> cmd = [_commandQueue commandBuffer];
    id<MTLAccelerationStructureCommandEncoder> enc = [cmd accelerationStructureCommandEncoder];
    [enc buildAccelerationStructure:accelStructure descriptor:descriptor scratchBuffer:scratch scratchBufferOffset:0];
    [enc endEncoding];
    [cmd commit];

    return accelStructure;
}

/// Build Raytracing Acceleration Structures
- (void)buildRTAccelerationStructures
{
    // Each mesh is an individual primitive acceleration structure, with each submesh being one
    // geometry within that acceleration structure

    // Instance Acceleration Structure references n Instances
    // 1 Instance references 1 Primitive Acceleration Structure
    // 1 Primitive Acceleration Structure = 1 Mesh in _meshes
    // 1 Primitive Acceleration Structure -> n geometries == n submeshes

    NSMutableArray< id<MTLAccelerationStructure>> *primitiveAccelerationStructures = [NSMutableArray arrayWithCapacity:_meshes.count];
    for ( AAPLMesh* mesh in _meshes )
    {
        NSMutableArray< MTLAccelerationStructureTriangleGeometryDescriptor* >* geometries = [NSMutableArray arrayWithCapacity:mesh.submeshes.count];
        for ( AAPLSubmesh* submesh in mesh.submeshes )
        {
            MTLAccelerationStructureTriangleGeometryDescriptor* g = [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
            g.vertexBuffer = mesh.metalKitMesh.vertexBuffers.firstObject.buffer;
            g.vertexBufferOffset = mesh.metalKitMesh.vertexBuffers.firstObject.offset;
            g.vertexStride = 12; // buffer must be packed XYZ XYZ XYZ ...

            g.indexBuffer = submesh.metalKitSubmmesh.indexBuffer.buffer;
            g.indexBufferOffset = submesh.metalKitSubmmesh.indexBuffer.offset;
            g.indexType = submesh.metalKitSubmmesh.indexType;

            NSUInteger indexElementSize = (g.indexType == MTLIndexTypeUInt16) ? sizeof(uint16_t) : sizeof(uint32_t);
            g.triangleCount = submesh.metalKitSubmmesh.indexBuffer.length / indexElementSize / 3;
            [geometries addObject:g];
        }
        MTLPrimitiveAccelerationStructureDescriptor* primDesc = [MTLPrimitiveAccelerationStructureDescriptor descriptor];
        primDesc.geometryDescriptors = geometries;
        [primitiveAccelerationStructures addObject:[self allocateAndBuildAccelerationStructureWithDescriptor:primDesc]];
    }
    _primitiveAccelerationStructures = primitiveAccelerationStructures;

    MTLInstanceAccelerationStructureDescriptor* instanceAccelStructureDesc = [MTLInstanceAccelerationStructureDescriptor descriptor];
    instanceAccelStructureDesc.instancedAccelerationStructures = primitiveAccelerationStructures;

    instanceAccelStructureDesc.instanceCount = kMaxModelInstances;

    // Load instance data (2 fire trucks):

    id<MTLBuffer> instanceDescriptorBuffer = [_device newBufferWithLength:sizeof(MTLAccelerationStructureInstanceDescriptor) * kMaxModelInstances options:MTLResourceStorageModeShared];
    MTLAccelerationStructureInstanceDescriptor* instanceDescriptors = (MTLAccelerationStructureInstanceDescriptor *)instanceDescriptorBuffer.contents;
    for (NSUInteger i = 0; i < kMaxModelInstances; ++i)
    {
        instanceDescriptors[i].accelerationStructureIndex = 0; // all instances are referencing the first primitive acceleration structure
        instanceDescriptors[i].intersectionFunctionTableOffset = 0;
        instanceDescriptors[i].mask = 0xFF;
        instanceDescriptors[i].options = MTLAccelerationStructureInstanceOptionNone;

        AAPLInstanceTransform* transforms = (AAPLInstanceTransform *)(((uint8_t *)_instanceTransformBuffer.contents) + i * kAlignedInstanceTransformsStructSize);
        instanceDescriptors[i].transformationMatrix = matrix4x4_drop_last_row( transforms->modelViewMatrix );
    }
    instanceAccelStructureDesc.instanceDescriptorBuffer = instanceDescriptorBuffer;

    _instanceAccelerationStructure = [self allocateAndBuildAccelerationStructureWithDescriptor:instanceAccelStructureDesc];
}

#pragma mark - Update State

- (void)setStaticState
{
    for (NSUInteger i = 0; i < kMaxModelInstances; ++i)
    {
        AAPLInstanceTransform* transforms = (AAPLInstanceTransform *)(((uint8_t *)_instanceTransformBuffer.contents) + (i * kAlignedInstanceTransformsStructSize));

        vector_float3 rotationAxis = {0, 1, 0};
        matrix_float4x4 rotationMatrix = matrix4x4_rotation( _modelInstanceTransforms[i].rotationRad, rotationAxis );
        matrix_float4x4 translationMatrix = matrix4x4_translationv( _modelInstanceTransforms[i].position );

        transforms->modelViewMatrix = matrix_multiply(translationMatrix, rotationMatrix);
    }

    [self updateCameraState];

    AAPLLightData* pLightData = (AAPLLightData *)(_lightDataBuffer.contents);
    pLightData->directionalLightInvDirection = -vector_normalize((vector_float3){ 0, -6, -6 });
    pLightData->lightIntensity = 5.0f;
}

- (void)updateCameraState
{
    // Determine next safe slot:

    _cameraBufferIndex = ( _cameraBufferIndex + 1 ) % kMaxBuffersInFlight;

    // Update Projection Matrix
    AAPLCameraData* pCameraData = (AAPLCameraData *)_cameraDataBuffers[_cameraBufferIndex].contents;
    pCameraData->projectionMatrix = _projectionMatrix;

    // Update Camera Position (and View Matrix):

    vector_float3 camPos = (vector_float3){ cosf( _cameraAngle ) * 10.0f, 5, sinf(_cameraAngle) * 22.5f };
    _cameraAngle += (0.02 * _cameraPanSpeedFactor);
    if ( _cameraAngle >= 2 * M_PI )
    {
        _cameraAngle -= (2 * M_PI);
    }

    pCameraData->viewMatrix = matrix4x4_translationv( -camPos );
    pCameraData->cameraPosition = camPos;
}

#pragma mark - Rendering

- (void)encodeSceneRendering:(id<MTLRenderCommandEncoder >)renderEncoder
{
    for (AAPLMesh *mesh in _meshes)
    {
        MTKMesh *metalKitMesh = mesh.metalKitMesh;

        // Set mesh's vertex buffers
        for (NSUInteger bufferIndex = 0; bufferIndex < metalKitMesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
            if((NSNull *)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        // Draw each submesh of the mesh
        for(AAPLSubmesh *submesh in mesh.submeshes)
        {
            // Set all textures for the submesh even if the shaders may not sample from them since
            //    the cost setting the texture in the encoder is negligible compareed to the cost
            //    of sampling from it in a shader.
            for(AAPLTextureIndex textureIndex = 0; textureIndex < AAPLNumMeshTextureIndices; textureIndex++)
            {
                [renderEncoder setFragmentTexture:submesh.textures[textureIndex] atIndex:textureIndex];
            }

            MTKSubmesh *metalKitSubmesh = submesh.metalKitSubmmesh;

            for (NSUInteger i = 0; i < kMaxModelInstances; ++i)
            {
                [renderEncoder setVertexBuffer:_instanceTransformBuffer
                                        offset:kAlignedInstanceTransformsStructSize * i
                                       atIndex:BufferIndexInstanceTransforms];

                [renderEncoder setVertexBuffer:_cameraDataBuffers[_cameraBufferIndex] offset:0 atIndex:BufferIndexCameraData];
                [renderEncoder setFragmentBuffer:_cameraDataBuffers[_cameraBufferIndex] offset:0 atIndex:BufferIndexCameraData];
                [renderEncoder setFragmentBuffer:_lightDataBuffer offset:0 atIndex:BufferIndexLightData];

                [renderEncoder drawIndexedPrimitives:metalKitSubmesh.primitiveType
                                          indexCount:metalKitSubmesh.indexCount
                                           indexType:metalKitSubmesh.indexType
                                         indexBuffer:metalKitSubmesh.indexBuffer.buffer
                                   indexBufferOffset:metalKitSubmesh.indexBuffer.offset];
            }

        }

    }

}

- (void)copyDepthStencilConfigurationFrom:(MTLRenderPassDescriptor *)src to:(MTLRenderPassDescriptor *)dest
{
    dest.depthAttachment.loadAction     = src.depthAttachment.loadAction;
    dest.depthAttachment.clearDepth     = src.depthAttachment.clearDepth;
    dest.depthAttachment.texture        = src.depthAttachment.texture;
    dest.stencilAttachment.loadAction   = src.stencilAttachment.loadAction;
    dest.stencilAttachment.clearStencil = src.stencilAttachment.clearStencil;
    dest.stencilAttachment.texture      = src.stencilAttachment.texture;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    /// Per frame updates here

    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Render Commands";

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];

    [self updateCameraState];

    /// Delay getting the currentRenderPassDescriptor until the renderer absolutely needs it to avoid
    ///   holding onto the drawable and blocking the display pipeline any longer than necessary
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {

        // When raytracing is enabled, first render a thin G-Buffer containing
        // position and reflection direction data. Then, dispatch a compute
        // kernel that raytraces mirror-like reflections from this data.

        if ( _renderMode == RMMetalRaytracing || _renderMode == RMReflectionsOnly )
        {

            MTLRenderPassDescriptor* gbufferPass = [MTLRenderPassDescriptor new];
            gbufferPass.colorAttachments[0].loadAction = MTLLoadActionClear;
            gbufferPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
            gbufferPass.colorAttachments[0].storeAction = MTLStoreActionStore;
            gbufferPass.colorAttachments[0].texture = _thinGBuffer.positionTexture;

            gbufferPass.colorAttachments[1].loadAction = MTLLoadActionClear;
            gbufferPass.colorAttachments[1].clearColor = MTLClearColorMake(0, 0, 0, 1);
            gbufferPass.colorAttachments[1].storeAction = MTLStoreActionStore;
            gbufferPass.colorAttachments[1].texture = _thinGBuffer.directionTexture;

            [self copyDepthStencilConfigurationFrom:renderPassDescriptor to:gbufferPass];
            gbufferPass.depthAttachment.storeAction = MTLStoreActionStore;

            // Create a render command encoder so we can render into something
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:gbufferPass];

            renderEncoder.label = @"ThinGBufferRenderEncoder";

            // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
            [renderEncoder pushDebugGroup:@"ThinGBuffer Pass"];

            // Set render command encoder state
            [renderEncoder setCullMode:MTLCullModeFront];
            [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
            [renderEncoder setRenderPipelineState:_gbufferPipelineState];
            [renderEncoder setDepthStencilState:_depthState];

            // Encode all draw calls for the scene
            [self encodeSceneRendering:renderEncoder];

            [renderEncoder popDebugGroup];

            // Done encoding commands
            [renderEncoder endEncoding];

            // Raytrace reflections

            id<MTLComputeCommandEncoder> compEnc = [commandBuffer computeCommandEncoder];
            [compEnc pushDebugGroup:@"Raytraced Reflections"];
            compEnc.label = @"RaytracedReflectionsComputeEncoder";
            [compEnc setTexture:_rtReflectionMap atIndex:OutImageIndex];
            [compEnc setTexture:_thinGBuffer.positionTexture atIndex:ThinGBufferPositionIndex];
            [compEnc setTexture:_thinGBuffer.directionTexture atIndex:ThinGBufferDirectionIndex];
            [compEnc setTexture:_irradianceMap atIndex:IrradianceMapIndex];

            // Bind root of the argument buffer for the scene:
            [compEnc setBuffer:_sceneArgumentBuffer offset:0 atIndex:SceneIndex];

            // Bind pre-built acceleration structure:
            [compEnc setAccelerationStructure:_instanceAccelerationStructure atBufferIndex:AccelerationStructureIndex];

            [compEnc setBuffer:_instanceTransformBuffer offset:0 atIndex:BufferIndexInstanceTransforms];
            [compEnc setBuffer:_cameraDataBuffers[_cameraBufferIndex] offset:0 atIndex:BufferIndexCameraData];
            [compEnc setBuffer:_lightDataBuffer offset:0 atIndex:BufferIndexLightData];

            // Set the raytracing reflection kernel:
            [compEnc setComputePipelineState:_rtReflectionKernel];

            // Determine dispatch grid size and dispatch compute.

            NSUInteger w = _rtReflectionKernel.threadExecutionWidth;
            NSUInteger h = _rtReflectionKernel.maxTotalThreadsPerThreadgroup / w;
            MTLSize threadsPerThreadgroup = MTLSizeMake( w, h, 1 );
            MTLSize threadsPerGrid = MTLSizeMake(_rtReflectionMap.width, _rtReflectionMap.height, 1);

            [compEnc dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];

            // Flag residency for indirectly-referenced resources.
            // These are:
            // 1. all primitive acceleration structures.
            // 2. buffers and textures referenced through argument buffers.

            for ( id<MTLAccelerationStructure> primAccelStructure in _primitiveAccelerationStructures )
            {
                [compEnc useResource:primAccelStructure usage:MTLResourceUsageRead];
            }

            for ( id<MTLResource> resource in _sceneResources )
            {
                [compEnc useResource:resource usage:MTLResourceUsageRead];
            }

            [compEnc popDebugGroup];
            [compEnc endEncoding];

            // Normally, for accurate rough reflections a renderer would perform cone raytracing in
            // the raytracing kernel.  In this case, the renderer simplifies this by blurring the
            // mirror-like reflections along the mipchain.  The renderer later biases the miplevel
            // sampled when reading the reflection in the accumulation pass.

            id<MTLBlitCommandEncoder> genMips = [commandBuffer blitCommandEncoder];
            [genMips generateMipmapsForTexture:_rtReflectionMap];
            [genMips endEncoding];
        }

        
        // Encode forward pass

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
        [renderEncoder pushDebugGroup:@"Forward Pass"];
        renderEncoder.label = @"ForwardPassRenderEncoder";

        if ( _renderMode == RMMetalRaytracing )
        {
            [renderEncoder setRenderPipelineState:_pipelineState];
        }
        else if ( _renderMode == RMNoRaytracing )
        {
            [renderEncoder setRenderPipelineState:_pipelineStateNoRT];
        }
        else if ( _renderMode == RMReflectionsOnly )
        {
            [renderEncoder setRenderPipelineState:_pipelineStateReflOnly];
        }

        [renderEncoder setCullMode:MTLCullModeFront];
        [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setFragmentTexture:_rtReflectionMap atIndex:AAPLTextureIndexReflections];
        [renderEncoder setFragmentTexture:_irradianceMap atIndex:AAPLTextureIndexIrradianceMap];

        [self encodeSceneRendering:renderEncoder];

        // Encode skybox rendering:

        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_skyboxPipelineState];
        MTKMesh* metalKitMesh = _skybox.metalKitMesh;
        for (NSUInteger bufferIndex = 0; bufferIndex < metalKitMesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
            if((NSNull *)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        for(MTKSubmesh *submesh in metalKitMesh.submeshes)
        {
            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                      indexCount:submesh.indexCount
                                       indexType:submesh.indexType
                                     indexBuffer:submesh.indexBuffer.buffer
                               indexBufferOffset:submesh.indexBuffer.offset];
        }

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (matrix_float4x4)projectionMatrixWithAspect:(float)aspect
{
    return matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

#pragma mark - Event Handling

/// Respond to drawable size or orientation changes here.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{

    float aspect = size.width / (float)size.height;
    _projectionMatrix = [self projectionMatrixWithAspect:aspect];

    [self resizeRTReflectionMapTo:size]; // passed-in size is already in backing coordinates

}

- (void)setRenderMode:(RenderMode)renderMode
{
    _renderMode = renderMode;
}

- (void)setCameraPanSpeedFactor:(float)speedFactor
{
    _cameraPanSpeedFactor = speedFactor;
}

@end
