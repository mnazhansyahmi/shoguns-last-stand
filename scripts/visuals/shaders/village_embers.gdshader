shader_type canvas_item;
render_mode blend_add;
uniform float motion = 1.0;
uniform float wind = 0.4;
varying float phase;
void vertex() { phase = COLOR.r; COLOR = vec4(1.0); }
void fragment() {
	float sparks = 0.0;
	for (int i = 0; i < 4; i++) {
		float age = fract(TIME * (0.21 + float(i) * 0.023) * motion + phase + float(i) * 0.27);
		vec2 at = vec2(0.5 + sin(float(i) * 4.1 + phase) * 0.15 + age * wind * 0.2, 1.0 - age);
		float dot_size = length((UV - at) * vec2(1.0, 0.65));
		sparks += (1.0 - smoothstep(0.003, 0.013, dot_size)) * sin(age * 3.14159);
	}
	COLOR = vec4(1.0, 0.45, 0.12, sparks * 0.75);
}
