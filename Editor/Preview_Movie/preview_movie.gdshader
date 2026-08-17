shader_type canvas_item;

uniform sampler2D fractal_img;
uniform vec3 bg_c;


void fragment ()
{
	vec4 f = texture(fractal_img, UV);
	vec3 c = mix(bg_c, f.rgb, f.a);
	COLOR = vec4(c, 1);
}
