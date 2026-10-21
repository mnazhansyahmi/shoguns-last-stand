shader_type canvas_item;
uniform float motion_time = 0.0;
uniform float motion_amount = 1.0;

void vertex() {
	vec3 weights = COLOR.rgb;
	float hair = sin(motion_time * 1.25 + UV.x * 8.0) * 12.0;
	float sash = sin(motion_time * 1.0 + UV.x * 6.0) * 16.0;
	float hem = sin(motion_time * 0.8 + UV.x * 5.0) * 8.0;
	VERTEX.x += dot(weights, vec3(hair, sash, hem)) * motion_amount;
	VERTEX.y += dot(weights, vec3(hair * 0.3, sash * 0.4, hem * 0.4)) * motion_amount;
}

void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	// Dusk ambient and warm moon light share the backdrop's lighting direction.
	// Compress bright cloth values so it no longer reads as a studio-lit cutout.
	float value = dot(paint.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 dusk = paint.rgb * vec3(0.82, 0.74, 0.82);
	vec3 moonlit = paint.rgb * vec3(1.02, 0.91, 0.78);
	paint.rgb = mix(dusk, moonlit, smoothstep(0.10, 0.82, value) * 0.7);
	paint.rgb = mix(vec3(0.071, 0.048, 0.085), paint.rgb, smoothstep(0.0, 0.17, value));
	float neighbour = texture(TEXTURE, UV - TEXTURE_PIXEL_SIZE * vec2(3.0, 3.0)).a;
	float rim = smoothstep(0.05, 0.65, paint.a - neighbour) * (1.0 - smoothstep(0.35, 0.82, UV.y));
	paint.rgb = mix(paint.rgb, vec3(0.88, 0.63, 0.40), rim * 0.28);
	// Near the rock the same cool ink bounce light ties sandals and cloth to it.
	paint.rgb *= 1.0 - smoothstep(0.85, 0.99, UV.y) * 0.18;
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
