shader_type canvas_item;
render_mode blend_add;
uniform float motion = 1.0;
varying float phase;
void vertex() { phase = COLOR.r * 6.283185; COLOR = vec4(1.0); }
void fragment() {
	float flicker = 0.28 + (sin(TIME * 5.2 + phase) * 0.035 + sin(TIME * 8.7 + phase * 2.3) * 0.02) * motion;
	COLOR = vec4(1.0, 0.27, 0.045, texture(TEXTURE, UV).a * flicker);
}
