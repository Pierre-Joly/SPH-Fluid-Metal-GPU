//
//  Kernel.h
//  SPH
//
//  Created by Pierre Joly on 20/09/2024.
//

#ifndef KERNEL_H
#define KERNEL_H

#include <metal_stdlib>
using namespace metal;

// Physics constants
constant const float mass = 1.0f;
constant const float PI = 3.1415927f;
constant const float volume = 0.5f;
constant const float h = 0.05f;  // Kernel Radius
constant const float restDensity = 1000.0f;
constant const float stiffness = 1e5f;
constant const float dt = 1e-4f;
constant const float2 g = float2(0.0f, -9.81f);
constant const float gravityK = 1e5f;
constant const float viscosityCoefficient = 1.0f;
constant const float nearStiffness = 1e-6 * stiffness;

// Precomputed constants
constant float h2 = h * h;
constant float h3 = h2 * h;
constant float h4 = h2 * h2;
constant float h5 = h2 * h3;
constant float h8 = h5 * h3;

// Viscosity Laplacian Kernel - Laplacian of
inline float ViscosityLaplacianKernel(float r)
{
    return (20.0f / (PI * h5)) * (h - r);
}

// Pressure Gradient Kernel - Gradient of Spiky kernel 2D
inline float2 PressureGradientKernel(float2 vec, float r)
{
    if (r > 0.0f){
        float h_minus_dist = h - r;
        float coeff = (30.0f / (PI * h5)) * h_minus_dist * h_minus_dist;
        return -coeff * vec / r;
    }
    return float2(0, 0);
}

// Near-Pressure Gradient Kernel
inline float2 NearPressureGradientKernel(float2 vec, float r)
{
    if (r > 0.0f){
        float h_minus_dist = h - r;
        float coeff = (10.0f / (PI * h5)) * h_minus_dist * h_minus_dist * h_minus_dist;
        return -coeff * vec / r;
    }
    return float2(0, 0);
}

// Density Kernel - Polynomial kernel 2D
inline float DensityKernel(float r)
{
    float h2_minus_r2 = h2 - r * r;
    float h2_minus_r2_cubed = h2_minus_r2 * h2_minus_r2 * h2_minus_r2;
    return (4.0f / (PI * h8)) * h2_minus_r2_cubed;
}

#endif /* KERNEL_H */
