#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void density(
    // Inputs
    device const float2 *positions           [[buffer(PositionBuffer)]],
                    
    // Output
    device float        *densities           [[buffer(DensityBuffer)]],
    device float        *pressures           [[buffer(PressureBuffer)]],

    // Range-based neighbor data
    device const uint   *cellStart           [[buffer(CellStartBuffer)]],
    device const uint   *cellEnd             [[buffer(CellEndBuffer)]],
    device const uint   *sortedParticleIds   [[buffer(ParticleIdsBuffer)]],
    device const float2 *sortedPositions     [[buffer(SortedPositionBuffer)]],
                    
    // Mapping constants
    constant uint2      &gridRes             [[buffer(GridResBuffer)]],
    constant float2     &origin              [[buffer(OriginBuffer)]],
    constant float      &invCell             [[buffer(InvCellBuffer)]],
    constant uint       &numParticles        [[buffer(NumParticlesBuffer)]],
    constant float      &particleSize        [[buffer(ParticleSizeBuffer)]],
    constant float      &stiffnessValue      [[buffer(StiffnessBuffer)]],
    constant float      &restDensityValue    [[buffer(RestDensityBuffer)]],

    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;
    
    // Particle state
    float2 position = positions[id];
    float h = particleSize * 4.0f;
    float h2 = h * h;
    float h3 = h2 * h;
    float h5 = h2 * h3;
    float h8 = h5 * h3;
    float volume = 1.0f;
    float mass = volume * restDensityValue / numParticles;

    // Clamp neighbor bounds
    float2 positionInCellSpace = (position - origin) * invCell;
    int2   cellIndex = int2(floor(positionInCellSpace));
    cellIndex.x = clamp(cellIndex.x, 0, int(gridRes.x) - 1);
    cellIndex.y = clamp(cellIndex.y, 0, int(gridRes.y) - 1);

    float density = 0.0f;

    // Visit 3×3 neighbor cells
    int x0 = max(0,              cellIndex.x - 1);
    int x1 = min(int(gridRes.x)-1, cellIndex.x + 1);
    int y0 = max(0,              cellIndex.y - 1);
    int y1 = min(int(gridRes.y)-1, cellIndex.y + 1);

    for (int ny = y0; ny <= y1; ++ny) {
        for (int nx = x0; nx <= x1; ++nx) {
            uint neighborCellLinearIndex = uint(ny) * gridRes.x + uint(nx);
            
            uint rangeStart = cellStart[neighborCellLinearIndex];
            uint rangeEnd   = cellEnd[neighborCellLinearIndex];

            for (uint k = rangeStart; k < rangeEnd; ++k) {
                float2 neighborPos = sortedPositions[k];
                float2 vector = position - neighborPos;
                float r2 = dot(vector, vector);
                if (r2 >= h2) continue;

                density += mass * DensityKernelR2(r2, h2, h8);
            }
        }
    }

    densities[id] = density;
    pressures[id] = stiffnessValue * (density - restDensityValue);
}
