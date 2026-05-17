#[compute]
#version 460

#include "Includes/defines.glslinc"

layout
    (local_size_x = LOCAL_SIZE_X,
     local_size_y = LOCAL_SIZE_Y,
     local_size_z = 1)
    in;
layout (r32f, set = 0, binding = 1) uniform image2D data;

#include "Includes/numbers.glslinc"
NUMBER_T num_buffers[];
const int POS0=0, POS1=1, POS2=2, POS3=3,
          TMP0=4;

#include "Includes/uniform_struct.glslinc"
#include "Includes/operations/operations.glslinc"
#include "Modes/default.glslinc"
#include "Includes/position.glslinc"

const int N_NUM_BUFFERS = 4 + max(N_TMP_BUFFERS, N_TMP_BUFFERS_POSITION);
NUMBER_T num_buffers[N_NUM_BUFFERS];

#ifdef USE_FIXED
#include "Includes/operations/fixed_nums/bits.glslinc"
#include "Includes/operations/fixed_nums/fixed_nums.glslinc"
#else
// works for DOUBLES as well
#include "Includes/operations/floats.glslinc"
#endif


void main ()
{
    const uint
        X_ = gl_GlobalInvocationID.x,
        Y_ = gl_GlobalInvocationID.y;
    const int X=int(X_), Y=int(Y_);

    if(X >= W || Y >= H)
        return;

    if (X % SUBSAMPLING != subsampling_step % SUBSAMPLING)
        return;
    if (Y % SUBSAMPLING != subsampling_step / SUBSAMPLING)
        return;

    make_position(X, Y);
    int n = compute();
    imageStore(data, ivec2(X,Y), vec4(n));
}
