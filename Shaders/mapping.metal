#include <metal_stdlib>
using namespace metal;
#include "Common.h"

// Zero counts in cellStart
kernel void zero_cells(
    device uint  *cellStart                 [[buffer(CellStartBuffer)]],
    constant uint2 &gridRes                 [[buffer(GridResBuffer)]],
    uint gid [[thread_position_in_grid]]
){
    uint totalCells = gridRes.x * gridRes.y;
    if (gid < totalCells) {
        cellStart[gid] = 0u;
    }
}

// Histogram: count particles per cell
kernel void histogram_cells(
    device const float2 *positions          [[buffer(PositionBuffer)]],
    device atomic_uint  *cellCounts         [[buffer(CellStartBuffer)]],
    constant uint2      &gridRes            [[buffer(GridResBuffer)]],
    constant float2     &origin             [[buffer(OriginBuffer)]],
    constant float      &invCell            [[buffer(InvCellBuffer)]],
    constant uint       &numParticles       [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;

    float2 position = positions[id];
    float2 positionInCellSpace = (position - origin) * invCell;
    int2   cellIndex = int2(floor(positionInCellSpace));
    cellIndex.x = clamp(cellIndex.x, 0, int(gridRes.x) - 1);
    cellIndex.y = clamp(cellIndex.y, 0, int(gridRes.y) - 1);

    uint cellLinearIndex = uint(cellIndex.y) * gridRes.x + uint(cellIndex.x);
    atomic_fetch_add_explicit(&cellCounts[cellLinearIndex], 1, memory_order_relaxed);
}

// Exclusive prefix sum (counts -> starts)
kernel void exclusive_scan_counts(
    device uint  *cellStart                 [[buffer(CellStartBuffer)]],
    constant uint2 &gridRes                 [[buffer(GridResBuffer)]],
    uint tid [[thread_position_in_grid]]
){
    if (tid != 0) return;

    uint totalCells = gridRes.x * gridRes.y;
    uint running = 0u;
    for (uint c = 0u; c < totalCells; ++c) {
        uint count = cellStart[c];
        cellStart[c] = running;
        running += count;
    }
}

// Copy starts -> ends
kernel void copy_starts_to_ends(
    device const uint *cellStart            [[buffer(CellStartBuffer)]],
    device uint       *cellEnd              [[buffer(CellEndBuffer)]],
    constant uint2    &gridRes              [[buffer(GridResBuffer)]],
    uint gid [[thread_position_in_grid]]
){
    uint totalCells = gridRes.x * gridRes.y;
    if (gid < totalCells) {
        cellEnd[gid] = cellStart[gid];
    }
}

// Scatter particle IDs into contiguous ranges per cell
kernel void scatter_sorted_ids(
    device const float2 *positions          [[buffer(PositionBuffer)]],
    device atomic_uint  *cellWritePtr       [[buffer(CellEndBuffer)]],
    device uint         *particleIds        [[buffer(ParticleIdsBuffer)]],
    constant uint2      &gridRes            [[buffer(GridResBuffer)]],
    constant float2     &origin             [[buffer(OriginBuffer)]],
    constant float      &invCell            [[buffer(InvCellBuffer)]],
    constant uint       &numParticles       [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;

    float2 position = positions[id];
    float2 positionInCellSpace = (position - origin) * invCell;
    int2   cellIndex = int2(floor(positionInCellSpace));
    cellIndex.x = clamp(cellIndex.x, 0, int(gridRes.x) - 1);
    cellIndex.y = clamp(cellIndex.y, 0, int(gridRes.y) - 1);

    uint cellLinearIndex = uint(cellIndex.y) * gridRes.x + uint(cellIndex.x);
    uint writeIndex = atomic_fetch_add_explicit(&cellWritePtr[cellLinearIndex], 1, memory_order_relaxed);
    particleIds[writeIndex] = id;
}
