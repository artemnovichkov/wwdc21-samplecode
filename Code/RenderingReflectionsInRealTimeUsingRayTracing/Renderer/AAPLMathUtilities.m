/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of vector, matrix, and quaternion math utility functions useful for 3D graphics
 rendering with Metal

 Metal uses column-major matrices and column-vector inputs.

    linearIndex     cr              example with reference elements
     0  4  8 12     00 10 20 30     sx  10  20   tx
     1  5  9 13 --> 01 11 21 31 --> 01  sy  21   ty
     2  6 10 14     02 12 22 32     02  12  sz   tz
     3  7 11 15     03 13 23 33     03  13  1/d  33

  The "cr" names are for <column><row>
*/

#import "AAPLMathUtilities.h"

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },
        { 0,   1,  0,  0 },
        { 0,   0,  1,  0 },
        { tx, ty, tz,  1 }
    }};
}

matrix_float4x4 matrix4x4_translationv(vector_float3 v)
{
    return matrix4x4_translation(v[0], v[1], v[2]);
}

matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis)
{
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {{
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},
        {                   0,                   0,                   0, 1}
    }};
}

MTLPackedFloat4x3 matrix4x4_drop_last_row( matrix_float4x4 m )
{
    MTLPackedFloat4x3 m4x3 = {
        (MTLPackedFloat3){ m.columns[0].x, m.columns[0].y, m.columns[0].z },
        (MTLPackedFloat3){ m.columns[1].x, m.columns[1].y, m.columns[1].z },
        (MTLPackedFloat3){ m.columns[2].x, m.columns[2].y, m.columns[2].z },
        (MTLPackedFloat3){ m.columns[3].x, m.columns[3].y, m.columns[3].z }
    };
    return m4x3;
}

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },
        {  0,  ys,          0,  0 },
        {  0,   0,         zs, -1 },
        {  0,   0, nearZ * zs,  0 }
    }};
}
