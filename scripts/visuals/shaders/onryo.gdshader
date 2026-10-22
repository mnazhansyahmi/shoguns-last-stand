shader_type canvas_item;
uniform float motion = 1.0;
uniform float phase = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	float robe = smoothstep(0.20, 0.65, UV.y);
	vec2 uv = UV;
	uv.x += sin(UV.y * 12.0 - TIME * 2.2 + phase) * 0.018 * robe * motion;
	COLOR = texture(TEXTURE, uv) * tint;
}
