shader_type canvas_item;
uniform float motion = 1.0;
varying vec2 site;
void vertex() { site = COLOR.rg; COLOR = vec4(1.0); }
void fragment() {
	int cell = int(round(site.y * 3.0));
	vec4 r = vec4(0.0, 0.0, 0.4, 0.52);
	if (cell == 1) r = vec4(0.4, 0.0, 0.6, 0.52);
	if (cell == 2) r = vec4(0.0, 0.52, 0.4, 0.48);
	if (cell == 3) r = vec4(0.4, 0.52, 0.6, 0.48);
	vec2 p = (UV - r.xy) / r.zw;
	float phase = site.x * 6.283185;
	float speed = 3.1 + site.x * 1.7;
	float root = pow(1.0 - p.y, 1.5);
	p.x += sin(p.y * 13.0 - TIME * speed + phase) * 0.032 * root * motion;
	p.y += sin(p.x * 11.0 + TIME * speed * 0.83 + phase) * 0.012 * root * motion;
	COLOR = texture(TEXTURE, r.xy + clamp(p, vec2(0.003), vec2(0.997)) * r.zw);
	COLOR.rgb *= 1.0 + sin(TIME * speed * 1.7 + phase) * 0.09 * motion;
}
