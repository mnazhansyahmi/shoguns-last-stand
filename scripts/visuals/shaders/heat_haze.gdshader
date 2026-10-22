shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
	float edge = smoothstep(0.0, 0.22, UV.x) * (1.0-smoothstep(0.78,1.0,UV.x));
	edge *= smoothstep(0.0,0.2,UV.y) * (1.0-smoothstep(0.75,1.0,UV.y));
	vec2 offset = vec2(sin(UV.y * 26.0 - TIME * 4.1) * 0.0012, 0.0) * edge;
	COLOR = vec4(texture(screen, SCREEN_UV + offset).rgb, edge * 0.28);
}
