shader_type canvas_item;
uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;
void vertex() {
	vec3 weight = COLOR.rgb;
	float breath = sin(motion_time * 1.38);
	float breeze = sin(motion_time * 2.1 + UV.x * 5.0 - UV.y * 3.0);
	float ripple = sin(motion_time * 3.5 - UV.x * 9.0 + UV.y * 6.0);
	// Source-pixel displacements: independent free edges, no whole-image bob.
	VERTEX.x += motion_amount * (weight.r * breath * 2.5 + weight.g * (breeze * 21.0 + ripple * 7.0) + weight.b * (breeze * 24.0 + ripple * 9.0));
	VERTEX.y += motion_amount * (-weight.r * breath * 5.0 + weight.g * ripple * 15.0 + weight.b * ripple * 12.0);
	COLOR = vec4(1.0);
}
void fragment() {
	COLOR = texture(TEXTURE, UV);
}
