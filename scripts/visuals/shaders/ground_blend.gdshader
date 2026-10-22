shader_type canvas_item;
// A single painted surface continues into the foreground. Only its upper edge
// feathers into the scenery; there is no separately stretched lower strip.
void fragment() {
	COLOR.a *= smoothstep(0.06, 0.18, UV.y);
}
