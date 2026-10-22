shader_type canvas_item;
uniform float motion = 1.0;
varying float phase;
void vertex() { phase = COLOR.r * 6.283185; COLOR = vec4(1.0); }
void fragment() {
	vec2 p = UV;
	float free_tip = 1.0 - p.y;
	p.x += sin(TIME * 0.4 + phase + p.y * 8.0) * 0.035 * free_tip * motion;
	p.y += sin(TIME * 0.6 + phase + p.y * 9.0) * 0.025 * free_tip * motion;
	COLOR = texture(TEXTURE, clamp(p, vec2(0.002), vec2(0.998)));
	COLOR.a *= 0.48 + sin(TIME * 0.7 + phase) * 0.07 * motion;
}
