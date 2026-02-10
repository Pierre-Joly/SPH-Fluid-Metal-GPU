#ifndef KERNEL_H
#define KERNEL_H

#include <metal_stdlib>
using namespace metal;

#include "Common.h"

// Physics constants
constant const float PI = 3.1415927f;
constant const float dt = 5e-5f;
constant const float2 g = float2(0.0f, -9.81f);

// Numerical stability constant
constant float eps = 1e-8f;

// Viscosity Laplacian Kernel - Laplacian of
inline float ViscosityLaplacianKernel(float r, float h, float h5)
{
    float h_minus_r = max(h - r, 0.0f);
    return (20.0f / (PI * h5)) * h_minus_r;
}

// Pressure Gradient Kernel - Gradient of Spiky kernel 2D
inline float2 PressureGradientKernel(float2 vec, float r, float h, float h5)
{
    float h_minus_r = max(h - r, 0.0f);
    float coeff = (30.0f / (PI * h5)) * h_minus_r * h_minus_r;
    return -coeff * vec / (r + eps);
}

// Near-Pressure Gradient Kernel
inline float2 NearPressureGradientKernel(float2 vec, float r, float h, float h5)
{
    float h_minus_r = max(h - r, 0.0f);
    float coeff = (10.0f / (PI * h5)) * h_minus_r * h_minus_r * h_minus_r;
    return -coeff * vec / (r + eps);
}

// Density Kernel - Polynomial kernel 2D (r2 version to avoid sqrt)
inline float DensityKernelR2(float r2, float h2, float h8)
{
    float h2_minus_r2 = h2 - r2;
    h2_minus_r2 = max(h2_minus_r2, 0.0f);
    float h2_minus_r2_cubed = h2_minus_r2 * h2_minus_r2 * h2_minus_r2;
    return (4.0f / (PI * h8)) * h2_minus_r2_cubed;
}

#endif /* KERNEL_H */
