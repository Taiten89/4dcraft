#version 460

layout (local_size_x=16, local_size_y=16, local_size_z=1) in;

layout(set = 0, binding = 0, std430)
restrict readonly buffer
Uniform_Struct
{
    int W, H;
    int subsampling, subsampling_step;
}
uniform_struct;
#define W uniform_struct.W
#define H uniform_struct.H
#define subsampling uniform_struct.subsampling
#define subsampling_step uniform_struct.subsampling_step

layout (rgba32f, set = 0, binding = 1) uniform image2D source;
layout (rgba8, set = 0, binding = 2) uniform image2D target;

#define X int(gl_GlobalInvocationID.x)
#define Y int(gl_GlobalInvocationID.y)
ivec2 XY;


void main ()
{
    XY = ivec2(X, Y);
    int X_mod = X % subsampling;
    int Y_mod = Y % subsampling;

    if(X >= W || Y >= H)
        return;

    int XY_as_step = X_mod + Y_mod*subsampling;
    if (XY_as_step <= subsampling_step)
    {
        vec4 img_c = imageLoad(source, XY);
        imageStore(target, XY, img_c);
        return;
    }

    vec4 img_c = vec4(0,0,0,0);
    ivec2 XY_step0 = ivec2(X - X_mod, Y - Y_mod);
    for (int interp_step=0; interp_step<=subsampling_step; interp_step++)
    {
        int X_offset = interp_step % subsampling;
        int Y_offset = interp_step / subsampling;
        ivec2 XY_interp = XY_step0 + ivec2(X_offset, Y_offset);
        img_c += imageLoad(source, XY_interp);
    }
    img_c /= subsampling_step + 1;

    imageStore(target, XY, img_c);
}
