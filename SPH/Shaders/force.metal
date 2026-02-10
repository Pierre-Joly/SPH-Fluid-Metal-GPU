#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "Kernel.h"

kernel void force(
    // Inputs
    device const float  *pressures            [[buffer(PressureBuffer)]],
    device const float2 *positions            [[buffer(PositionBuffer)]],
    device const float2 *velocities           [[buffer(VelocityBuffer)]],
    device const float  *densities            [[buffer(DensityBuffer)]],

    // Output
    device float2       *forces               [[buffer(ForceBuffer)]],

    // Range-based neighbor data
    device const uint   *cellStart            [[buffer(CellStartBuffer)]],
    device const uint   *cellEnd              [[buffer(CellEndBuffer)]],
    device const uint   *sortedParticleIds    [[buffer(ParticleIdsBuffer)]],
    device const float2 *sortedPositions      [[buffer(SortedPositionBuffer)]],
    device const float2 *sortedVelocities     [[buffer(SortedVelocityBuffer)]],
    device const float  *sortedDensities      [[buffer(SortedDensityBuffer)]],
    device const float  *sortedPressures      [[buffer(SortedPressureBuffer)]],

    // Mapping constants
    constant uint2      &gridRes              [[buffer(GridResBuffer)]],
    constant float2     &origin               [[buffer(OriginBuffer)]],
    constant float      &invCell              [[buffer(InvCellBuffer)]],
    constant uint       &numParticles         [[buffer(NumParticlesBuffer)]],
    constant float      &particleSize         [[buffer(ParticleSizeBuffer)]],
    constant float      &stiffnessValue       [[buffer(StiffnessBuffer)]],
    constant float      &restDensityValue     [[buffer(RestDensityBuffer)]],
    constant float      &viscosityValue       [[buffer(ViscosityBuffer)]],
    constant float      &gravityMultiplier    [[buffer(GravityBuffer)]],

    uint id [[thread_position_in_grid]]
){
    if (id >= numParticles) return;

    // Particle state
    float h = particleSize * 4.0f;
    float h2 = h * h;
    float h3 = h2 * h;
    float h5 = h2 * h3;
    float volume = 1.0f;
    float mass = volume * restDensityValue / numParticles;
    float nearStiffness = 1e-5f * stiffnessValue;
    float2 position = positions[id];
    float2 velocity = velocities[id];
    float  pressure = pressures[id];
    float  density  = densities[id];

    // Forces
    float2 externalForce  = density * g * gravityMultiplier;
    float2 pressureForce  = float2(0.0f, 0.0f);
    float2 viscosityForce = float2(0.0f, 0.0f);

    // Cell of this particle
    float2 positionInCellSpace = (position - origin) * invCell;
    int2   cellIndex = int2(floor(positionInCellSpace));
    cellIndex.x = clamp(cellIndex.x, 0, int(gridRes.x) - 1);
    cellIndex.y = clamp(cellIndex.y, 0, int(gridRes.y) - 1);

    // Clamp neighbor bounds
    int x0 = max(0,                cellIndex.x - 1);
    int x1 = min(int(gridRes.x)-1, cellIndex.x + 1);
    int y0 = max(0,                cellIndex.y - 1);
    int y1 = min(int(gridRes.y)-1, cellIndex.y + 1);

    // Visit 3×3 neighbor cells
    for (int ny = y0; ny <= y1; ++ny) {
        for (int nx = x0; nx <= x1; ++nx) {
            uint neighborCellLinearIndex = uint(ny) * gridRes.x + uint(nx);
            uint rangeStart = cellStart[neighborCellLinearIndex];
            uint rangeEnd   = cellEnd[neighborCellLinearIndex];

            for (uint k = rangeStart; k < rangeEnd; ++k) {
                uint   neighborId       = sortedParticleIds[k];
                if (neighborId == id) continue;

                float2 neighborPosition = sortedPositions[k];
                float2 neighborVelocity = sortedVelocities[k];
                float  neighborPressure = sortedPressures[k];
                float  neighborDensity  = sortedDensities[k];

                float2 vector = position - neighborPosition;
                float radius2 = dot(vector, vector);
                if (radius2 >= h2) continue;
                float radius = sqrt(radius2);

                // Pressure force (Spiky gradient)
                float2 gradW = PressureGradientKernel(vector, radius, h, h5);
                float  pressureTerm = mass * (pressure + neighborPressure) / (2.0f * neighborDensity * density);
                pressureForce -= pressureTerm * gradW;

                // Near-pressure
                float2 gradNear = NearPressureGradientKernel(vector, radius, h, h5);
                float  nearTerm = mass * nearStiffness * density;
                pressureForce -= nearTerm * gradNear;

                // Viscosity
                float laplacianW = ViscosityLaplacianKernel(radius, h, h5);
                viscosityForce += mass * viscosityValue * (neighborVelocity - velocity) * (laplacianW / neighborDensity);
            }
        }
    }

    forces[id] = pressureForce + viscosityForce + externalForce;
}
