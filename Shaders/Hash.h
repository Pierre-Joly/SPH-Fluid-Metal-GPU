//
//  Hash.h
//  SPH
//
//  Created by Pierre joly on 02/11/2024.
//

#ifndef Hash_h
#define Hash_h

#include "Kernel.h"

// Define maximum particles per cell to prevent buffer overflow
constant const uint maxParticlesPerCell = 200;
constant const float cellSize = h/2;
constant const float2 minBound = float2(-0.5, -0.5);
constant const float2 maxBound = float2(0.5, 0.5);
constant const uint gridDimX = uint((maxBound.x - minBound.x) / cellSize);
constant const uint gridDimY = uint((maxBound.y - minBound.y) / cellSize);
constant const uint2 gridDims = uint2(gridDimX, gridDimY);
constant const uint totalGridCells = (gridDims.x + 1) * (gridDims.y + 1);

// Helper function to compute grid hash from grid indices
inline uint computeHash(uint2 gridIndex) {
    return gridIndex.y * gridDims.x + gridIndex.x;
}

#endif /* Hash_h */
