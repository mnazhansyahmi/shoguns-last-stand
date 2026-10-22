shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear;
uniform float motion = 1.0;
uniform float wind = 0.4;
varying float phase;
void vertex() { phase = COLOR.r * 6.283185; COLOR = vec4(1.0); }
void fragment() {
	float mask = texture(TEXTURE, UV).a * (1.0 - UV.y);
	vec2 shift = vec2(sin(UV.y * 28.0 - TIME * 2.8 + phase), cos(UV.x * 18.0 + TIME * 1.9 + phase));
	COLOR = vec4(texture(screen, SCREEN_UV + shift * mask * 0.0012 * motion).rgb, mask * 0.45);
}
