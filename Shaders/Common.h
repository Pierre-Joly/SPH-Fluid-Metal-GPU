#ifndef Common_h
#define Common_h

#include <simd/simd.h>

// Size of particles
#define PARTICLE_SIZE 0.005f

typedef enum BufferIndices {
    VertexBuffer = 0,
    UniformsBuffer = 1,
    DensityBuffer = 2,
    PressureBuffer = 3,
    ForceBuffer = 4,
    ViewWidthBuffer = 5,
    ViewHeightBuffer = 6,
    NumParticlesBuffer = 7,
    DTBuffer = 8,
    PositionKBuffer = 9,
    VelocityK1Buffer = 10,
    VelocityK2Buffer = 11,
    VelocityK3Buffer = 12,
    PositionBuffer = 13,
    VelocityBuffer = 14,
    VertexArgumentBuffer = 15,
    ForceK1Buffer = 16,
    ForceK2Buffer = 17,
    ForceK3Buffer = 18,
    ForceK4Buffer = 19,
    GridCountsBuffer = 20,
    GridParticleIndicesBuffer = 21,
    TotalGridCellsBuffer = 22
} BufferIndices;

typedef struct {
    vector_float2 position;
} VertexIn;

typedef struct {
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

#endif /* Common_h */
