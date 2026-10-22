shader_type canvas_item;
uniform float motion = 1.0;
uniform float wind = 0.4;
varying float phase;
void vertex() { phase = COLOR.r * 6.283185; COLOR = vec4(1.0); }
void fragment() {
	vec2 p = UV;
	float free_tip = 1.0 - p.y;
	p.x += sin(TIME * 0.4 + phase + p.y * 8.0) * 0.035 * free_tip * motion;
	p.x -= free_tip * wind * 0.12 * motion;
	// Two overlapping upward flows cross-fade before either wraps, so the
	// plume rises continuously rather than oscillating up and down.
	float flow = fract(TIME * 0.09 * motion + phase / 6.283185);
	vec2 a = p + vec2(0.0, flow * 0.18 * free_tip);
	vec2 b = p + vec2(0.0, fract(flow + 0.5) * 0.18 * free_tip);
	COLOR = mix(texture(TEXTURE, clamp(a, vec2(0.002), vec2(0.998))),
		texture(TEXTURE, clamp(b, vec2(0.002), vec2(0.998))), abs(0.5 - flow) * 2.0);
	COLOR.a *= 0.48 + sin(TIME * 0.7 + phase) * 0.07 * motion;
	COLOR.rgb *= mix(vec3(0.7, 0.66, 0.62), vec3(1.0, 0.52, 0.24), pow(UV.y, 3.0) * 0.65);
}
