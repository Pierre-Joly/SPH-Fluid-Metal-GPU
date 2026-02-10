#include <metal_stdlib>
using namespace metal;

#include "Common.h"

constant float box     = 0.5f;
constant float damping = 0.7f;

kernel void collision(device float2 *velocities [[buffer(VelocityBuffer)]],
                      device float2 *positions  [[buffer(PositionBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) return;

    float2 position = positions[id];
    float2 velocity = velocities[id];

    // Per-axis hit masks (0 or 1)
    float2 hitHi = step(float2(box), position);
    float2 hitLo = step(position, -float2(box));
    float2 hit   = clamp(hitHi + hitLo, 0.0f, 1.0f);

    // Clamp position into the box
    float2 positionClamped = clamp(position, -float2(box), float2(box));

    // Reflect & damp only collided component
    float2 velocityReflected = -velocity * damping;
    float2 velocityOut = velocity * (1.0f - hit) + velocityReflected * hit;

    positions[id]  = positionClamped;
    velocities[id] = velocityOut;
}
