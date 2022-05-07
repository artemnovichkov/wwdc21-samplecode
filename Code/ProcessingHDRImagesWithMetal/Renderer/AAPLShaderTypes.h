/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header that contains types and enumeration constants shared between Metal shaders and C/Objective-C source.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>
#include "UIOptionEnums.h"

// --
enum AAPLBufferIndex
{
    AAPLBufferIndexVertices = 0,
    AAPLBufferIndexUniforms = 1,
    AAPLBufferIndexBytes = 2
};

// --
enum AAPLVertexAttributeIndex
{
    AAPLVertexAttributeIndexPosition = 0,
    AAPLVertexAttributeIndexNormal = 1
};

// --
enum AAPLFunctionConstantIndex
{
    AAPLFunctionConstantIndexExposureType = 0,
    AAPLFunctionConstantIndexTonemapType = 1
};

// --
typedef struct AAPLVertex
{
    vector_float3 position;
    vector_float3 normal;
} AAPLVertex;

// --
#define OBJECT_COUNT 3
typedef struct AAPLUniforms
{
    matrix_float4x4 World[OBJECT_COUNT];
    matrix_float4x4 View;
    matrix_float4x4 ViewInv;
    matrix_float4x4 Perspective;

    vector_float3 skyDomeOffsets;

    vector_float2 fullResolutionTexelOffset;

    // x: Range min, y: Range Max, z: Intensity, w: Blur Kernel scale
    vector_float4 bloomParameters;

    float manualExposureValue;
    float exposureKey;

    float tonemapWhitePoint;

    float luminanceScale;
} AAPLUniforms;

#endif /* ShaderTypes_h */
