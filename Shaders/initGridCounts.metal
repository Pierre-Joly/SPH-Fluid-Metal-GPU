//
//  initGridCounts.metal
//  SPH
//
//  Created by Pierre joly on 07/11/2024.
//

#include <metal_stdlib>
#include "Common.h"
#include "Hash.h"
using namespace metal;

kernel void init_count_grid(
    device atomic_uint *gridCounts [[buffer(GridCountsBuffer)]],
    uint id [[thread_position_in_grid]]
)
{
    if (id >= totalGridCells) return;

    // Reset each atomic_uint to zero
    atomic_store_explicit(&gridCounts[id], 0, memory_order_relaxed);
}
