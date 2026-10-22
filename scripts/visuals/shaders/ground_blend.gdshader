shader_type canvas_item;
#include "res://scripts/visuals/shaders/world_grade.gdshaderinc"
uniform bool village = false;
varying vec4 tint;
void vertex() { tint = COLOR; }
// A single painted surface continues into the foreground. Only its upper edge
// feathers into the scenery; there is no separately stretched lower strip.
void fragment() {
	vec4 paint = village ? village_grade(textureLod(TEXTURE, UV, 1.8), 3.0) : texture(TEXTURE, UV);
	COLOR = paint * tint;
	COLOR.a *= smoothstep(0.06, 0.18, UV.y);
}
