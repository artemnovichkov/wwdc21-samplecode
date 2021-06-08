/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for common utility functions.
*/

#ifndef AAPLUtility_hpp
#define AAPLUtility_hpp

#include <simd/simd.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declarations
struct AAPLVertex;

@protocol MTLTexture;
@protocol MTLDevice;

@class NSString;
@class NSError;

// --
float lerpf(float v0, float v1, float t);

/// Helpers for converting enum values to strings
NSString * string_for_tonemap_operator_type(uint32_t typeIndex);
NSString * string_for_exposure_control_type(uint32_t typeIndex);

/// Creates an array of AAPLVertex representing postion and normals for a unit sphere
/// Caller is responsible for freeing data
struct AAPLVertex * generate_sphere_data(uint32_t * vertexCount);
void delete_sphere_data(struct AAPLVertex * data);

/// As a source of HDR input, renderer leverages radiance (.hdr) files. This helper method provides a radiance file
/// loaded into an MTLTexture given a source file name and MTLDevice
id<MTLTexture> texture_from_radiance_file(NSString * fileName, id<MTLDevice> device, NSError ** error);

#ifdef __cplusplus
}
#endif

#endif /* AAPLUtility_hpp */
