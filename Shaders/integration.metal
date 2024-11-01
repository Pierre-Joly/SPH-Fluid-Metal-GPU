//
//  integration.metal
//  SPH
//
//  Created by Pierre Joly on 28/08/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"

kernel void rk4_step1(constant const float2 *positions [[buffer(PositionBuffer)]],
                      constant const float2 *velocities [[buffer(VelocityBuffer)]],
                      device float2 *velocitiesK1 [[buffer(VelocityK1Buffer)]],
                      device float2 *positionsK1 [[buffer(PositionK1Buffer)]],
                      constant const float2 *forcesK1 [[buffer(ForceK1Buffer)]],
                      constant const float &dt [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    // Compute k1 values
    velocitiesK1[id] = velocities[id] + 0.5f * dt * forcesK1[id];
    positionsK1[id] = positions[id] + 0.5f * dt * velocities[id];
}

kernel void rk4_step2(constant const float2 *positionsK1 [[buffer(PositionK1Buffer)]],
                      constant const float2 *velocitiesK1 [[buffer(VelocityK1Buffer)]],
                      device float2 *velocitiesK2 [[buffer(VelocityK2Buffer)]],
                      device float2 *positionsK2 [[buffer(PositionK2Buffer)]],
                      constant const float2 *forcesK2 [[buffer(ForceK2Buffer)]],
                      constant float &dt [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    // Compute k2 values
    velocitiesK2[id] = velocitiesK1[id] + 0.5f * dt * forcesK2[id];
    positionsK2[id] = positionsK1[id] + 0.5f * dt * velocitiesK1[id];
}

kernel void rk4_step3(constant const float2 *positionsK2 [[buffer(PositionK2Buffer)]],
                      constant const float2 *velocitiesK2 [[buffer(VelocityK2Buffer)]],
                      device float2 *velocitiesK3 [[buffer(VelocityK3Buffer)]],
                      device float2 *positionsK3 [[buffer(PositionK3Buffer)]],
                      constant const float2 *forcesK3 [[buffer(ForceK3Buffer)]],
                      constant float &dt [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    // Compute k3 values
    velocitiesK3[id] = velocitiesK2[id] + 0.5f * dt * forcesK3[id];
    positionsK3[id] = positionsK2[id] + 0.5f * dt * velocitiesK2[id];
}

kernel void rk4_step4(constant const float2 *positionsK3 [[buffer(PositionK3Buffer)]],
                      constant const float2 *velocitiesK3 [[buffer(VelocityK3Buffer)]],
                      device float2 *velocitiesK4 [[buffer(VelocityK4Buffer)]],
                      device float2 *positionsK4 [[buffer(PositionK4Buffer)]],
                      constant const float2 *forcesK4 [[buffer(ForceK4Buffer)]],
                      constant float &dt [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    // Compute k4 values
    velocitiesK4[id] = velocitiesK3[id] + dt * forcesK4[id];
    positionsK4[id] = positionsK3[id] + dt * velocitiesK3[id];
}

kernel void integrateRK4Results(device float2 *positions [[buffer(PositionBuffer)]],
                                device float2 *velocities [[buffer(VelocityBuffer)]],
                                constant const float2 *forcesK1 [[buffer(ForceK1Buffer)]],
                                constant const float2 *forcesK2 [[buffer(ForceK2Buffer)]],
                                constant const float2 *forcesK3 [[buffer(ForceK3Buffer)]],
                                constant const float2 *forcesK4 [[buffer(ForceK4Buffer)]],
                                constant const float2 *positionsK1 [[buffer(PositionK1Buffer)]],
                                constant const float2 *positionsK2 [[buffer(PositionK2Buffer)]],
                                constant const float2 *positionsK3 [[buffer(PositionK3Buffer)]],
                                constant const float2 *positionsK4 [[buffer(PositionK4Buffer)]],
                                constant const float2 *velocitiesK1 [[buffer(VelocityK1Buffer)]],
                                constant const float2 *velocitiesK2 [[buffer(VelocityK2Buffer)]],
                                constant const float2 *velocitiesK3 [[buffer(VelocityK3Buffer)]],
                                constant const float2 *velocitiesK4 [[buffer(VelocityK4Buffer)]],
                                constant float &dt [[buffer(DTBuffer)]],
                                constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                                uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;
    
    // Compute the weighted average of k1, k2, k3, and k4 for final position and velocity
    positions[id] += (dt / 6.0f) * \
                                    (velocitiesK1[id] + 2.0f * (velocitiesK2[id] + velocitiesK3[id]) + velocitiesK4[id]);
    
    velocities[id] += (dt / 6.0f) * \
                                    (forcesK1[id] + 2.0f * (forcesK2[id] + forcesK3[id]) + forcesK4[id]);
}
