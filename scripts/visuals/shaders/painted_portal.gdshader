shader_type canvas_item;
uniform float region_x = 0.0;
uniform float motion = 1.0;
void fragment() {
	vec2 p = vec2((UV.x - region_x) * 2.0, UV.y);
	float inside = (1.0 - smoothstep(0.15, 0.32, abs(p.x - 0.5))) * smoothstep(0.27, 0.43, p.y) * (1.0 - smoothstep(0.80, 0.9, p.y));
	vec2 uv = UV + vec2(sin(p.y * 22.0 - TIME * 1.9), cos(p.x * 19.0 + TIME * 1.3)) * vec2(0.005, 0.004) * inside * motion;
	COLOR = texture(TEXTURE, uv);
}
