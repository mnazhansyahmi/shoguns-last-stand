shader_type canvas_item;
#include "res://scripts/visuals/shaders/world_grade.gdshaderinc"
uniform bool village = false;
uniform float depth_kind = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 paint = village ? textureLod(TEXTURE, UV, 1.35) : texture(TEXTURE, UV);
	COLOR = (village ? village_grade(paint, depth_kind) : paint) * tint;
}
