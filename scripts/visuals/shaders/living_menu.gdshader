shader_type canvas_item;
uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;
void vertex() {
	vec3 w = COLOR.rgb;
	float hair = sin(motion_time * 1.5 + UV.x * 8.0) * 5.0;
	float sash = sin(motion_time * 1.1 + UV.x * 6.0) * 8.0;
	float hem = sin(motion_time * 0.8 + UV.x * 5.0) * 4.0;
	VERTEX.x += dot(w, vec3(hair, sash, hem)) * motion_amount;
	VERTEX.y += dot(w, vec3(hair, sash, hem)) * 0.28 * motion_amount;
	COLOR = vec4(1.0);
}
void fragment() {
	vec2 uv = UV;
	float clouds = (1.0 - smoothstep(0.24, 0.38, UV.y)) * (1.0 - smoothstep(0.60, 0.70, UV.x));
	uv.x += sin(motion_time * 0.08) * 0.005 * clouds * motion_amount;
	vec4 paint = texture(TEXTURE, uv);
	float moon = 1.0 - smoothstep(0.8, 1.0, length((UV - vec2(0.738, 0.18)) / vec2(0.09, 0.16)));
	paint.rgb *= 1.0 + sin(motion_time * 0.55) * 0.025 * moon * motion_amount;
	COLOR = paint;
}
