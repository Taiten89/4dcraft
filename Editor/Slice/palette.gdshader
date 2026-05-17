shader_type canvas_item;

const float CARET_WIDTH = 0.005;

uniform int selected_i;
uniform int palette_size;
uniform sampler2D palette;
uniform vec3 bg_c;
varying vec3 bg_c_;


void vertex ()
{
	bg_c_ = vec3(1.0,1.0,1.0) - bg_c;
}


void fragment ()
{
	float t = UV.x;
	float selected_t = float(selected_i) / float(palette_size-1);

	if (abs(t-selected_t) < CARET_WIDTH)
		COLOR = vec4(bg_c_, 1.0);
	else
	{
		vec4 c = texture(palette, vec2(t, 0.5));
		vec3 c_ = mix(bg_c, c.rgb, c.a);
		COLOR = vec4(c_, 1.0);
	}
}
