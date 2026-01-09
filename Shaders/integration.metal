#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void rk4_step1(device const float2 *positions [[buffer(PositionBuffer)]],
                      device const float2 *velocities [[buffer(VelocityBuffer)]],
                      device float2 *velocitiesK1 [[buffer(VelocityK1Buffer)]],
                      device float2 *positionsK [[buffer(PositionKBuffer)]],
                      device const float2 *forcesK1 [[buffer(ForceK1Buffer)]],
                      constant const float &dtValue [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    // Compute k1 values
    velocitiesK1[id] = velocities[id] + 0.5f * dtValue * forcesK1[id];
    positionsK[id] = positions[id] + 0.5f * dtValue * velocities[id];
}

kernel void rk4_step2(device const float2 *positions [[buffer(PositionBuffer)]],
                      device const float2 *velocities [[buffer(VelocityBuffer)]],
                      device float2 *velocitiesK2 [[buffer(VelocityK2Buffer)]],
                      device float2 *positionsK [[buffer(PositionKBuffer)]],
                      device const float2 *velocitiesK1 [[buffer(VelocityK1Buffer)]],
                      device const float2 *forcesK2 [[buffer(ForceK2Buffer)]],
                      constant const float &dtValue [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;
    
    // Compute k2 values
    velocitiesK2[id] = velocities[id] + 0.5f * dtValue * forcesK2[id];
    positionsK[id] = positions[id] + 0.5f * dtValue * velocitiesK1[id];
}

kernel void rk4_step3(device const float2 *positions [[buffer(PositionBuffer)]],
                      device const float2 *velocities [[buffer(VelocityBuffer)]],
                      device float2 *velocitiesK3 [[buffer(VelocityK3Buffer)]],
                      device float2 *positionsK [[buffer(PositionKBuffer)]],
                      device const float2 *velocitiesK2 [[buffer(VelocityK2Buffer)]],
                      device const float2 *forcesK3 [[buffer(ForceK3Buffer)]],
                      constant const float &dtValue [[buffer(DTBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    // Compute k3 values
    velocitiesK3[id] = velocities[id] + dtValue * forcesK3[id];
    positionsK[id] = positions[id] + dtValue * velocitiesK2[id];
}

kernel void integrateRK4Results(device float2 *positions [[buffer(PositionBuffer)]],
                                device float2 *velocities [[buffer(VelocityBuffer)]],
                                device const float2 *velocitiesK1 [[buffer(VelocityK1Buffer)]],
                                device const float2 *velocitiesK2 [[buffer(VelocityK2Buffer)]],
                                device const float2 *velocitiesK3 [[buffer(VelocityK3Buffer)]],
                                device const float2 *forcesK1 [[buffer(ForceK1Buffer)]],
                                device const float2 *forcesK2 [[buffer(ForceK2Buffer)]],
                                device const float2 *forcesK3 [[buffer(ForceK3Buffer)]],
                                device const float2 *forcesK4 [[buffer(ForceK4Buffer)]],
                                constant const float &dtValue [[buffer(DTBuffer)]],
                                constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                                uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;
    
    // Compute the weighted average of k1, k2, k3, and k4 for final position and velocity
    positions[id] += (dtValue / 6.0f) * (velocities[id] + 2.0f * (velocitiesK1[id] + velocitiesK2[id]) + velocitiesK3[id]);
    velocities[id] += (dtValue / 6.0f) * (forcesK1[id] + 2.0f * (forcesK2[id] + forcesK3[id]) + forcesK4[id]);
}

kernel void verlet_step1(device float2 *positions [[buffer(PositionBuffer)]],
                         device const float2 *velocities [[buffer(VelocityBuffer)]],
                         device float2 *velocitiesHalf [[buffer(VelocityK1Buffer)]],
                         device const float2 *forces [[buffer(ForceK1Buffer)]],
                         constant const float &dtValue [[buffer(DTBuffer)]],
                         constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                         uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    float2 vHalf = velocities[id] + 0.5f * dtValue * forces[id];
    positions[id] += dtValue * vHalf;
    velocitiesHalf[id] = vHalf;
}

kernel void verlet_step2(device float2 *velocities [[buffer(VelocityBuffer)]],
                         device const float2 *velocitiesHalf [[buffer(VelocityK1Buffer)]],
                         device const float2 *forces [[buffer(ForceK2Buffer)]],
                         constant const float &dtValue [[buffer(DTBuffer)]],
                         constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                         uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    velocities[id] = velocitiesHalf[id] + 0.5f * dtValue * forces[id];
}

kernel void integrateRK2Results(device float2 *positions [[buffer(PositionBuffer)]],
                                device float2 *velocities [[buffer(VelocityBuffer)]],
                                device const float2 *velocitiesMid [[buffer(VelocityK1Buffer)]],
                                device const float2 *forcesMid [[buffer(ForceK2Buffer)]],
                                constant const float &dtValue [[buffer(DTBuffer)]],
                                constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                                uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    positions[id] += dtValue * velocitiesMid[id];
    velocities[id] += dtValue * forcesMid[id];
}

kernel void pc_predict(device const float2 *positions [[buffer(PositionBuffer)]],
                       device const float2 *velocities [[buffer(VelocityBuffer)]],
                       device float2 *positionsPred [[buffer(PositionKBuffer)]],
                       device float2 *velocitiesPred [[buffer(VelocityK1Buffer)]],
                       device const float2 *forces [[buffer(ForceK1Buffer)]],
                       constant const float &dtValue [[buffer(DTBuffer)]],
                       constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                       uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    positionsPred[id] = positions[id] + dtValue * velocities[id];
    velocitiesPred[id] = velocities[id] + dtValue * forces[id];
}

kernel void pc_correct(device float2 *positions [[buffer(PositionBuffer)]],
                       device float2 *velocities [[buffer(VelocityBuffer)]],
                       device const float2 *positionsPred [[buffer(PositionKBuffer)]],
                       device const float2 *velocitiesPred [[buffer(VelocityK1Buffer)]],
                       device const float2 *forces [[buffer(ForceK1Buffer)]],
                       device const float2 *forcesPred [[buffer(ForceK2Buffer)]],
                       constant const float &dtValue [[buffer(DTBuffer)]],
                       constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                       uint id [[thread_position_in_grid]]) {
    if (id >= numParticles) return;

    positions[id] += 0.5f * dtValue * (velocities[id] + velocitiesPred[id]);
    velocities[id] += 0.5f * dtValue * (forces[id] + forcesPred[id]);
}
