//
//  ShaderDefinitions.h
//  shaders
//
//  Created by William Scheirey on 10/9/23.
//

#include <simd/simd.h>

#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))


typedef struct {
    vector_float2 pos;
    
    vector_float2 textureCoordinate;
} Vertex;

#endif /* ShaderDefinitions_h */
