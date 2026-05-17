#version 460

layout (local_size_x=16, local_size_y=16, local_size_z=1) in;

layout(set = 0, binding = 0, std430)
restrict readonly buffer
Uniform_Struct
{
    int max_n;
    int palette_size;
    int W, H;
    bool clear;
    float alpha;
    int subsampling, subsampling_step;
}
uniform_struct;
#define max_n uniform_struct.max_n
#define palette_size uniform_struct.palette_size
#define W uniform_struct.W
#define H uniform_struct.H
#define clear uniform_struct.clear
#define alpha uniform_struct.alpha
#define subsampling uniform_struct.subsampling
#define subsampling_step uniform_struct.subsampling_step

layout (r32f, set = 0, binding = 1) uniform image2D data;
layout (rgba8, set = 0, binding = 2) uniform image2D palette;
layout (rgba32f, set = 0, binding = 3) uniform image2D background;
layout (rgba32f, set = 0, binding = 4) uniform image2D target;

#define X int(gl_GlobalInvocationID.x)
#define Y int(gl_GlobalInvocationID.y)
ivec2 XY;


vec4 color_over_color (vec4 FG, vec4 BG)
{
    vec3 rgb = mix(BG.rgb, FG.rgb, FG.a);
    float a = BG.a + FG.a * (1-BG.a);
    return vec4(rgb, a);
}


vec4 background_c ()
{
    if (clear)
        return vec4(0,0,0,0);
    else
        return imageLoad(background, XY);
}


vec4 fractal_c ()
{
    float fractal_t = imageLoad(data, XY).r / max_n;
    float palette_i_f = fractal_t * (palette_size-1);
    int palette_i = int(palette_i_f);

    vec4 fractal_c;
    if (palette_i == palette_size - 1)
        fractal_c = imageLoad(palette, ivec2(palette_i,0));
    else
    {
        float interp = palette_i_f - palette_i;
        vec4 fractal_c0 = imageLoad(palette, ivec2(palette_i,0));
        vec4 fractal_c1 = imageLoad(palette, ivec2(palette_i+1,0));
        fractal_c = mix(fractal_c0, fractal_c1, interp);
    }
    fractal_c.a *= alpha;

    return fractal_c;
}


void main ()
{
    XY = ivec2(X, Y);

    if(X >= W || Y >= H)
        return;

    int X_mod = X % subsampling;
    int Y_mod = Y % subsampling;
    int XY_as_step = X_mod + Y_mod*subsampling;
    if (XY_as_step != subsampling_step)
        return;

    vec4 img_c = color_over_color(fractal_c(), background_c());
    imageStore(target, XY, img_c);
}
