shader_type canvas_item;
// The sun's thin rim light on a character part. The part's triangles are drawn twice in one
// array: first a copy flagged UV.x = 1 that is pushed a little toward the sun (in WORLD pixels, so
// it stays on the sun side however the part is turned or mirrored) and tinted with the rim colour,
// then the part itself on top. Only the sliver of the copy that sticks out past the part shows.

uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.5, 0.9);
uniform vec2 rim_offset = vec2(0.8, -1.0);

void vertex() {
	if (UV.x > 0.5) {
		// Undo the part's own rotation, scale and mirroring for the offset (2x2 inverse).
		vec2 a = MODEL_MATRIX[0].xy;
		vec2 b = MODEL_MATRIX[1].xy;
		float det = a.x * b.y - a.y * b.x;
		if (abs(det) > 0.0001) {
			vec2 local = vec2(b.y * rim_offset.x - b.x * rim_offset.y, -a.y * rim_offset.x + a.x * rim_offset.y) / det;
			VERTEX += local;
		}
	}
}

void fragment() {
	if (UV.x > 0.5) {
		COLOR = vec4(rim_color.rgb, rim_color.a * COLOR.a);
	}
}
