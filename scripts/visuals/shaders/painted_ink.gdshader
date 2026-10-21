shader_type canvas_item;
// Alpha-aware sun-side edge for painted textures, without procedural UV flags.
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.5, 0.5);
uniform vec2 rim_offset = vec2(0.8, -1.0);
varying vec4 art_tint;
void vertex() {
	art_tint = COLOR;
}
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float neighbour = texture(TEXTURE, UV - normalize(rim_offset) * TEXTURE_PIXEL_SIZE * 1.5).a;
	float edge = max(0.0, ink.a - neighbour) * rim_color.a;
	float alpha = ink.a * smoothstep(0.02, 0.07, ink.a);
	COLOR = vec4(mix(ink.rgb, rim_color.rgb, edge * 0.35), alpha) * art_tint;
}
