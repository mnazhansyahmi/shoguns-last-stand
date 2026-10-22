shader_type canvas_item;
uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;
void vertex() {
	vec3 w = COLOR.rgb;
	float hair = sin(motion_time * 1.5 + UV.x * 8.0) * 6.0;
	float sash = sin(motion_time * 1.15 + UV.x * 6.0 - 0.7) * 8.0 + sin(motion_time * 2.2 - UV.x * 8.0) * 1.5;
	float hem = sin(motion_time * 0.85 + UV.x * 5.0 - 1.4) * 4.0;
	float cloth = dot(w, vec3(hair, sash, hem));
	VERTEX += vec2(cloth, cloth * 0.24) * motion_amount;
	// Free tips follow the body with different lags; soles remain anchored.
	float planted = 1.0 - smoothstep(0.73, 0.90, UV.y);
	float body = smoothstep(0.72, 0.77, UV.x) * planted;
	VERTEX.y -= sin(motion_time * 1.65) * 1.5 * body * motion_amount;
	VERTEX.x += sin(motion_time * 0.37) * 1.4 * body * motion_amount;
	// Rare small head turn, blended to neutral at the neck. No limb rig.
	float beat = mod(motion_time, 17.0);
	float turn = smoothstep(13.0, 13.7, beat) * (1.0 - smoothstep(14.3, 15.0, beat));
	float head = smoothstep(0.74, 0.77, UV.x) * (1.0 - smoothstep(0.84, 0.87, UV.x)) * (1.0 - smoothstep(0.18, 0.23, UV.y));
	vec2 relative = VERTEX - vec2(1340.0, 173.0);
	VERTEX += vec2(-relative.y, relative.x) * turn * head * 0.012 * motion_amount;
	COLOR = vec4(1.0);
}
void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	// Reject sub-byte extraction dust, preserving fine hair alpha.
	if (paint.a < 0.012) discard;
	vec2 hilt = vec2(0.715, 0.53);
	vec2 blade = vec2(0.54, 0.76) - hilt;
	float along = dot(UV - hilt, blade) / dot(blade, blade);
	float distance_to_blade = length(UV - (hilt + clamp(along, 0.0, 1.0) * blade));
	float travel = (mod(motion_time, 13.0) - 10.5) / 1.5;
	float glint = (1.0 - smoothstep(0.0006, 0.0022, distance_to_blade)) * exp(-pow((along - travel) * 32.0, 2.0));
	glint *= step(0.0, travel) * step(travel, 1.0) * step(0.0, along) * step(along, 1.0);
	paint.rgb += vec3(0.45, 0.43, 0.36) * glint * motion_amount;
	COLOR = paint;
}
