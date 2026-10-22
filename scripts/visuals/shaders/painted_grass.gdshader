shader_type canvas_item;
uniform float wind = 0.4;
uniform float time = 0.0;
uniform float motion = 1.0;
void vertex() {
	float root = clamp((1020.0 - VERTEX.y) / 250.0, 0.0, 1.0);
	VERTEX.x += sin(time * 1.4 + VERTEX.x * 0.005) * wind * 9.0 * root * motion;
}
