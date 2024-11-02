// InitPosition.metal

#include <metal_stdlib>
using namespace metal;

#include "Common.h"

// Compute shader kernel to initialize particle positions
kernel void init_position(device float2 *positionBuffer [[buffer(PositionBuffer)]],
                          device float2 *positionKBuffer [[buffer(PositionKBuffer)]],
                          constant const InitPositionConstants &constants [[buffer(ConstantBuffer)]],
                          uint id [[thread_position_in_grid]])
{
    if (id >= constants.particleNumber) {
        return;
    }

    // Calculate grid dimensions (assuming a square grid)
    uint gridSize = uint(sqrt((float)constants.particleNumber));
    uint gridWidth = gridSize;
    uint gridHeight = gridSize;

    // Calculate grid spacing
    float gridSpacingX = constants.viewWidth / float(gridWidth);
    float gridSpacingY = constants.viewHeight / float(gridHeight);
    float gridSpacing = min(gridSpacingX, gridSpacingY);

    // Compute x and y indices in the grid
    uint x = id % gridWidth;
    uint y = id / gridWidth;

    // Calculate positions so that particles are centered in each cell
    float posX = float(x) * gridSpacing - constants.viewWidth / 2.0;
    float posY = float(y) * gridSpacing - constants.viewHeight / 2.0;
    float2 position = float2(posX, posY);

    // Write the position to the buffer
    positionBuffer[id] = position;
    positionKBuffer[id] = position;
}
