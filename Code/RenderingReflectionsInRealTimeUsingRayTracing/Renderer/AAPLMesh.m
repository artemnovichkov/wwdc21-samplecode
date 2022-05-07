/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation for Mesh and Submesh objects
*/

@import MetalKit;
@import ModelIO;

#import "AAPLMesh.h"
#import "AAPLMathUtilities.h"
#import "AAPLArgumentBufferTypes.h"

@implementation AAPLSubmesh
{
    NSMutableArray<id<MTLTexture>> *_textures;
    AAPLMaterialData *_values;
    id<MTLBuffer> _materialData;
}

@synthesize textures = _textures;
@synthesize materialData = _materialData;

/// Create a metal texture with the given semantic in the given Model I/O material object
+ (nonnull id<MTLTexture>) createMetalTextureFromMaterial:(nonnull MDLMaterial *)material
                                  modelIOMaterialSemantic:(MDLMaterialSemantic)materialSemantic
                                      modelIOMaterialType:(MDLMaterialPropertyType)defaultPropertyType
                                    metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
                                             materialData:(nullable void *)data
{
    id<MTLTexture> texture = nil;

    NSArray<MDLMaterialProperty *> *propertiesWithSemantic
        = [material propertiesWithSemantic:materialSemantic];

    for (MDLMaterialProperty *property in propertiesWithSemantic)
    {
        assert(property.semantic == materialSemantic);

        if(property.type == MDLMaterialPropertyTypeString)
        {
            // Load textures with TextureUsageShaderRead and StorageModePrivate.
            NSDictionary *textureLoaderOptions =
            @{
              MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
              MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
              };

            // First will interpret the string as a file path and attempt to load it with
            //    -[MTKTextureLoader newTextureWithContentsOfURL:options:error:]

            NSURL *url = property.URLValue;
            NSMutableString *URLString = nil;
            if(property.type == MDLMaterialPropertyTypeURL) {
                URLString = [[NSMutableString alloc] initWithString:[url absoluteString]];
            } else {
                URLString = [[NSMutableString alloc] initWithString:@"file://"];
                [URLString appendString:property.stringValue];
            }

            NSURL *textureURL = [NSURL URLWithString:URLString];

            // Attempt to load the texture from the file system.
            texture = [textureLoader newTextureWithContentsOfURL:textureURL
                                                         options:textureLoaderOptions
                                                           error:nil];

            // If the texture has been found for a material using the string as a file path
            // name, then return it.
            if(texture)
            {
                return texture;
            }

            // If no texture has been fround by interpreting the URL as a path, interpret
            // string as an asset catalog name and attempt to load it with
            //  -[MTKTextureLoader newTextureWithName:scaleFactor:bundle:options::error:]

            NSString *lastComponent =
                [[property.stringValue componentsSeparatedByString:@"/"] lastObject];

            texture = [textureLoader newTextureWithName:lastComponent
                                            scaleFactor:1.0
                                                 bundle:nil
                                                options:textureLoaderOptions
                                                  error:nil];

            // If a texture with the by interpreting the URL as an asset catalog name,
            // then return it.
            if(texture) {
                return texture;
            }

            // If no texture found by interpreting it as a file path or as an asset name
            // in the asset catalog, something went wrong (Perhaps the file was missing or
            // misnamed in the asset catalog, model/material file, or file system).

            // Depending on how the Metal render pipeline use with this submesh is implemented,
            // this condition can be handled more gracefully.  The app could load a dummy texture
            // that will look okay when set with the pipeline or ensure that the pipelines
            // rendering this submesh do not require a material with this property.

            [NSException raise:@"Texture data for material property not found"
                        format:@"Requested material property semantic: %lu string: %@",
                                materialSemantic, property.stringValue];
        }
        else if (data && defaultPropertyType !=  MDLMaterialPropertyTypeNone && property.type == defaultPropertyType)
        {
            switch (defaultPropertyType)
            {
                case MDLMaterialPropertyTypeFloat:
                    *(float *)data = property.floatValue;
                    break;
                case MDLMaterialPropertyTypeFloat3:
                    *(vector_float3 *)data = property.float3Value;
                    break;
                default:
                    [NSException raise:@"Invalid MDLMaterialPropertyType for semantic"
                            format:@"Requested MDLMaterialPropertyType(%lu) for material property semantic(%lu)",
                                    defaultPropertyType, materialSemantic];
            }
        }
    }

    if (!texture)
    {
        [NSException raise:@"No appropriate material property from which to create texture"
                format:@"Requested material property semantic: %lu", materialSemantic];
    }

    return texture;
}

- (nonnull instancetype) initWithModelIOSubmesh:(nonnull MDLSubmesh *)modelIOSubmesh
                                metalKitSubmesh:(nonnull MTKSubmesh *)metalKitSubmesh
                          metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
{
    self = [super init];
    if(self)
    {
        _metalKitSubmmesh = metalKitSubmesh;

        _textures = [[NSMutableArray alloc] initWithCapacity:AAPLNumMeshTextureIndices];

        // Fill up texture array with null objects so that it can be indexed into
        for(NSUInteger shaderIndex = 0; shaderIndex < AAPLNumMeshTextureIndices; shaderIndex++) {
            [_textures addObject:(id<MTLTexture>)[NSNull null]];
        }

        // Create the buffer with materials.
        _materialData = [textureLoader.device newBufferWithLength:sizeof(AAPLMaterialData)
                                                               options:0];

        _materialData.label = @"Material Data";

        _values = (AAPLMaterialData *)_materialData.contents;

        // Set default material values for shaders
        _values->baseColor = (vector_float3){0.3, 0.0, 0.0};
        _values->roughness = 0.2f;
        _values->metalness = 0;
        _values->ambientOcclusion = 0.5f;
        _values->irradiatedColor = (vector_float3){1.0, 1.0, 1.0};

        // Set each index in the array with the appropriate material semantic specified in the
        //   submesh's material property

        _textures[AAPLTextureIndexBaseColor] =
            [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                                modelIOMaterialSemantic:MDLMaterialSemanticBaseColor
                                    modelIOMaterialType:MDLMaterialPropertyTypeFloat3
                                  metalKitTextureLoader:textureLoader
                                           materialData:&(_values->baseColor)];

        _textures[AAPLTextureIndexMetallic] =
            [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                                modelIOMaterialSemantic:MDLMaterialSemanticMetallic
                                    modelIOMaterialType:MDLMaterialPropertyTypeFloat3
                                  metalKitTextureLoader:textureLoader
                                           materialData:&(_values->metalness)];

        _textures[AAPLTextureIndexRoughness] =
        [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                            modelIOMaterialSemantic:MDLMaterialSemanticRoughness
                                modelIOMaterialType:MDLMaterialPropertyTypeFloat3
                              metalKitTextureLoader:textureLoader
                                       materialData:&(_values->roughness)];

        _textures[AAPLTextureIndexNormal] =
        [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                            modelIOMaterialSemantic:MDLMaterialSemanticTangentSpaceNormal
                                modelIOMaterialType:MDLMaterialPropertyTypeNone
                              metalKitTextureLoader:textureLoader
                                        materialData:nil];

        _textures[AAPLTextureIndexAmbientOcclusion] =
            [AAPLSubmesh createMetalTextureFromMaterial:modelIOSubmesh.material
                                modelIOMaterialSemantic:MDLMaterialSemanticAmbientOcclusion
                                    modelIOMaterialType:MDLMaterialPropertyTypeNone
                                  metalKitTextureLoader:textureLoader
                                           materialData:nil];
    }
    return self;
}

@end

@implementation AAPLMesh
{
    NSMutableArray<AAPLSubmesh *> *_submeshes;
}

@synthesize submeshes = _submeshes;

/// Load the Model I/O mesh, including vertex data and submesh data which have index buffers and
///   textures.  Also generate tangent and bitangent vertex attributes
- (nonnull instancetype) initWithModelIOMesh:(nonnull MDLMesh *)modelIOMesh
                     modelIOVertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
                       metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
                                 metalDevice:(nonnull id<MTLDevice>)device
                                       error:(NSError * __nullable * __nullable)error
{
    self = [super init];
    if(!self) {
        return nil;
    }

    [modelIOMesh addNormalsWithAttributeNamed:MDLVertexAttributeNormal
                       creaseThreshold:0.98];

    // Have Model I/O create the tangents from mesh texture coordinates and normals
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                              normalAttributeNamed:MDLVertexAttributeNormal
                                             tangentAttributeNamed:MDLVertexAttributeTangent];

    // Have Model I/O create bitangents from mesh texture coordinates and the newly created tangents
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                             tangentAttributeNamed:MDLVertexAttributeTangent
                                           bitangentAttributeNamed:MDLVertexAttributeBitangent];

    // Assigning a new vertex descriptor to a ModelIO mesh performs a re-layout of the vertex
    // vertex data.  In this case, rthe renderer created the ModelIO vertex descriptor so that the
    // layout of the vertices in the ModelIO mesh match the layout of vertices the Metal render
    // pipeline expects as input into its vertex shader

    // Note ModelIO must create tangents and bitangents (as done above) before this relayout occur
    // This is because Model IO's addTangentBasis methods only works with vertex data is all in
    // 32-bit floating-point.  The vertex descriptor applied, changes those floats into 16-bit
    // floats or other types from which ModelIO cannot produce tangents

    modelIOMesh.vertexDescriptor = vertexDescriptor;

    // Create the MetalKit mesh which will contain the Metal buffer(s) with the mesh's vertex data
    //   and submeshes with info to draw the mesh
    MTKMesh* metalKitMesh = [[MTKMesh alloc] initWithMesh:modelIOMesh
                                                   device:device
                                                    error:error];

    _metalKitMesh = metalKitMesh;

    // There should always be the same number of MetalKit submeshes in the MetalKit mesh as there
    //   are Model I/O submeshes in the Model I/O mesh
    assert(metalKitMesh.submeshes.count == modelIOMesh.submeshes.count);

    // Create an array to hold this AAPLMesh object's AAPLSubmesh objects
    _submeshes = [[NSMutableArray alloc] initWithCapacity:metalKitMesh.submeshes.count];

    // Create an AAPLSubmesh object for each submesh and a add it to the submesh's array
    for(NSUInteger index = 0; index < metalKitMesh.submeshes.count; index++)
    {
        // Create an app specific submesh to hold the MetalKit submesh
        AAPLSubmesh *submesh =
            [[AAPLSubmesh alloc] initWithModelIOSubmesh:modelIOMesh.submeshes[index]
                                        metalKitSubmesh:metalKitMesh.submeshes[index]
                                  metalKitTextureLoader:textureLoader]; 

        [_submeshes addObject:submesh];
    }

    return self;
}

/// Traverses the Model I/O object hierarchy picking out Model I/O mesh objects and creates Metal
///   vertex buffers, index buffers, and textures from them
+ (NSArray<AAPLMesh*> *) newMeshesFromObject:(nonnull MDLObject*)object
                     modelIOVertexDescriptor:(nonnull MDLVertexDescriptor*)vertexDescriptor
                       metalKitTextureLoader:(nonnull MTKTextureLoader *)textureLoader
                                 metalDevice:(nonnull id<MTLDevice>)device
                                       error:(NSError * __nullable * __nullable)error {

    NSMutableArray<AAPLMesh *> *newMeshes = [[NSMutableArray alloc] init];

    // If this Model I/O  object is a mesh object (not a camera, light, or something else),
    // create an app-specific AAPLMesh object from it
    if ([object isKindOfClass:[MDLMesh class]])
    {
        MDLMesh* mesh = (MDLMesh*) object;

        AAPLMesh *newMesh = [[AAPLMesh alloc] initWithModelIOMesh:mesh
                                          modelIOVertexDescriptor:vertexDescriptor
                                            metalKitTextureLoader:textureLoader
                                                      metalDevice:device
                                                            error:error];

        [newMeshes addObject:newMesh];
    }

    // Recursively traverse the Model I/O  asset hierarchy to find Model I/O  meshes that are children
    //   of this Model I/O  object and create app-specific AAPLMesh objects from those Model I/O meshes
    for (MDLObject *child in object.children)
    {
        NSArray<AAPLMesh*> *childMeshes;

        childMeshes = [AAPLMesh newMeshesFromObject:child
                            modelIOVertexDescriptor:vertexDescriptor
                              metalKitTextureLoader:textureLoader
                                        metalDevice:device
                                              error:error];

        [newMeshes addObjectsFromArray:childMeshes];
    }

    return newMeshes;
}

/// Uses Model I/O to load a model file at the given URL, create Model I/O vertex buffers, index buffers
///   and textures, applying the given Model I/O vertex descriptor to layout vertex attribute data
///   in the way that the Metal vertex shaders expect.
+ (nullable NSArray<AAPLMesh *> *) newMeshesFromURL:(nonnull NSURL *)url
                            modelIOVertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
                                        metalDevice:(nonnull id<MTLDevice>)device
                                              error:(NSError * __nullable * __nullable)error
{

    // Create a MetalKit mesh buffer allocator so that Model I/O  will load mesh data directly into
    //   Metal buffers accessible by the GPU
    MTKMeshBufferAllocator *bufferAllocator =
        [[MTKMeshBufferAllocator alloc] initWithDevice:device];

    // Use ModelIO to load the model file at the URL.  This returns a ModelIO asset object, which
    // contains a hierarchy of ModelIO objects composing a "scene" described by the model file.
    // This hierarchy may include lights, cameras, but, most importantly, mesh and submesh data
    // rendered with Metal
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:url
                                   vertexDescriptor:nil
                                    bufferAllocator:bufferAllocator];

    NSAssert(asset, @"Failed to open model file with given URL: %@", url.absoluteString);

    // Create a MetalKit texture loader to load material textures from files or the asset catalog
    //   into Metal textures
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:device];

    NSMutableArray<AAPLMesh *> *newMeshes = [[NSMutableArray alloc] init];

    // Traverse the Model I/O asset hierarchy to find Model I/O meshes and create app-specific
    //   AAPLMesh objects from those Model I/O meshes
    for(MDLObject* object in asset)
    {
        NSArray<AAPLMesh *> *assetMeshes;

        assetMeshes = [AAPLMesh newMeshesFromObject:object
                            modelIOVertexDescriptor:vertexDescriptor
                              metalKitTextureLoader:textureLoader
                                        metalDevice:device
                                              error:error];

        [newMeshes addObjectsFromArray:assetMeshes];
    }

    return newMeshes;
}

+ (nullable AAPLMesh *)newSkyboxMeshOnDevice:(id< MTLDevice >)device
{
    MTKMeshBufferAllocator* bufferAllocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];

    MDLMesh* mdlMesh = [MDLMesh newEllipsoidWithRadii:(vector_float3){75, 75, 75}
                                       radialSegments:200
                                     verticalSegments:200
                                         geometryType:MDLGeometryTypeTriangles
                                        inwardNormals:YES
                                           hemisphere:NO
                                            allocator:bufferAllocator];

    MTLVertexDescriptor* mtlVertexDesc = [[MTLVertexDescriptor alloc] init];
    mtlVertexDesc.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    mtlVertexDesc.attributes[VertexAttributePosition].offset = 0;
    mtlVertexDesc.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

    mtlVertexDesc.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    mtlVertexDesc.attributes[VertexAttributeTexcoord].offset = 0;
    mtlVertexDesc.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;

    mtlVertexDesc.layouts[BufferIndexMeshPositions].stride = 12;
    mtlVertexDesc.layouts[BufferIndexMeshPositions].stepRate = 1;
    mtlVertexDesc.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    mtlVertexDesc.layouts[BufferIndexMeshGenerics].stride = sizeof(simd_float2);
    mtlVertexDesc.layouts[BufferIndexMeshGenerics].stepRate = 1;
    mtlVertexDesc.layouts[BufferIndexMeshGenerics].stepRate = MTLVertexStepFunctionPerVertex;

    MDLVertexDescriptor* mdlVertexDesc = MTKModelIOVertexDescriptorFromMetal( mtlVertexDesc );
    mdlVertexDesc.attributes[VertexAttributePosition].name = MDLVertexAttributePosition;
    mdlVertexDesc.attributes[VertexAttributeTexcoord].name = MDLVertexAttributeTextureCoordinate;
    mdlMesh.vertexDescriptor = mdlVertexDesc;

    __autoreleasing NSError* error;
    MTKMesh* mtkMesh = [[MTKMesh alloc] initWithMesh:mdlMesh
                                              device:device
                                               error:&error];

    NSAssert(mtkMesh, @"Error creating skybox mesh: %@", error);

    return [[AAPLMesh alloc] initWithMtkMesh:mtkMesh];

}

- (instancetype)initWithMtkMesh:(MTKMesh *)mtkMesh
{
    if ( self = [super init] )
    {
        _metalKitMesh = mtkMesh;
    }
    return self;
}

@end
