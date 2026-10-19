shader_type canvas_item;
// Reeds and pampas grass swaying in wind waves. Every vertex carries its sway weight in the
// colour's alpha: 0 at the root of a stalk, 1 at its tip. The tip leans downwind more than the
// middle, and a wave travels along the field so neighbouring stalks bend one after another.

uniform float wind = 0.4;        // current wind strength, 0..1
uniform float time = 0.0;        // seconds
uniform float reach = 38.0;      // how far a tip leans at full wind (layer pixels)

void vertex() {
	float weight = COLOR.a;
	COLOR.a = 1.0;
	float wave = sin(VERTEX.x * 0.0042 - time * 1.3) * 0.5 + 0.5;
	float flutter = sin(VERTEX.x * 0.033 + time * 3.3) * 0.5;
	float lean = wind * (0.3 + 0.7 * wave) + wind * flutter * 0.35 + 0.04 * sin(time * 0.9 + VERTEX.x * 0.011);
	float bend = weight * weight;
	VERTEX.x += bend * reach * lean;
	VERTEX.y += bend * abs(lean) * reach * 0.16;
}
