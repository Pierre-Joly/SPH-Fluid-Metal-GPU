//
//  spatialHash.metal
//  SPH
//
//  Created by Pierre joly on 02/11/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"
#include "Hash.h"

kernel void spatial_hash(constant const float2 *positions [[buffer(PositionBuffer)]],
                         device uint3 *spatialIndices [[buffer(SpatialIndicesBuffer)]],
                         device uint *spatialOffsets [[buffer(SpatialOffsetsBuffer)]],
                         constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                         uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) return;
    
    // Reset offsets
    spatialOffsets[id] = numParticles;
    
    // Update index buffer
    uint index = id;
    uint2 cell = GetCell2D(positions[index], h);
    uint hash = HashCell2D(cell);
    uint key = KeyFromHash(hash, numParticles);
    spatialIndices[id] = uint3(index, hash, key);
}
