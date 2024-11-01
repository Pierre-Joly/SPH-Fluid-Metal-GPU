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
constant float PI = 3.1415927f;
constant float h = 0.05f;
constant const float volume = 0.5;
constant const float restDensity = 1000;

// Precomputed constants
constant float h2 = h * h;
constant float h3 = h2 * h;
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
    if (r > 0) {
        float h_minus_dist = h - r;
        float coeff = (30.0f / (PI * h5)) * h_minus_dist * h_minus_dist;
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
