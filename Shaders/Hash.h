//
//  Hash.h
//  SPH
//
//  Created by Pierre joly on 02/11/2024.
//

#ifndef Hash_h
#define Hash_h

// Constants used for hashing
constant const uint hashK1 = 15823;
constant const uint hashK2 = 9737333;

// Helper function

constant const int2 offsets2D[9] =
{
    int2(-1, 1),
    int2(0, 1),
    int2(1, 1),
    int2(-1, 0),
    int2(0, 0),
    int2(1, 0),
    int2(-1, -1),
    int2(0, -1),
    int2(1, -1),
};

// Convert floating point position into an integer cell coordinate
uint2 GetCell2D(float2 position, float radius)
{
    return (uint2)floor(position / radius);
}

// Hash cell coordinate to a single unsigned integer
uint HashCell2D(uint2 cell)
{
    uint a = cell.x * hashK1;
    uint b = cell.y * hashK2;
    return (a + b);
}

uint KeyFromHash(uint hash, uint tableSize)
{
    return hash % tableSize;
}

#endif /* Hash_h */
