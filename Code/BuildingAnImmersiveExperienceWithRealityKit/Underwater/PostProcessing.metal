/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal postprocessing shaders.
*/

#include <metal_stdlib>

using namespace metal;

constant int renderMode [[function_constant(0)]];
constant bool withCaustics [[function_constant(1)]];
constant bool useColorRamp [[function_constant(2)]];

// Note: If you make changes here, you must also make the same change to
// PostProcessing.swift, otherwise everything will be green.
struct InputArgs
{
    float4x4 viewMatrixInverse;
    float4x4 viewMatrix;
    float4 viewTranslation;
    float4 topLeft;
    float4 topRight;
    float4 bottomLeft;
    float4 bottomRight;
    float time;
    float2x2 orientationTransform;
    float2 orientationOffset;
    float fogIntensity = 5;
    float fogFalloff = 2;
    float fogExponent = 0.3;
    float causticStrength = 0.3;
    float causticAddition = 0.1;
    float causticWaveScale;
    float causticWaveSpeed;
    float causticsOrientation;
    float causticSlope;
    float4 fogColor;

    // Must be last.
    uint8_t validityCheck;
};

float linearizeDepth(float sampleDepth, float4x4 viewMatrix)
{
    constexpr float kDepthEpsilon = 1e-5f;
    float d = max(kDepthEpsilon, sampleDepth);
    // Linearize (we have reverse infinite projection);
    d = abs(-viewMatrix[3][2] / d);
    return d;
}

float unlinearizeDepth(float linearDepth, float4x4 viewMatrix)
{
    return linearDepth / -viewMatrix[3][2];
}

float3 getDirection(float2 screenCoord, constant InputArgs *args)
{
    float3 top = mix(args->topLeft.xyz, args->topRight.xyz, screenCoord.x);
    float3 bottom = mix(args->bottomLeft.xyz, args->bottomRight.xyz, screenCoord.x);
    return normalize(mix(bottom, top, screenCoord.y));
}

float3 worldCoordsForDepth(float depth, float2 screenCords,
                           constant InputArgs *args)
{
    float3 centerDirection = getDirection(float2(0.5, 0.5), args);
    float3 direction = getDirection(screenCords, args);
    // The depth is actually in the direction of the center, not the direction of the ray.
    float depth2 = depth / dot(direction, centerDirection);
    return direction * depth2 + args->viewTranslation.xyz;
}

constexpr sampler causticSampler(metal::coord::normalized, metal::address::repeat, metal::filter::linear, metal::mip_filter::nearest);

half wavePattern2(texture2d<half, access::sample> cellNoiseTex, float2 uv, half scale, float scroll, float2 scrollDir)
{
    float2 scaledUV = (uv * scale + scroll * scrollDir);
    half cellStrength = cellNoiseTex.sample(causticSampler, scaledUV).r;

    return cellStrength;
}

float3x3 rotationY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3x3( c,  0,  s,
                     0,  1,  0,
                    -s,  0,  c);
}

float3x3 rotationZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float3x3( c, -s,  0,
                     s,  c,  0,
                     0,  0,  1);
}

half4 causticNoise(float3 worldCoords,
                   constant InputArgs *args,
                   texture2d<half, access::sample> cellNoiseTex)
{
    float2 uv = (rotationZ(args->causticSlope) * rotationY(args->causticsOrientation) * worldCoords).xz;

    half wave = wavePattern2(cellNoiseTex, uv, 10.0 * args->causticWaveScale, args->time * args->causticWaveSpeed, float2(1.0, 0.0) * args->causticWaveScale);
    half wave2 = wavePattern2(cellNoiseTex, uv , 11.0 * args->causticWaveScale, args->time * args->causticWaveSpeed, float2(-1.0, 0.25) * args->causticWaveScale);
    half wave3 = wavePattern2(cellNoiseTex, uv, 7.0 * args->causticWaveScale, args->time * 0.15 * args->causticWaveSpeed, float2(1.0, 1.0) * args->causticWaveScale);

    half finalWave = pow(wave2*wave, wave3+3.15h) * 100.0;
    return half4(finalWave, finalWave, finalWave, 1.0);
}

float debug3DPattern(float3 pos) {
    float frequency = 4.0;
    float grid = (sin(pos.x * frequency) + sin(pos.y * frequency) + sin(pos.z * frequency)) / 3;
    grid = sin(32.0 * grid);
    grid = grid * 8.0 + 0.5;
    grid = max(0.0, min(1.0, grid));
    return grid;
}

constexpr sampler textureSampler(address::clamp_to_edge, filter::bicubic);

float getDepth(float2 coords,
               constant InputArgs *args,
               texture2d<float, access::sample> inDepth,
               depth2d<float, access::sample> arDepth)
{
    float2 arDepthCoords = args->orientationTransform * coords + args->orientationOffset;

    float realDepth = arDepth.sample(textureSampler, arDepthCoords);
    float virtualDepth = linearizeDepth(inDepth.sample(textureSampler, coords)[0], args->viewMatrix);
    bool realFragment = (virtualDepth <= FLT_EPSILON);
    if (realFragment) { virtualDepth = realDepth; }

    return min(virtualDepth, realDepth);
}

[[kernel]]
void postProcess(uint2 gid [[thread_position_in_grid]],
                 constant InputArgs *args [[buffer(0)]],
                 texture2d<half, access::read> inColor [[texture(0)]],
                 texture2d<float, access::sample> inDepth [[texture(1)]],
                 texture2d<half, access::write> outColor [[texture(2)]],
                 depth2d<float, access::sample> arDepth [[texture(3)]],
                 texture2d<half, access::sample> colorRamp [[texture(4)]],
                 texture2d<float, access::sample> mixingRamp [[texture(5)]],
                 texture2d<half, access::sample> cellNoise [[texture(6)]])
{
    float2 screenCoords = float2(float(gid[0]) / float(outColor.get_width()),
                                 float(gid[1]) / float(outColor.get_height()));

    float rawDepth = getDepth(screenCoords, args, inDepth, arDepth);

    float3 worldCoords = worldCoordsForDepth(rawDepth, screenCoords, args);

    float fogIntensity = args->fogIntensity;

    float depth = rawDepth;
    depth = 1 - pow(1 / (pow(depth, fogIntensity) + 1), args->fogFalloff);
    depth = clamp(depth, 0.0, 1.0);

    half4 color = half4(0.0);

    if (renderMode == 0) { // Final

        float blend = pow(1 - depth, args->fogExponent);

        half4 nearColor = inColor.read(gid);// * half4(0.427, 0.969, 1.0, 1.0);

        half4 fogColor = useColorRamp ? colorRamp.sample(textureSampler, float2(1 - depth, 0.5)) : half4(args->fogColor);

        if (withCaustics) {
            half4 caustics = causticNoise(worldCoords, args, cellNoise);

            // Caustics.
            half4 causticsColor = caustics * nearColor + args->causticAddition * caustics * half4(1.0);
            nearColor = nearColor + args->causticStrength * causticsColor;
        }

        color = blend * nearColor + (1 - blend) * fogColor;

    } else if(renderMode == 1) { // None

        color = inColor.read(gid);

    } else if (renderMode == 2) { // Depth

        float offset = 1.0;
        float depth2 = 1 / (depth + offset) - 1 / offset;
        color = half4(0.5 + 0.5 * sin((depth2 + 0.0/3) * 2 * M_PI_F),
                      0.5 + 0.5 * sin((depth2 + 1.0/3) * 2 * M_PI_F),
                      0.5 + 0.5 * sin((depth2 + 2.0/3) * 2 * M_PI_F),
                      1.0);

    } else if (renderMode == 3) { // Position

        worldCoords *= 2.0;
        color = half4(debug3DPattern(worldCoords));

    } else if (renderMode == 4) { // God Rays

        float4 rayDensity = 0;
        float marchingDepth = 0;
        size_t iterationCount = 32;
        for (size_t i = 0; i < iterationCount; i++) {
            marchingDepth += 0.2;
            if (marchingDepth >= rawDepth) { break; }
            float3 worldCoords = worldCoordsForDepth(marchingDepth, screenCoords, args);
            rayDensity += max(0.0, float4(causticNoise(worldCoords, args, cellNoise)));
        }
        rayDensity /= float(iterationCount);
        color = half4(rayDensity);

    } else if (renderMode == 5) { // Direction

        float3 direction = getDirection(screenCoords, args);
        float grid = debug3DPattern(4.0 * direction);
        color = half4(half3((0.5 * direction + float3(0.5)) * grid), 1.0);

    } else if (renderMode == 6) { // Normals

        float offsetX = 1.2 / float(inDepth.get_width());
        float offsetY = 1.2 / float(inDepth.get_height());
        float dx = getDepth(float2(screenCoords.x + offsetX, screenCoords.y), args, inDepth, arDepth)
                 - getDepth(float2(screenCoords.x - offsetX, screenCoords.y), args, inDepth, arDepth);
        float dy = getDepth(float2(screenCoords.x, screenCoords.y + offsetY), args, inDepth, arDepth)
                 - getDepth(float2(screenCoords.x, screenCoords.y - offsetY), args, inDepth, arDepth);
        dx /= 2 * offsetX;
        dy /= 2 * offsetY;
        float dz = sqrt(1 - dx * dx + dy * dy);
        float3 normal = normalize(float3(dx, dy, dz));
        color = half4(half3(normal + float3(1.0)) / 2.0, 1.0);

    } else { // Invalid option

        // Red
        color = half4(1.0, 0.0, 0.0, 1.0);
    }

    if (args->validityCheck == 42) { // Debug check to make sure that the args are properly passed.
        outColor.write(color, gid);
    } else {
        // Green
        outColor.write(half4(0.0, 1.0, 0.0, 1.0), gid);
    }
}
