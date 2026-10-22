// Atmospheric separation is restricted to scenery, never applied to units.
vec4 village_grade(vec4 paint, float depth_kind) {
	float luminance = dot(paint.rgb, vec3(0.2126, 0.7152, 0.0722));
	float contrast = depth_kind > 2.5 ? 0.34 : 0.48;
	float calm = (luminance - 0.35) * contrast + (depth_kind > 2.5 ? 0.25 : 0.29);
	vec3 chroma = paint.rgb - vec3(luminance);
	paint.rgb = vec3(calm) + chroma * 0.18;
	// A muted smoke veil compresses detail while leaving the painted silhouettes.
	paint.rgb = mix(paint.rgb, vec3(0.28, 0.265, 0.25), depth_kind < 2.5 ? 0.16 : 0.06);
	return paint;
}
