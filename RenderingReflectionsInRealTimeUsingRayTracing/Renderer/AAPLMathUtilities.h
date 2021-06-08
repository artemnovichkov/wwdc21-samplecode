/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for vector, matrix, and quaternion math utility functions useful for 3D graphics rendering.
*/

#ifndef AAPLMathUtilities_h
#define AAPLMathUtilities_h

#import <simd/simd.h>
#import <Metal/MTLAccelerationStructureTypes.h>

matrix_float4x4 matrix4x4_translationv(vector_float3 v);

matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis);

MTLPackedFloat4x3 matrix4x4_drop_last_row( matrix_float4x4 m );

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ);

#endif //AAPLMathUtilities_h
