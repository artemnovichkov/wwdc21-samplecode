/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Geometry shader for handling seaweed movement.
*/
#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;

float3 noise3D(float3 worldPos, float time) {
    float spatialScale = 8.0;
    return float3(sin(spatialScale * 1.1 * (worldPos.x + time)),
                  sin(spatialScale * 1.2 * (worldPos.y + time)),
                  sin(spatialScale * 1.2 * (worldPos.z + time)));
}

[[visible]]
void seaweedGeometry(realitykit::geometry_parameters params)
{
    float3 worldPos = params.geometry().world_position();

    float phaseOffset = 3.0 * dot(params.geometry().world_position(), float3(1.0, 0.5, 0.7));
    float time = 0.1 * params.uniforms().time() + phaseOffset;
    float amplitude = 0.05;
    float3 maxOffset = noise3D(worldPos, time);
    float3 offset = maxOffset * amplitude * max(0.0, params.geometry().model_position().y);
    params.geometry().set_model_position_offset(offset);
}
