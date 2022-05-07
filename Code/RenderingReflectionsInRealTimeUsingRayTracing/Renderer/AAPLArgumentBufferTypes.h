/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types defining types used in argument buffers
*/
#ifndef AAPLArgumentBufferTypes_h
#define AAPLArgumentBufferTypes_h

typedef struct AAPLMaterialData
{
    vector_float3 baseColor;
    vector_float3 irradiatedColor;
    vector_float3 roughness;
    vector_float3 metalness;
    float         ambientOcclusion;
    float         mapWeights[AAPLNumMeshTextureIndices];
} AAPLMaterialData;

#if __METAL_VERSION__

#include <metal_stdlib>
using namespace metal;

struct MeshGenerics
{
    float2 tc [[id(0)]];
    half4 normal [[id(1)]];
    half4 tangent [[id(2)]];
    half4 bitangent [[id(3)]];
};

struct Material
{
    texture2d< float > textureMap [[id(0)]];
    //texture2d< float > metallic;
    //texture2d< float > roughness;
    //texture2d< float > normal;
    //texture2d< float > occlusion;
};

struct Submesh
{

    // Positions and generic vertex attributes stored in container mesh.
    // packed_float3* positions;
    // MeshGenerics* generics;

    // Indices into the container mesh's position and generics arrays
    constant uint32_t* indices [[id(0)]];

    // Array of Material
    constant Material* materials [[id(1)]];
    constant AAPLMaterialData* pMaterialData [[id(2)]]; // pointer to material data
};

struct Mesh
{
   constant packed_float3* positions [[id(0)]];
   constant MeshGenerics* generics [[id(1)]];

    // Array of Submeshs
   constant Submesh* submeshes [[id(2)]];
};

struct Instance
{
    constant Mesh* pMesh [[id(0)]]; // references a single Mesh
    float4x4 transform;
};

struct Scene
{
    constant Instance* instances [[id(0)]]; // array of Instance
};

#endif // __METAL_VERSION__

#endif // ArgumentBufferTypes_h
