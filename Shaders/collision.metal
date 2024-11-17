//
//  collision.metal
//  SPH
//
//  Created by Pierre Joly on 19/09/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"

constant float box = 0.5f;
constant float damping = 0.7f;
constant float dist = box;

kernel void collision(device float2 *velocities [[buffer(VelocityBuffer)]],
                      device float2 *positions [[buffer(PositionBuffer)]],
                      constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                      uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) {
        return;
    }
    
    thread float2 myPosition = positions[id];
    thread float2 myVelocity = velocities[id];

    // Check collision with box boundaries and apply damping
    if (myPosition.x > dist) {
        myPosition.x = dist;
        myVelocity.x *= -damping;
    } else if (myPosition.x < -dist) {
        myPosition.x = -dist;
        myVelocity.x *= -damping;
    }
    if (myPosition.y > dist) {
        myPosition.y = dist;
        myVelocity.y *= -damping;
    } else if (myPosition.y < -dist) {
        myPosition.y = -dist;
        myVelocity.y *= -damping;
    }
    
    // Update positions and velocities
    positions[id] = myPosition;
    velocities[id] = myVelocity;
}
