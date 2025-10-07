#include <metal_stdlib>
#include "Hash.h"
#include "Common.h"
using namespace metal;

kernel void assign_particles_to_grid(
    device const float2 *positions [[buffer(PositionBuffer)]],
    device atomic_uint *gridCounts [[buffer(GridCountsBuffer)]],
    device uint *gridParticleIndices [[buffer(GridParticleIndicesBuffer)]],
    constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
)
{
    if (id >= numParticles) return;

    float2 position = positions[id];

    // Compute grid cell indices
    uint x = uint((position.x + 0.5) / cellSize);
    uint y = uint((position.y + 0.5) / cellSize);
    uint2 gridIndex = uint2(x, y);

    // Compute grid hash
    uint hash = computeHash(gridIndex);

    // Atomically increment grid count and get insertion index
    uint index = atomic_fetch_add_explicit(&gridCounts[hash], 1, memory_order_relaxed);

    // Check for overflow
    if (index < maxParticlesPerCell) {
        // Assign particle to grid cell
        gridParticleIndices[hash * maxParticlesPerCell + index] = id;
    }
}
