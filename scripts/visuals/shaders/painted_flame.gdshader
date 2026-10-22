shader_type canvas_item;
uniform vec4 uv_rect = vec4(0.0, 0.0, 0.4, 0.52);
uniform float motion = 1.0;
uniform float phase = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = (UV - uv_rect.xy) / uv_rect.zw;
	float root = pow(1.0 - p.y, 1.5);
	vec2 shift = vec2(sin(p.y * 13.0 - TIME * 4.1 + phase) * 0.023,
		sin(p.x * 11.0 + TIME * 3.7 + phase) * 0.012) * root * motion;
	vec2 sample_uv = uv_rect.xy + clamp(p + shift, vec2(0.002), vec2(0.998)) * uv_rect.zw;
	COLOR = texture(TEXTURE, sample_uv) * tint;
	COLOR.rgb *= 1.0 + sin(TIME * 6.1 + phase) * 0.07 * motion;
}
