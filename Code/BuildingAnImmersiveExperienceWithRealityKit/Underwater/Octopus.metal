/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Metal code for the custom surface shader of the octopus
*/

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

using namespace metal;

constexpr sampler samplerBilinear(coord::normalized,
                                 address::repeat,
                                 filter::linear,
                                 mip_filter::nearest);

void octopusBlend(float time,
                  half3 masks,
                  thread half &blend,
                  thread half &colorBlend)
{
    half noise = masks.r;
    half gradient = masks.g;
    half mask = masks.b;

    half transition = (sin(time * 1.0) + 1) / 2;
    transition = saturate(transition);

    blend = 2 * transition - (noise + gradient) / 2;
    blend = 0.5 + 4.0 * (blend - 0.5); // More contrast
    blend = saturate(blend);
    blend = max(blend, mask);
    blend = 1 - blend;

    colorBlend = min(blend, mix(blend, 1 - transition, 0.8h));
}

void octopusBlend(realitykit::surface_parameters params,
                  thread float &blend,
                  thread float &colorBlend)
{
    float2 uv = params.geometry().uv0();
    uv.y = 1.0 - uv.y;

    float3 masks = float3(params.textures().custom().sample(samplerBilinear, uv).rgb);
    float noise = masks.r;
    float gradient = masks.g;
    float mask = masks.b;

    float transition = (sin(params.uniforms().time() * 1.0) + 1) / 2;
    transition = saturate(transition);
    //transition = 1 - pow(1 - pow(transition, 2.0), 2.0); // smoother derivatives

    blend = 2 * transition - (noise + gradient) / 2;
    blend = 0.5 + 4.0 * (blend - 0.5); // more contrast
    blend = saturate(blend);
    blend = max(blend, mask);
    blend = 1 - blend;

    colorBlend = min(blend, mix(blend, 1 - transition, 0.8));
}

[[visible]]
void octopusSurface(realitykit::surface_parameters params)
{

    auto tex = params.textures();
    auto surface = params.surface();
    float2 uv = params.geometry().uv0();

    int stage = 11;//int(params.uniforms().custom_parameter()[0]);

    // USD textures require uvs to be flipped.
    uv.y = 1.0 - uv.y;

    half3 mask = tex.custom().sample(samplerBilinear, uv).rgb;

    half blend, colorBlend;
    octopusBlend(params.uniforms().time(), mask, blend, colorBlend);

    if (stage-- <= 0) { return; }

    // Color
    half3 baseColor1 = tex.base_color().sample(samplerBilinear, uv).rgb;
    half3 baseColor2 = tex.emissive_color().sample(samplerBilinear, uv).rgb;

    surface.set_base_color(mix(baseColor1, baseColor2, colorBlend));

    if (stage-- <= 0) { return; }

    // Normal
    half3 normal = realitykit::unpack_normal(tex.normal().sample(samplerBilinear, uv).rgb);
    surface.set_normal(float3(normal));

    if (stage-- <= 0) { return; }

    // Roughness
    half roughness = tex.roughness().sample(samplerBilinear, uv).r * params.material_constants().roughness_scale();
    surface.set_roughness(roughness * (1 + blend));

    if (stage-- <= 0) { return; }

    // Metallic
    half metallic = tex.metallic().sample(samplerBilinear, uv).r * params.material_constants().metallic_scale();
    surface.set_metallic(metallic);

    if (stage-- <= 0) { return; }

    // Ambient
    surface.set_ambient_occlusion(tex.ambient_occlusion().sample(samplerBilinear, uv).r);

    if (stage-- <= 0) { return; }

    // Specular
    half specular = tex.specular().sample(samplerBilinear, uv).r * params.material_constants().specular_scale();
    surface.set_specular(specular);
}

[[visible]]
void octopusCustomTexture(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    uv.y = 1.0 - uv.y;

    auto surface = params.surface();
    auto tex = params.textures();

    surface.set_base_color(tex.custom().sample(samplerBilinear, uv).b);
    surface.set_roughness(1.0);
}
