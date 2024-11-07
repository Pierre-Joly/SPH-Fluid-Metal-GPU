//
//  force.metal
//  SPH
//
//  Created by Pierre Joly on 28/08/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void force(device const float *pressures [[buffer(PressureBuffer)]],
                  device const float2 *positions [[buffer(PositionKBuffer)]],
                  device const float2 *velocities [[buffer(VelocityBuffer)]],
                  device const float *densities [[buffer(DensityBuffer)]],
                  device float2 *forces [[buffer(ForceBuffer)]],
                  constant uint &numParticles [[buffer(NumParticlesBuffer)]],
                  uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) {
        return;
    }
    
    thread float M = volume * restDensity / numParticles;

    thread float2 position = positions[id];
    thread float2 velocity = velocities[id];
    thread float pressure = pressures[id];
    thread float density = densities[id];
    
    // Initialize force with gravity
    thread float2 externalForce = M * gravityK * g;
    thread float2 pressureForce = float2(0, 0);
    thread float2 viscosityForce = float2(0, 0);

    // Loop over cells
    for (uint i = 0; i < numParticles; i++) {

        float2 neighborPosition = positions[i];
        float2 neighborVelocity = velocities[i];
        float neighborPressure = pressures[i];
        float neighborDensity = densities[i];

        float2 vector = position - neighborPosition;
        float radius = length(vector);

        if (radius < h) {
            // Pressure force
            float2 gradW = PressureGradientKernel(vector, radius);
            float pressureTerm = M * (pressure + neighborPressure) / 2 / neighborDensity / density;
            pressureForce -= pressureTerm * gradW;
            
            // Near Pressure force
            gradW = NearPressureGradientKernel(vector, radius);
            pressureTerm = M * nearStiffness * density;
            pressureForce -= pressureTerm * gradW;

            // Viscosity force
            float laplacianW = ViscosityLaplacianKernel(radius);
            viscosityForce += M * viscosityCoefficient * (neighborVelocity - velocity) * laplacianW / neighborDensity;
        }
    }

    // Store the total force
    forces[id] = pressureForce + viscosityForce + externalForce;
}
