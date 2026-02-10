#include <metal_stdlib>
using namespace metal;
#include "Common.h"

#define SCAN_BLOCK_SIZE 256

inline uint expandBits2D(uint v) {
    v = (v | (v << 8)) & 0x00FF00FFu;
    v = (v | (v << 4)) & 0x0F0F0F0Fu;
    v = (v | (v << 2)) & 0x33333333u;
    v = (v | (v << 1)) & 0x55555555u;
    return v;
}

inline uint morton2D(uint x, uint y) {
    return (expandBits2D(y) << 1) | expandBits2D(x);
}

kernel void compute_morton_codes(
    device const float2 *positions          [[buffer(PositionBuffer)]],
    device uint         *mortonCodes        [[buffer(MortonCodeBuffer)]],
    device uint         *particleIds        [[buffer(ParticleIdsBuffer)]],
    device uint         *cellLinear         [[buffer(CellLinearBuffer)]],
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

    uint x = uint(cellIndex.x);
    uint y = uint(cellIndex.y);
    mortonCodes[id] = morton2D(x, y);
    particleIds[id] = id;
    cellLinear[id] = y * gridRes.x + x;
}

kernel void radix_bit_flags(
    device const uint *mortonCodes          [[buffer(MortonCodeBuffer)]],
    device uint       *flags                [[buffer(RadixFlagsBuffer)]],
    constant uint     &bitIndex             [[buffer(BitIndexBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;
    uint bit = (mortonCodes[id] >> bitIndex) & 1u;
    flags[id] = (bit == 0u) ? 1u : 0u;
}

kernel void radix_scan_block_exclusive(
    device const uint *inputFlags           [[buffer(RadixFlagsBuffer)]],
    device uint       *prefix               [[buffer(RadixPrefixBuffer)]],
    device uint       *blockSums            [[buffer(BlockSumsBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint tid [[thread_index_in_threadgroup]],
    uint3 tgid [[threadgroup_position_in_grid]]
){
    threadgroup uint shared[SCAN_BLOCK_SIZE];
    uint blockId = tgid.x;
    uint idx = blockId * SCAN_BLOCK_SIZE + tid;

    uint value = (idx < numParticles) ? inputFlags[idx] : 0u;
    shared[tid] = value;
    threadgroup_barrier(mem_flags::mem_threadgroup);

    for (uint offset = 1; offset < SCAN_BLOCK_SIZE; offset <<= 1) {
        uint index = ((tid + 1) * offset * 2) - 1;
        if (index < SCAN_BLOCK_SIZE) {
            shared[index] += shared[index - offset];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    uint total = shared[SCAN_BLOCK_SIZE - 1];
    if (tid == 0) {
        blockSums[blockId] = total;
        shared[SCAN_BLOCK_SIZE - 1] = 0u;
    }
    threadgroup_barrier(mem_flags::mem_threadgroup);

    for (uint offset = SCAN_BLOCK_SIZE >> 1; offset > 0; offset >>= 1) {
        uint index = ((tid + 1) * offset * 2) - 1;
        if (index < SCAN_BLOCK_SIZE) {
            uint t = shared[index - offset];
            shared[index - offset] = shared[index];
            shared[index] += t;
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (idx < numParticles) {
        prefix[idx] = shared[tid];
    }
}

kernel void radix_scan_block_sums_exclusive(
    device const uint *blockSums            [[buffer(BlockSumsBuffer)]],
    device uint       *blockOffsets         [[buffer(BlockOffsetsBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint tid [[thread_index_in_threadgroup]]
){
    if (tid != 0) return;
    uint numBlocks = (numParticles + SCAN_BLOCK_SIZE - 1) / SCAN_BLOCK_SIZE;
    uint running = 0u;
    for (uint i = 0u; i < numBlocks; ++i) {
        uint value = blockSums[i];
        blockOffsets[i] = running;
        running += value;
    }
}

kernel void radix_add_block_offsets(
    device uint       *prefix               [[buffer(RadixPrefixBuffer)]],
    device const uint *blockOffsets         [[buffer(BlockOffsetsBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint gid [[thread_position_in_grid]]
){
    if (gid >= numParticles) return;
    uint blockId = gid / SCAN_BLOCK_SIZE;
    prefix[gid] += blockOffsets[blockId];
}

kernel void radix_total_zeros(
    device const uint *flags                [[buffer(RadixFlagsBuffer)]],
    device const uint *prefix               [[buffer(RadixPrefixBuffer)]],
    device uint       *totalZeros           [[buffer(TotalZerosBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint tid [[thread_position_in_grid]]
){
    if (tid != 0) return;
    if (numParticles == 0u) {
        totalZeros[0] = 0u;
        return;
    }
    uint last = numParticles - 1u;
    totalZeros[0] = prefix[last] + flags[last];
}

kernel void radix_scatter(
    device const uint *keysIn               [[buffer(MortonCodeBuffer)]],
    device const uint *idsIn                [[buffer(ParticleIdsBuffer)]],
    device const uint *cellIn               [[buffer(CellLinearBuffer)]],
    device const uint *flags                [[buffer(RadixFlagsBuffer)]],
    device const uint *prefix               [[buffer(RadixPrefixBuffer)]],
    device const uint *totalZeros           [[buffer(TotalZerosBuffer)]],
    device uint       *keysOut              [[buffer(MortonTempBuffer)]],
    device uint       *idsOut               [[buffer(ParticleIdsTempBuffer)]],
    device uint       *cellOut              [[buffer(CellLinearTempBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;
    uint zerosBefore = prefix[id];
    uint isZero = flags[id];
    uint totalZero = totalZeros[0];
    uint pos = isZero ? zerosBefore : (totalZero + (id - zerosBefore));
    keysOut[pos] = keysIn[id];
    idsOut[pos] = idsIn[id];
    cellOut[pos] = cellIn[id];
}

kernel void clear_cell_ranges(
    device uint  *cellStart                 [[buffer(CellStartBuffer)]],
    device uint  *cellEnd                   [[buffer(CellEndBuffer)]],
    constant uint2 &gridRes                 [[buffer(GridResBuffer)]],
    uint gid [[thread_position_in_grid]]
){
    uint totalCells = gridRes.x * gridRes.y;
    if (gid < totalCells) {
        cellStart[gid] = 0u;
        cellEnd[gid] = 0u;
    }
}

kernel void build_cell_ranges(
    device const uint *cellLinearSorted     [[buffer(CellLinearBuffer)]],
    device uint       *cellStart            [[buffer(CellStartBuffer)]],
    device uint       *cellEnd              [[buffer(CellEndBuffer)]],
    constant uint     &numParticles         [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;

    uint cell = cellLinearSorted[id];
    uint prevCell = (id > 0) ? cellLinearSorted[id - 1] : cell;
    uint nextCell = (id + 1 < numParticles) ? cellLinearSorted[id + 1] : cell;

    if (id == 0 || cell != prevCell) {
        cellStart[cell] = id;
    }
    if (id + 1 == numParticles || cell != nextCell) {
        cellEnd[cell] = id + 1;
    }
}

kernel void reorder_positions_velocities(
    device const uint   *sortedParticleIds  [[buffer(ParticleIdsBuffer)]],
    device const float2 *positions          [[buffer(PositionBuffer)]],
    device const float2 *velocities         [[buffer(VelocityBuffer)]],
    device float2       *sortedPositions    [[buffer(SortedPositionBuffer)]],
    device float2       *sortedVelocities   [[buffer(SortedVelocityBuffer)]],
    constant uint       &numParticles       [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;
    uint pid = sortedParticleIds[id];
    sortedPositions[id] = positions[pid];
    sortedVelocities[id] = velocities[pid];
}

kernel void reorder_density_pressure(
    device const uint *sortedParticleIds    [[buffer(ParticleIdsBuffer)]],
    device const float *densities           [[buffer(DensityBuffer)]],
    device const float *pressures           [[buffer(PressureBuffer)]],
    device float       *sortedDensities     [[buffer(SortedDensityBuffer)]],
    device float       *sortedPressures     [[buffer(SortedPressureBuffer)]],
    constant uint      &numParticles        [[buffer(NumParticlesBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;
    uint pid = sortedParticleIds[id];
    sortedDensities[id] = densities[pid];
    sortedPressures[id] = pressures[pid];
}
