/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC source
*/
#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

typedef enum RTReflectionKernelImageIndex
{
    OutImageIndex                   = 0,
    ThinGBufferPositionIndex        = 1,
    ThinGBufferDirectionIndex       = 2,
    IrradianceMapIndex              = 3
} RTReflectionKernelImageIndex;

typedef enum RTReflectionKernelBufferIndex
{
    SceneIndex                      = 0,
    AccelerationStructureIndex      = 1
} RTReflectionKernelBufferIndex;

typedef enum BufferIndex
{
    BufferIndexMeshPositions        = 0,
    BufferIndexMeshGenerics         = 1,
    BufferIndexInstanceTransforms   = 2,
    BufferIndexCameraData           = 3,
    BufferIndexLightData            = 4
} BufferIndex;

typedef enum VertexAttribute
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
} VertexAttribute;

// Attribute index values shared between shader and C code to ensure Metal shader vertex
//   attribute indices match the Metal API vertex descriptor attribute indices
typedef enum AAPLVertexAttribute
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
    AAPLVertexAttributeNormal    = 2,
    AAPLVertexAttributeTangent   = 3,
    AAPLVertexAttributeBitangent = 4
} AAPLVertexAttribute;

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls
typedef enum AAPLTextureIndex
{
    AAPLTextureIndexBaseColor        = 0,
    AAPLTextureIndexMetallic         = 1,
    AAPLTextureIndexRoughness        = 2,
    AAPLTextureIndexNormal           = 3,
    AAPLTextureIndexAmbientOcclusion = 4,
    AAPLTextureIndexIrradianceMap    = 5,
    AAPLTextureIndexReflections      = 6,
    AAPLNumMeshTextureIndices = AAPLTextureIndexAmbientOcclusion+1,
} AAPLTextureIndex;

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum AAPLBufferIndex
{
    AAPLBufferIndexMeshPositions    = 0,
    AAPLBufferIndexMeshGenerics     = 1,
} AAPLBufferIndex;

typedef struct AAPLInstanceTransform
{
    matrix_float4x4 modelViewMatrix;
} AAPLInstanceTransform;

typedef struct AAPLCameraData
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    vector_float3 cameraPosition;
} AAPLCameraData;

// Structure shared between shader and C code to ensure the layout of data accessed in
//    Metal shaders matches the layout of data set in C code
typedef struct
{
    // Per Light Properties
    vector_float3 directionalLightInvDirection;
    float lightIntensity;

} AAPLLightData;

#endif /* ShaderTypes_h */

