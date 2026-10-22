shader_type canvas_item;
#include "res://scripts/visuals/shaders/world_grade.gdshaderinc"
uniform bool village = false;
varying vec4 tint;
uniform float wind = 0.4;
uniform float time = 0.0;
uniform float motion = 1.0;
void vertex() {
	tint = COLOR;
	float root = clamp((1020.0 - VERTEX.y) / 250.0, 0.0, 1.0);
	VERTEX.x += sin(time * 1.4 + VERTEX.x * 0.005) * wind * 9.0 * root * motion;
}
void fragment() {
	vec4 paint = village ? village_grade(textureLod(TEXTURE, UV, 1.2), 4.0) : texture(TEXTURE, UV);
	COLOR = paint * tint;
}
