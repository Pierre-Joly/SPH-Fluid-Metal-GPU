#include <metal_stdlib>
using namespace metal;

#include "Common.h"
#include "ShaderDefs.h"

struct vertexArgument {
    constant float2* positions [[id(0)]];
    constant float2* velocities [[id(1)]];
};

vertex VertexOut vertex_main(constant Uniforms& uniforms [[buffer(UniformsBuffer)]],
                             constant VertexIn* vertexArray [[buffer(VertexBuffer)]],
                             constant const vertexArgument& vertexArgument [[buffer(VertexArgumentBuffer)]],
                             constant float &particleSize [[buffer(ParticleSizeBuffer)]],
                             uint vertexId [[vertex_id]],
                             uint instanceId [[instance_id]])
{
    // Access the vertex data
    VertexIn vtx = vertexArray[vertexId];

    // Get the position of the particle (instance)
    float2 particlePosition = vertexArgument.positions[instanceId];
    float2 particleVelocity = vertexArgument.velocities[instanceId];

    // Quad size
    float2 quadSize = float2(particleSize);

    // Compute world position
    float2 position_2D = vtx.position * quadSize + particlePosition;

    // Apply transformations
    float4 position_4D = uniforms.projectionMatrix * uniforms.viewMatrix * float4(position_2D, 0.0, 1.0);

    // Compute texture coordinates
    float2 texCoord = vtx.position + 0.5;
    
    // Compute color
    float3 colorSlow = float3(0.0, 0.0, 1.0);
    float3 colorMedium = float3(0.0, 1.0, 0.0);
    float3 colorFast = float3(1.0, 0.0, 0.0);
    float speed = length(particleVelocity);
    float t = clamp(speed / 100, 0.0, 1.0);
    float3 color = (t < 0.5) ? mix(colorSlow, colorMedium, t * 2.0) : mix(colorMedium, colorFast, (t - 0.5) * 2.0);

    // Prepare the output
    VertexOut out;
    out.position = position_4D;
    out.texCoord = texCoord;
    out.color = color;
    return out;
}

struct DensityVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex DensityVertexOut density_vertex(constant VertexIn* vertexArray [[buffer(VertexBuffer)]],
                                       uint vertexId [[vertex_id]])
{
    VertexIn vtx = vertexArray[vertexId];
    float2 pos = vtx.position * 2.0f;

    DensityVertexOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.texCoord = vtx.position + 0.5f;
    return out;
}
