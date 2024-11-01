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

// Constants
constant const float2 g = float2(0.0f, -9.81f);
constant const float viscosityCoefficient = 100.0f;
constant const float surfaceTensionCoefficient = 1.0f;

kernel void force_main(device const float *pressures [[buffer(PressureBuffer)]],
                       device const float2 *positions [[buffer(PositionBuffer)]],
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
    thread float densitySquared = density*density;
    
    // Initialize force with gravity
    thread float2 externalForce = g;
    thread float2 pressureForce = float2(0, 0);
    thread float2 viscosityForce = float2(0, 0);
    thread float2 surfaceTensionForce = float2(0, 0);

    // Loop over cells
    for (uint i = 0; i < numParticles; i++) {

        float2 neighborPosition = positions[i];
        float2 neighborVelocity = velocities[i];
        float neighborPressure = pressures[i];
        float neighborDensity = densities[i];
        float neighborDensitySquared = neighborDensity*neighborDensity;

        float2 vector = position - neighborPosition;
        float radius = length(vector);

        if (radius < h) {
            // Pressure force
            float2 gradW = PressureGradientKernel(vector, radius);
            float pressureTerm = M * (pressure / densitySquared + neighborPressure / neighborDensitySquared);
            pressureForce -= pressureTerm * gradW;

            // Viscosity force
            float laplacianW = ViscosityLaplacianKernel(radius);
            viscosityForce += viscosityCoefficient * M * (neighborVelocity - velocity) * laplacianW / neighborDensity / density;
            
            // Surface Tension force
            float W = DensityKernel(radius);
            surfaceTensionForce += surfaceTensionCoefficient * (position - neighborPosition) * W;
        }
    }

    // Store the total force
    forces[id] = pressureForce + viscosityForce + surfaceTensionForce + externalForce;
}
