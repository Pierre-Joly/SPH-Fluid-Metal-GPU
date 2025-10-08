#include <metal_stdlib>
using namespace metal;
#include "Common.h"

kernel void compute_cell_ids(
    device const float2 *positions     [[buffer(PositionBuffer)]],
    device uint         *cellIds       [[buffer(CellIdsBuffer)]],
    device uint         *particleIds   [[buffer(ParticleIdsBuffer)]],
    constant uint2      &gridRes       [[buffer(GridResBuffer)]],
    constant float2     &origin        [[buffer(OriginBuffer)]],
    constant float      &invCell       [[buffer(InvCellBuffer)]],
    constant uint       &numParticles  [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;

    float2 position = positions[id];

    float2 positionInCellSpace = (position - origin) * invCell;
    int2   cellIndex = int2(floor(positionInCellSpace));
    cellIndex.x = clamp(cellIndex.x, 0, int(gridRes.x) - 1);
    cellIndex.y = clamp(cellIndex.y, 0, int(gridRes.y) - 1);

    uint cellLinearIndex = uint(cellIndex.y) * gridRes.x + uint(cellIndex.x);

    cellIds[id]     = cellLinearIndex;
    particleIds[id] = id;
}
