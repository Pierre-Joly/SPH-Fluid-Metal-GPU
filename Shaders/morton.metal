#include <metal_stdlib>
using namespace metal;

// Interleaves the bits of x and y to form a 32-bit Morton code.
// Positions should be normalized or scaled so they fit within [0, 1) or some known domain.
inline uint morton2D(float x, float y)
{
    // Example: scale x,y into 16-bit range:
    uint ix = (uint)clamp(x * 65535.0, 0.0, 65535.0);
    uint iy = (uint)clamp(y * 65535.0, 0.0, 65535.0);

    // Interleave bits. This is a simple function that places bits of ix, iy
    // into the final code as x0,y0,x1,y1,..., etc. (There are many ways to do this.)
    // For brevity, we’ll do a small loop. In high-performance code,
    // you might unroll or use precomputed lookups.

    uint code = 0;
    for (uint i = 0; i < 16; i++) {
        code |= ((ix & (1u << i)) << i) | ((iy & (1u << i)) << (i + 1));
    }
    return code;
}

struct MortonPair {
    uint code;  // Morton code
    uint id;    // Original particle ID
};

kernel void computeMortonCodes2D(
    device const float2*   positions  [[ buffer(0) ]],
    device MortonPair*     outCodes   [[ buffer(1) ]],
    constant uint&         numParticles [[ buffer(2) ]],
    uint                   gid        [[ thread_position_in_grid ]],
    uint                   size       [[ threads_per_grid ]]
)
{
    for (uint i = gid; i < numParticles; i += size) {
        float2 pos = positions[i];
        
        // Compute 2D Morton code from pos.x and pos.y
        uint mcode = morton2D(pos.x, pos.y);
        
        // Write out (code, id)
        outCodes[i].code = mcode;
        outCodes[i].id   = i;  // store the original index of the particle
    }
}
