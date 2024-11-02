//
//  density.metal
//  SPH
//
//  Created by Pierre Joly on 28/08/2024.
//

#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void density_main(constant const float2 *positions [[buffer(PositionKBuffer)]],
                         device float *densities [[buffer(DensityBuffer)]],
                         device float *pressures [[buffer(PressureBuffer)]],
                         constant const uint &numParticles [[buffer(NumParticlesBuffer)]],
                         uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) {
        return;
    }

    thread float2 position = positions[id];
    thread float density = 0.0f;
    thread float M = volume * restDensity / numParticles;

    // Loop over cells
    for (uint i = 0; i < numParticles; i++) {

        float2 vector = position - positions[i];
        float radius = length(vector);

        if (radius < h) {
            density += DensityKernel(radius);
        }
    }
    
    density *= M;
    densities[id] = density;
    pressures[id] = stiffness * (density - restDensity);
}
