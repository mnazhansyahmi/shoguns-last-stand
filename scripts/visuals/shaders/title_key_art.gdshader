shader_type canvas_item;
uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;

void vertex() {
	vec3 weights = COLOR.rgb;
	float hair = sin(motion_time * 1.25 + UV.x * 8.0) * 7.0;
	float sash = sin(motion_time * 1.0 + UV.x * 6.0) * 8.0;
	float hem = sin(motion_time * 0.8 + UV.x * 5.0) * 5.0;
	VERTEX.x += dot(weights, vec3(hair, sash, hem)) * motion_amount;
	VERTEX.y += dot(weights, vec3(hair * 0.3, sash * 0.4, hem * 0.4)) * motion_amount;
}

void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	vec2 a = vec2(0.252, 0.611);
	vec2 b = vec2(0.031, 0.843);
	vec2 blade = b - a;
	float along = clamp(dot(UV - a, blade) / dot(blade, blade), 0.0, 1.0);
	float distance = length(UV - (a + blade * along));
	float moving = fract(motion_time * 0.07);
	float glint = (1.0 - smoothstep(0.001, 0.003, distance)) *
		(1.0 - smoothstep(0.01, 0.055, abs(along - moving)));
	paint.rgb = mix(paint.rgb, vec3(1.0, 0.96, 0.84), glint * 0.65 * motion_amount);
	paint.a *= smoothstep(0.02, 0.08, paint.a);
	COLOR = paint;
}
