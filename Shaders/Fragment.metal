//
//  Fragment.metal
//  SPH
//
//  Created by Pierre joly on 26/08/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "ShaderDefs.h"

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
