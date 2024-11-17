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
#include "Hash.h"

kernel void force(constant const float *pressures [[buffer(PressureBuffer)]],
                  constant const float2 *positions [[buffer(PositionKBuffer)]],
                  constant const float2 *velocities [[buffer(VelocityBuffer)]],
                  constant const float *densities [[buffer(DensityBuffer)]],
                  device float2 *forces [[buffer(ForceBuffer)]],
                  constant const uint *gridCounts [[buffer(GridCountsBuffer)]],
                  constant const uint *gridParticleIndices [[buffer(GridParticleIndicesBuffer)]],
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

    thread float2 externalForce = M * gravityK * g;
    thread float2 pressureForce = float2(0, 0);
    thread float2 viscosityForce = float2(0, 0);

    // Compute grid index of the current particle
    uint x = uint((position.x + 0.5f) / cellSize);
    uint y = uint((position.y + 0.5f) / cellSize);
    uint2 gridIndex = uint2(x, y);

    // Loop over neighboring cells
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int2 neighborGrid = int2(gridIndex) + int2(dx, dy);

            // Check grid bounds
            if (neighborGrid.x < 0 || neighborGrid.x >= int(gridDims.x) ||
                neighborGrid.y < 0 || neighborGrid.y >= int(gridDims.y)) {
                continue;
            }

            uint2 neighborGridU = uint2(neighborGrid.x, neighborGrid.y);
            uint neighborHash = computeHash(neighborGridU);

            uint count = gridCounts[neighborHash];

            // Loop over particles in the neighbor cell
            for (uint i = 0; i < count; i++) {
                uint neighborId = gridParticleIndices[neighborHash * maxParticlesPerCell + i];

                if (neighborId == id) {
                    continue; // Skip self
                }

                float2 neighborPosition = positions[neighborId];
                float2 neighborVelocity = velocities[neighborId];
                float neighborPressure = pressures[neighborId];
                float neighborDensity = densities[neighborId];

                float2 vector = position - neighborPosition;
                float radius = length(vector);

                if (radius < h && radius > 0.0f) {
                    // Pressure force
                    float2 gradW = PressureGradientKernel(vector, radius);
                    float pressureTerm = M * (pressure + neighborPressure) / (2.0f * neighborDensity * density);
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
        }
    }

    // Store the total force
    forces[id] = pressureForce + viscosityForce + externalForce;
}
