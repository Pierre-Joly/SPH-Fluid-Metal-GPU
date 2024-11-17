//
//  density.metal
//  SPH
//
//  Created by Pierre Joly on 28/08/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"
#include "Hash.h"

kernel void density(constant const float2 *positions [[buffer(PositionKBuffer)]],
                    device float *densities [[buffer(DensityBuffer)]],
                    device float *pressures [[buffer(PressureBuffer)]],
                    constant const uint *gridCounts [[buffer(GridCountsBuffer)]],
                    constant const uint *gridParticleIndices [[buffer(GridParticleIndicesBuffer)]],
                    constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                    uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) {
        return;
    }

    thread float2 position = positions[id];
    thread float density = 0.0f;
    thread float M = volume * restDensity / numParticles;
    
    // Compute grid index of the current particle
    uint x = uint((position.x + 0.5) / cellSize);
    uint y = uint((position.y + 0.5) / cellSize);
    uint2 gridIndex = uint2(x, y);
    
    // Loop over neighboring cells
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int2 neighborGrid = int2(gridIndex) + int2(dx, dy);
            
            // Check grid bounds
            if (neighborGrid.x < 0 || neighborGrid.x >= int(gridDims.x) ||
                neighborGrid.y < 0 || neighborGrid.y >= int(gridDims.y)) {
                continue;
            }
            
            uint2 neighborGridU = uint2(neighborGrid.x, neighborGrid.y);
            uint neighborHash = computeHash(neighborGridU);
            
            uint count = gridCounts[neighborHash];
            
            for (uint i = 0; i < count; i++) {
                uint neighborId = gridParticleIndices[neighborHash * maxParticlesPerCell + i];
                
                float2 neighborPos = positions[neighborId];
                float2 vector = position - neighborPos;
                float radius = length(vector);
                
                density += M * DensityKernel(radius);
            }
        }
    }
    densities[id] = density;
    pressures[id] = stiffness * (density - restDensity);
}
