shader_type canvas_item;

const float CARET_WIDTH = 0.005;

uniform int selected_i;
uniform int palette_size;
uniform sampler2D palette;

void fragment ()
{
	float t = UV.x;
	float selected_t = float(selected_i) / float(palette_size-1);

	if (abs(t-selected_t) < CARET_WIDTH)
		COLOR = vec4(0.5,0.5,0.5, 1.0);
	else
		COLOR = texture(palette, vec2(t, 0.5));
}
