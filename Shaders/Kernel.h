#ifndef KERNEL_H
#define KERNEL_H

#include <metal_stdlib>
using namespace metal;

#include "Common.h"

// Physics constants
constant const float mass = 1.0f;
constant const float PI = 3.1415927f;
constant const float volume = PARTICLE_SIZE * 100;
constant const float h = PARTICLE_SIZE * 10;  // Kernel Radius
constant const float restDensity = 1000.0f;
constant const float stiffness = 1e5f;
constant const float dt = 5e-5f;
constant const float2 g = float2(0.0f, -9.81f);
constant const float gravityK = 1e5f;
constant const float viscosityCoefficient = 1.0f;
constant const float nearStiffness = 1e-5 * stiffness;

// Numerical stability constant
constant float eps = 1e-8f;

// Precomputed constants
constant float h2 = h * h;
constant float h3 = h2 * h;
constant float h4 = h2 * h2;
constant float h5 = h2 * h3;
constant float h8 = h5 * h3;

// Viscosity Laplacian Kernel - Laplacian of
inline float ViscosityLaplacianKernel(float r)
{
    float h_minus_r = max(h - r, 0.0f);
    return (20.0f / (PI * h5)) * h_minus_r;
}

// Pressure Gradient Kernel - Gradient of Spiky kernel 2D
inline float2 PressureGradientKernel(float2 vec, float r)
{
    float h_minus_r = max(h - r, 0.0f);
    float coeff = (30.0f / (PI * h5)) * h_minus_r * h_minus_r;
    return -coeff * vec / (r + eps);
}

// Near-Pressure Gradient Kernel
inline float2 NearPressureGradientKernel(float2 vec, float r)
{
    float h_minus_r = max(h - r, 0.0f);
    float coeff = (10.0f / (PI * h5)) * h_minus_r * h_minus_r * h_minus_r;
    return -coeff * vec / (r + eps);
}

// Density Kernel - Polynomial kernel 2D
inline float DensityKernel(float r)
{
    float h2_minus_r2 = h2 - r * r;
    h2_minus_r2 = max(h2_minus_r2, 0.0f);
    float h2_minus_r2_cubed = h2_minus_r2 * h2_minus_r2 * h2_minus_r2;
    return (4.0f / (PI * h8)) * h2_minus_r2_cubed;
}

#endif /* KERNEL_H */
