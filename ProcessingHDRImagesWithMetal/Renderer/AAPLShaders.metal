/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample.
*/

#include <metal_stdlib>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#include "AAPLShaderTypes.h"

namespace
{

// Relative luminance for sRGB Primaries.
constant half3 kRec709Luma(.2126f,.7152f,.0722f);

// --
constexpr sampler linearFilterSampler(coord::normalized, address::clamp_to_edge, filter::linear);

// Define a triangle in clip space to be clipped perfectly to the viewport, resulting in a Full Screen Quad (FSQ)
constant float4 FSQPositions[] = { float4(-1.f, 1.f, 0.f, 1.f), float4( 3.f, 1.f, 0.f, 1.f), float4(-1.f, -3.f, 0.f, 1.f) };
constant float2 FSQTexCoords[] = { float2(0.f, 0.f), float2(2.f, 0.f), float2(0.f, 2.f) };

// --
constant float2 kSkyDomeDirections[] = { float2(-1.f, 1.f), float2(1.f, 1.f), float2(-1.f, -1.f), float2(1.f, 1.f), float2(1.f, -1.f), float2(-1.f, -1.f)};

// Helper for equirectangular textures
half4 EquirectangularSample(float3 direction, sampler s, texture2d<half> image)
{
    float3 d = normalize(direction);

    float2 t = float2((atan2(d.z, d.x) + M_PI_F) / (2.f * M_PI_F), acos(d.y) / M_PI_F);

    return image.sample(s, t);
}

// Maximum value for HDR samples (prevent Inf samples from source HDR textures)
constant float kHDRMaxValue = 500.f;

// Avoid negative infinity when calculating luminance at a black pixel
constant float kLuminanceEpsilon = .001f;

//---------------
// Scene Exposure

// For managing shader variations across exposure control modes
constant uint32_t kExposureModeIndex [[function_constant(AAPLFunctionConstantIndexExposureType)]];

//Sample high level mipmap and apply exp()
half KeyExposureCoefficient(float averageLogLuminance, float key)
{
    return key / exp(averageLogLuminance);
}

// Manual exposure ignores average luminance and, instead, applies
// a direct pow function
half ManualExposureCoefficient(float exposureValue)
{
    return pow(2.f, exposureValue);
}

//------------------------------
// Blur support data and methods

struct GaussSample
{
    float2 offset;
    float weight;
};


// Gaussian sampline matrix
constant GaussSample GaussKernelX[] =
{
    {{-2.06278f, 0.f}, 0.05092f},
    {{-0.53805f, 0.f}, 0.44908f},
    {{ 0.53805f, 0.f}, 0.44908f},
    {{ 2.06278f, 0.f}, 0.05092f}
};
constant size_t GAUSS_KERNEL_SIZE_X = sizeof(GaussKernelX) / sizeof(GaussKernelX[0]);

constant GaussSample GaussKernelY[] =
{
    {{0.f, -2.06278f}, 0.05092f},
    {{0.f, -0.53805f}, 0.44908f},
    {{0.f,  0.53805f}, 0.44908f},
    {{0.f,  2.06278f}, 0.05092f}
};

constant size_t GAUSS_KERNEL_SIZE_Y = sizeof(GaussKernelY) / sizeof(GaussKernelY[0]);

// Horizontal pass
half3 BlurredSampleX(texture2d<half> texture, sampler samp, float2 texCoords, float2 texelOffset, float kernelScale)
{
    half3 finalColor = half3(0.f);

    float totalWeight = 0.f;

    for(uint32_t gaussSampleIdx = 0ul; gaussSampleIdx < ::GAUSS_KERNEL_SIZE_X; ++gaussSampleIdx)
    {
        constant GaussSample & gaussSample = ::GaussKernelX[gaussSampleIdx];

        float2 sampleCoord = saturate(texCoords + (gaussSample.offset * texelOffset * kernelScale));
        finalColor += texture.sample(samp, sampleCoord).xyz * gaussSample.weight;
        totalWeight += gaussSample.weight;
    }

    return finalColor / totalWeight;
}

// Vertical pass
half3 BlurredSampleY(texture2d<half> texture, sampler samp, float2 texCoords, float2 texelOffset, float kernelScale)
{
    half3 finalColor = half3(0.f);

    float totalWeight = 0.f;

    for(uint32_t gaussSampleIdx = 0ul; gaussSampleIdx < ::GAUSS_KERNEL_SIZE_Y; ++gaussSampleIdx)
    {
        constant GaussSample & gaussSample = ::GaussKernelY[gaussSampleIdx];

        float2 sampleCoord = saturate(texCoords + (gaussSample.offset * texelOffset * kernelScale));
        finalColor += texture.sample(samp, sampleCoord).xyz * gaussSample.weight;
        totalWeight += gaussSample.weight;
    }

    return finalColor / totalWeight;
}

//------------
// Tonemapping

// For managing shader variations across tonemapping operators
constant uint32_t kTonemapModeIndex [[function_constant(AAPLFunctionConstantIndexTonemapType)]];

// Notes on the math for the following tonemapping operators:
//
// The following operators are defined in terms of luminance, therefore some work must be done
// to determine the final color's scale factor.
//
// Operator represents the input color as vector S and luminance vector R, then computes input
// color luminance L by calculating the dot product of S and R:
//
//   L = S・R
//
// Using L, operator calculates the desired luminance L' using the tonemapping operator T(x) such that:
//
//   L' = T(L)
//
// Operator determines the scalar value K such that:
//
//  KS・R = L'
//
// By leveraging the scalar multiplication property of dot products, this is rewritten as:
//
//   K(S・R) = L'
//
// Substituting L, given it's initial definition:
//
//   KL = L'
//
// Thus
//
//   K = L' / L
//
// For any tone mapping operator T(x) which operates on Luminance, the color scaling factor K is:
//
//   K = T(L) / L

// Equation 1
half3 RinehardOperator(half3 srcColor, float luminanceScale)
{
    float luminance = dot(srcColor, ::kRec709Luma) + kLuminanceEpsilon;
    float targetLuminance = 1.f / (1.f + luminance);
    return srcColor * targetLuminance * luminanceScale;
}

// Equation 2
half3 RinehardExOperator(half3 srcColor, half luminanceWhitePoint, float luminanceScale)
{
    float luminance = dot(srcColor, ::kRec709Luma) + kLuminanceEpsilon;

    float targetLuminance = luminance * (1.f + (luminance / (luminanceWhitePoint * luminanceWhitePoint)));

    targetLuminance /= 1.f + luminance;

    targetLuminance *= luminanceScale;

    return srcColor * (targetLuminance / luminance);
}

}// anonymous namespace

#pragma mark -
#pragma mark Scene Geometry

// --
struct VertexIn
{
    float3 position [[attribute(AAPLVertexAttributeIndexPosition)]];
    float3 normal [[attribute(AAPLVertexAttributeIndexNormal)]];
};

// --
struct GeometryVertexOut
{
    float4 position [[position]];
    float3 normal;
    float3 viewPosition;
    float3 refl;
};

// --
vertex GeometryVertexOut GeometryVertex(const uint vertexID [[ vertex_id ]],
                                        const uint instanceID [[instance_id]],
                                        const VertexIn input [[stage_in]],
                                        const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    matrix_float4x4 worldView = uniforms.View * uniforms.World[instanceID];

    GeometryVertexOut out;

    float3 cameraPosition = uniforms.ViewInv.columns[3].xyz;
    out.refl = reflect(normalize(input.position - cameraPosition), input.normal);

    // Store the view-space position.
    out.viewPosition = (worldView * float4(input.position, 1.f)).xyz;

    // Store the clip space position (Standard required output).
    out.position = uniforms.Perspective * float4(out.viewPosition, 1.f);

    // Rotate the normal into view space (No need to use the inverse transpose, WorldMtx is an ortho-normal matrix).
    out.normal = normalize(worldView * float4(input.normal, 0.f)).xyz;

    return out;
}

// Blinn-Phong
fragment half4 GeometryFragment(GeometryVertexOut input [[stage_in]],
                                 texture2d<half> imageIn [[texture(0)]],
                                 const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    half3 c = ::EquirectangularSample(normalize(input.refl), ::linearFilterSampler, imageIn).rgb;
    return half4(clamp(c, 0.f, kHDRMaxValue), 1.f);
}

#pragma mark -
#pragma mark Sky Dome

// --
struct SkyDomeVertexOut
{
    float4 position [[position]];
    float3 sampleDirection;
};

// --
vertex SkyDomeVertexOut SkyDomeVertex(const uint vertexID [[vertex_id]],
                                      const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    SkyDomeVertexOut output;

    float2 skyDomeDirection = ::kSkyDomeDirections[vertexID];
    output.position = float4(skyDomeDirection, .9999f, 1);

    float3 sampleDirection = float3(0);

    sampleDirection.x = skyDomeDirection.x * uniforms.skyDomeOffsets.x;
    sampleDirection.y = skyDomeDirection.y * uniforms.skyDomeOffsets.y;
    sampleDirection.z = uniforms.skyDomeOffsets.z;

    output.sampleDirection = (uniforms.ViewInv * float4(sampleDirection, 1.f)).xyz;

    return output;
}

// --
fragment half4 SkyDomeFragment(SkyDomeVertexOut input [[stage_in]],
                                texture2d<half> imageIn [[texture(0)]])
{
    half3 c = ::EquirectangularSample(input.sampleDirection, ::linearFilterSampler, imageIn).rgb;
    return half4(clamp(c, 0.f, kHDRMaxValue), 1.f);
}

#pragma mark -
#pragma mark Post Process

#pragma mark Standard Full Screen Quad (FSQ) Vertex Processing

//--------------------------------------------------------------
// For the full screen image processing passes (post processing)

// Vertex shader outputs and per-fragment inputs.  Includes clip-space position and vertex outputs
// interpolated by rasterizer and fed to each fragment generated by clip-space primitives.
struct FSQVertexOut
{
    float4 position [[position]];
    float2 texCoord;
};

// This works with a corresponding call to drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3].
//   We treat each vertex ID as an array index for our predefined clip-space positions.
vertex FSQVertexOut FSQVertex(const uint vertexID  [[ vertex_id ]],
                              const device uint &bloomIndex [[buffer(AAPLBufferIndexBytes)]])
{
    FSQVertexOut out;

    out.position = ::FSQPositions[vertexID];
    out.texCoord = ::FSQTexCoords[vertexID];

    return out;
}

#pragma mark Scene Exposure

// Scene Luminance
// log average luminance:
//   average:luminance := exp(avg(log(delta + lum(rgb))))
//   Where
//   lum(rgb) := r * .2126f + g * .7152f + b * .0722f := dot(rgb, float3(.2126f,.7152f,.0722f))
//
// Computing Average Log Luminance will happen in 3 steps:
//   1. Store log(delta + lum(rgb)) for each pixel
//   2. Generate mip chain -> average will be stored in highest mip level
//   3. Sample max mip level and apply exp() for final average luminance result

// Step 1: Store log(delta + lum(rgb))
fragment half LogLuminanceFragment(FSQVertexOut input [[ stage_in ]],
                                    texture2d<half> imageIn [[texture(0)]])
{
    half luminance = dot(imageIn.sample(::linearFilterSampler, input.texCoord).rgb, ::kRec709Luma) + ::kLuminanceEpsilon;
    return log(luminance);
}

// Step 2: Handled in ObjC by creating a Blit command encoder and calling generateMipmapsForTexture

// Step 3: Compute final exposure - handled between bloom init and bloom composite passes

#pragma mark Bloom

//------
// Bloom

// Vertex shader outputs and per-fragment inputs.  Includes clip-space position and vertex outputs
// interpolated by rasterizer and fed to each fragment generated by clip-space primitives.
struct BloomVertexOut
{
    float4 position [[position]];
    float2 texCoord;
    float srcTexelScale;
};

// Similar to FSQVertex function, but additionally a constant which represents how much to scale
// texel offsets based upon relative source target size.
vertex BloomVertexOut BloomVertex(const uint vertexID  [[ vertex_id ]],
                                  const device float &srcTexelScale [[buffer(AAPLBufferIndexBytes)]])
{
    BloomVertexOut out;

    out.position = ::FSQPositions[vertexID];
    out.texCoord = ::FSQTexCoords[vertexID];

    // Each bloom pass will send a texel scale value to calculate the correct offset into the source
    // texture.  This makes it easier for the app to control bloom pass count and quality.
    out.srcTexelScale = srcTexelScale;

    return out;
}

#pragma mark Blur Kernels

// ------------------
// Separable Gaussian

// Perform initial blur and thresholding operation.
fragment half4 BloomSetup(BloomVertexOut input [[ stage_in ]],
                           texture2d<half> imageIn [[texture(0)]],
                           texture2d<half> logLuminanceIn [[texture(1), function_constant(::kExposureModeIndex)]],
                           const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    // When determining the portions of the screen that are bright enough to trigger bloom,
    //  it's most sensible to do this once scaling for exposure has been applied.
    float exposureCoefficient = 1.f;

    switch (::kExposureModeIndex)
    {
        case kExposureControlTypeKey:
        {
            constexpr sampler mipSampler(filter::linear, mip_filter::linear, lod_clamp(MAXFLOAT,MAXFLOAT));
            exposureCoefficient = ::KeyExposureCoefficient(logLuminanceIn.sample(mipSampler, input.texCoord).r, uniforms.exposureKey);
        }
        break;

        case kExposureControlTypeManual:
            exposureCoefficient = ::ManualExposureCoefficient(uniforms.manualExposureValue);
            break;

        default:
            break;
    }

    // Start the bloom process by blurring in the X direction.
    // Note that the input to the Y direction blur will be the output of the X direction blur,
    // So it's only necessary to filter luminance in this first pass.
    half3 blur = exposureCoefficient * ::BlurredSampleX(imageIn,
                                                         ::linearFilterSampler,
                                                         input.texCoord,
                                                         uniforms.fullResolutionTexelOffset * input.srcTexelScale,
                                                         uniforms.bloomParameters.w);

    // Blend in blurred values with smoothstep based upon app controlled luminance range.
    float luminance = dot(blur, normalize(::kRec709Luma));
    half3 finalColor = blur * smoothstep(uniforms.bloomParameters.x, uniforms.bloomParameters.y, luminance);

    return half4(finalColor, 1.f);
}

// Horizontal blur for separable gaussian passes
fragment half4 BloomBlurX(BloomVertexOut input [[ stage_in ]],
                           texture2d<half> imageIn [[texture(0)]],
                           const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    half3 blur = ::BlurredSampleX(imageIn,
                                   ::linearFilterSampler,
                                   input.texCoord,
                                   uniforms.fullResolutionTexelOffset * input.srcTexelScale,
                                   uniforms.bloomParameters.w);
    return half4(blur, 1.f);
}

// Vertical blur for separable gaussian passes
fragment half4 BloomBlurY(BloomVertexOut input [[ stage_in ]], texture2d<half> imageIn [[texture(0)]],
                           const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    half3 blur = ::BlurredSampleY(imageIn,
                                   ::linearFilterSampler,
                                   input.texCoord,
                                   uniforms.fullResolutionTexelOffset * input.srcTexelScale,
                                   uniforms.bloomParameters.w);
    return half4(blur, 1.f);
}

#pragma mark Post Process Composite

// This fragment function is meant to be applied as the final pass in the post processing pipeline.
//
// It composites the bloom result with the render result and feeds that composite result into the
// selected tonemapping operator.
fragment half4 PostProcessComposite(FSQVertexOut input [[ stage_in ]],
                                     texture2d<half> hdrSceneImage [[texture(0)]],
                                     texture2d<half> bloomResult [[texture(1)]],
                                     texture2d<half> logLuminanceIn [[texture(2), function_constant(::kExposureModeIndex)]],
                                     const device AAPLUniforms& uniforms [[buffer(AAPLBufferIndexUniforms)]])
{
    // In the first step, scene result is sampled and exposure is applied. (Controlled via function constant)
    half exposureCoefficient = 1.f;
    switch (::kExposureModeIndex)
    {
        case kExposureControlTypeKey:
        {
            constexpr sampler mipSampler(filter::linear, mip_filter::linear, lod_clamp(MAXFLOAT,MAXFLOAT));
            exposureCoefficient = ::KeyExposureCoefficient(logLuminanceIn.sample(mipSampler, input.texCoord).r, uniforms.exposureKey);
            break;
        }

        case kExposureControlTypeManual:
        {
            exposureCoefficient = ::ManualExposureCoefficient(uniforms.manualExposureValue);
            break;
        }

        default:
            break;
    }

    half3 finalColor = exposureCoefficient * hdrSceneImage.sample(::linearFilterSampler, input.texCoord).rgb;

    // Sum with bloom result. Note that the bloom result has already been scaled for exposure: See BloomInit().
    finalColor += bloomResult.sample(::linearFilterSampler, input.texCoord).rgb * uniforms.bloomParameters.z;

    // Finally, apply the selected tonemapping operator. (Controlled via function constant)
    switch (::kTonemapModeIndex)
    {
        case kTonemapOperatorTypeReinhard:
        {
            finalColor = ::RinehardOperator(finalColor, uniforms.luminanceScale);
            break;
        }

        case kTonemapOperatorTypeReinhardEx:
        {
            finalColor = ::RinehardExOperator(finalColor, uniforms.tonemapWhitePoint, uniforms.luminanceScale);
            break;
        }

        default:
            break;
    }

    return half4(finalColor, 1.f);
}
