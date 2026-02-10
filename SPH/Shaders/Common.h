#ifndef Common_h
#define Common_h

#include <simd/simd.h>

typedef enum BufferIndices {
    VertexBuffer = 0,
    UniformsBuffer = 1,
    ViscosityBuffer = UniformsBuffer,
    DensityBuffer = 2,
    PressureBuffer = 3,
    ForceBuffer = 4,
    ViewWidthBuffer = 5,
    ViewHeightBuffer = 6,
    NumParticlesBuffer = 7,
    SortedPositionBuffer = 8,
    SortedVelocityBuffer = ViewWidthBuffer,
    SortedDensityBuffer = ViewHeightBuffer,
    PositionKBuffer = 9,
    VelocityK1Buffer = 10,
    VelocityK2Buffer = 11,
    VelocityK3Buffer = 12,
    RadixFlagsBuffer = PositionKBuffer,
    CellLinearTempBuffer = VelocityK1Buffer,
    CellLinearBuffer = VelocityK2Buffer,
    RadixPrefixBuffer = VelocityK3Buffer,
    PositionBuffer = 13,
    VelocityBuffer = 14,
    VertexArgumentBuffer = 15,
    SortedPressureBuffer = VertexArgumentBuffer,
    ForceK1Buffer = 16,
    ParticleIdsTempBuffer = ForceK1Buffer,
    ForceK2Buffer = 17,
    ForceK3Buffer = 18,
    ForceK4Buffer = 19,
    CellIdsBuffer = 20,
    MortonCodeBuffer = CellIdsBuffer,
    GravityBuffer = CellIdsBuffer,
    MortonTempBuffer = ForceBuffer,
    ParticleIdsBuffer = 21,
    CellStartBuffer = 22,
    CellEndBuffer = 23,
    GridResBuffer = 24,
    OriginBuffer = 25,
    InvCellBuffer = 26,
    ParticleSizeBuffer = 27,
    DensityScaleBuffer = ParticleSizeBuffer,
    BitIndexBuffer = ParticleSizeBuffer,
    StiffnessBuffer = 28,
    TotalZerosBuffer = StiffnessBuffer,
    RestDensityBuffer = 29,
    DTBuffer = 30,
    BlockSumsBuffer = ViewWidthBuffer,
    BlockOffsetsBuffer = ViewHeightBuffer
} BufferIndices;

typedef struct {
    vector_float2 position;
} VertexIn;

typedef struct {
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

#endif /* Common_h */
