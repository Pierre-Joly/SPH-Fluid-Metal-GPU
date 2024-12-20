//
//  ShaderDefs.h
//  SPH
//
//  Created by Pierre joly on 26/08/2024.
//

#ifndef ShaderDefs_h
#define ShaderDefs_h

#include "Common.h"

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float3 color;
};

#endif /* ShaderDefs_h */
