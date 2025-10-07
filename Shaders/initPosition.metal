#include <metal_stdlib>
using namespace metal;

#include "Common.h"

// Compute shader kernel to initialize particle positions
kernel void init_position(device float2 *positionBuffer [[buffer(PositionBuffer)]],
                          device float2 *positionKBuffer [[buffer(PositionKBuffer)]],
                          constant uint &numParticles [[buffer(NumParticlesBuffer)]],
                          constant float &viewWidth [[buffer(ViewWidthBuffer)]],
                          constant float &viewHeight [[buffer(ViewHeightBuffer)]],
                          uint id [[thread_position_in_grid]])
{
    if (id >= numParticles) {
        return;
    }

    // Calculate grid dimensions (assuming a square grid)
    uint gridSize = uint(sqrt((float)numParticles));
    uint gridWidth = gridSize;
    uint gridHeight = gridSize;

    // Calculate grid spacing
    float gridSpacingX = viewWidth / float(gridWidth);
    float gridSpacingY = viewHeight / float(gridHeight);
    float gridSpacing = min(gridSpacingX, gridSpacingY);

    // Compute x and y indices in the grid
    uint x = id % gridWidth;
    uint y = id / gridWidth;

    // Calculate positions so that particles are centered in each cell
    float posX = float(x) * gridSpacing - viewWidth / 2.0;
    float posY = float(y) * gridSpacing - viewHeight / 2.0;
    float2 position = float2(posX, posY);

    // Write the position to the buffer
    positionBuffer[id] = position;
    positionKBuffer[id] = position;
}
