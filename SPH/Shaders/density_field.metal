#include <metal_stdlib>
using namespace metal;

#include "Common.h"

kernel void clear_density_grid(
    device atomic_uint *grid              [[buffer(ForceBuffer)]],
    constant uint2     &gridRes           [[buffer(GridResBuffer)]],
    uint id [[thread_position_in_grid]]
){
    uint total = gridRes.x * gridRes.y;
    if (id < total) {
        atomic_store_explicit(&grid[id], 0u, memory_order_relaxed);
    }
}

kernel void accumulate_density_grid(
    device const float2 *positions         [[buffer(PositionBuffer)]],
    device const float2 *velocities        [[buffer(VelocityBuffer)]],
    device atomic_uint  *grid              [[buffer(ForceBuffer)]],
    constant uint2      &gridRes           [[buffer(GridResBuffer)]],
    constant float2     &origin            [[buffer(OriginBuffer)]],
    constant float      &viewWidth         [[buffer(ViewWidthBuffer)]],
    constant float      &viewHeight        [[buffer(ViewHeightBuffer)]],
    constant uint       &numParticles      [[buffer(NumParticlesBuffer)]],
    constant float      &densityScale      [[buffer(DensityScaleBuffer)]],
    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;

    float2 pos = positions[id];
    float2 uv = (pos - origin) / float2(viewWidth, viewHeight);
    uv = clamp(uv, float2(0.0f), float2(0.999999f));

    uint x = uint(uv.x * float(gridRes.x));
    uint y = uint(uv.y * float(gridRes.y));
    uint idx = y * gridRes.x + x;
    if (densityScale < 0.0f) {
        float speed = length(velocities[id]);
        float fixedScale = 1024.0f;
        uint add = uint(min(speed * fixedScale, 4294967000.0f));
        atomic_fetch_add_explicit(&grid[idx], add, memory_order_relaxed);
    } else {
        atomic_fetch_add_explicit(&grid[idx], 1u, memory_order_relaxed);
    }
}

kernel void density_grid_to_texture(
    device const atomic_uint *grid         [[buffer(ForceBuffer)]],
    texture2d<float, access::write> outTex [[texture(0)]],
    constant uint2      &gridRes           [[buffer(GridResBuffer)]],
    constant float      &densityScale      [[buffer(DensityScaleBuffer)]],
    uint2 tid [[thread_position_in_grid]]
){
    if (tid.x >= gridRes.x || tid.y >= gridRes.y) return;
    uint idx = tid.y * gridRes.x + tid.x;
    uint count = atomic_load_explicit(&grid[idx], memory_order_relaxed);
    float scale = fabs(densityScale);
    if (densityScale < 0.0f) {
        float fixedScale = 1024.0f;
        float speed = float(count) / fixedScale;
        float intensity = min(1.0f, speed * scale);
        outTex.write(intensity, tid);
    } else {
        float intensity = min(1.0f, float(count) * scale);
        outTex.write(intensity, tid);
    }
}
