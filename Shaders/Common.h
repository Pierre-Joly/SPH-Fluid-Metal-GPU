//
//  Common.h
//  SPH
//
//  Created by Pierre joly on 26/08/2024.
//

#ifndef Common_h
#define Common_h

#include <simd/simd.h>

#define size 0.005f
#define mass 1.0f

typedef enum BufferIndices {
    VertexBuffer = 0,
    UniformsBuffer = 1,
    DensityBuffer = 2,
    PressureBuffer = 3,
    ForceBuffer = 4,
    ConstantBuffer = 5,
    NumParticlesBuffer = 6,
    DTBuffer = 7,
    PositionK1Buffer = 8,
    PositionK2Buffer = 9,
    PositionK3Buffer = 10,
    PositionK4Buffer = 11,
    VelocityK1Buffer = 12,
    VelocityK2Buffer = 13,
    VelocityK3Buffer = 14,
    VelocityK4Buffer = 15,
    PositionBuffer = 16,
    VelocityBuffer = 17,
    VertexArgumentBuffer = 18,
    ForceK1Buffer = 19,
    ForceK2Buffer = 20,
    ForceK3Buffer = 21,
    ForceK4Buffer = 22
} BufferIndices;

typedef struct {
    vector_float2 position;
} VertexIn;

typedef struct {
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

typedef struct {
    uint particleNumber;
    float viewWidth;
    float viewHeight;
} InitPositionConstants;

#endif /* Common_h */
