#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "ShaderDefs.h"

struct DensityVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> spriteTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]])
{
    // Sample the texture using the texture coordinates
    float4 color = spriteTexture.sample(textureSampler, in.texCoord);
    
    color.xyz = in.color;
    
    // Output the color with alpha blending
    return color;
}

fragment float4 density_fragment(DensityVertexOut in [[stage_in]],
                                 texture2d<float> densityTexture [[texture(0)]],
                                 sampler textureSampler [[sampler(0)]])
{
    float d = densityTexture.sample(textureSampler, in.texCoord).r;
    float logScale = 20.0f;
    float mapped = log(1.0f + d * logScale) / log(1.0f + logScale);
    float3 colorLow = float3(0.1, 0.2, 0.9);
    float3 colorHigh = float3(0.95, 0.2, 0.1);
    float3 color = mix(colorLow, colorHigh, clamp(mapped, 0.0f, 1.0f));
    float alpha = mix(0.2f, 0.9f, smoothstep(0.0f, 1.0f, mapped));
    return float4(color, alpha);
}
