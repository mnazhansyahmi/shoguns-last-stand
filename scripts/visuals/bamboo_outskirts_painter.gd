class_name BambooOutskirtsPainter
extends RefCounted
## Paints the Bamboo Outskirts backdrop (ink wash at sunset) one layer at a time, for
## BackdropLayer._draw(). Coordinates are battlefield world pixels; the ground line is y 880.
## Every layer is seeded, so it looks the same each time it is drawn, and every colour comes from the
## stage's AtmosphereTheme (a golden sunset, a rose dusk, a misty grove...). Layers behind the
## fighters stay light (docs/ART_BIBLE.md, contrast rules); dark near bamboo only frames the edges.
## The reed layers carry each vertex's sway weight in the colour alpha for reed_sway.gdshader.

## New layers are appended so the numbers saved in scenes stay valid.
enum Layer { SKY, MOON, DISTANT_MOUNTAINS, MOUNTAINS, MIST_HIGH, HILLS, BAMBOO_FAR, MIST_LOW,
		BAMBOO_NEAR, GROUND, FRONT_FOG, CLOUDS_HIGH, CLOUDS_LOW, RAYS, REEDS_BACK, REEDS_FRONT }

const GROUND_Y: float = 880.0
const LEFT: float = -900.0
const RIGHT: float = 2800.0
const TOP: float = -700.0
const BOTTOM: float = 1700.0
## Drifting layers repeat every this many pixels (BackdropLayer.tile_width must match).
const FOG_TILE: float = 3600.0
## Where the sun (or moon) hangs, in layer coordinates. The title screen lines up with it.
const SUN_POSITION: Vector2 = Vector2(1480.0, 230.0)


static func paint(ci: CanvasItem, layer: Layer, seed_value: int, theme: AtmosphereTheme = null) -> void:
	var t: AtmosphereTheme = theme if theme != null else Atmosphere.current()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + int(layer) * 104729
	# Shapes collect into one batch (one draw call); it is flushed before soft washes that
	# must draw on top of shapes already added, to keep the layering.
	var b: InkBatch = InkBatch.new()
	match layer:
		Layer.SKY:
			_sky(ci, b, t)
		Layer.MOON:
			_sun(ci, b, t)
		Layer.CLOUDS_HIGH:
			_clouds(b, rng, t, 120.0, 330.0, 7, 1.0)
		Layer.CLOUDS_LOW:
			_clouds(b, rng, t, 380.0, 600.0, 6, 0.75)
		Layer.DISTANT_MOUNTAINS:
			_mountains(ci, b, rng, t, 760.0, 430.0, t.mountain_far.lerp(t.mist, 0.45), 840.0)
		Layer.MOUNTAINS:
			_mountains(ci, b, rng, t, 800.0, 320.0, t.mountain_far, 870.0)
		Layer.MIST_HIGH:
			_mist(ci, b, rng, t, 600.0, 770.0, 18, Vector2(420.0, 900.0), Vector2(60.0, 140.0), Vector2(0.3, 0.5))
		Layer.HILLS:
			_hills(ci, b, rng, t)
		Layer.BAMBOO_FAR:
			_bamboo_far(ci, b, rng, t)
		Layer.MIST_LOW:
			_mist_low(ci, b, rng, t)
		Layer.RAYS:
			_rays(b, rng, t)
		Layer.BAMBOO_NEAR:
			_bamboo_near(ci, b, rng, t)
		Layer.GROUND:
			_ground(ci, b, rng, t)
		Layer.REEDS_BACK:
			_reeds_back(b, rng, t)
		Layer.REEDS_FRONT:
			_reeds_front(b, rng, t)
		Layer.FRONT_FOG:
			_mist(ci, b, rng, t, GROUND_Y - 6.0, GROUND_Y + 26.0, 12, Vector2(320.0, 700.0), Vector2(26.0, 46.0), Vector2(0.08, 0.13))
	b.flush(ci)


## A soft elliptical wash (glow texture with normal blending).
static func soft(ci: CanvasItem, center: Vector2, size: Vector2, color: Color) -> void:
	ci.draw_texture_rect(InkBrush.glow_texture(), Rect2(center - size * 0.5, size), false, color)


# --- Sky, sun, clouds, rays ---------------------------------------------------

## Indigo at the top, through crimson, to gold at the horizon.
static func _sky(ci: CanvasItem, b: InkBatch, t: AtmosphereTheme) -> void:
	var width: float = RIGHT - LEFT
	var upper: Color = t.sky_top.lerp(t.sky_mid, 0.5)
	b.gradient_rect(Rect2(LEFT, TOP, width, 380.0 - TOP), t.sky_top, upper)
	b.gradient_rect(Rect2(LEFT, 380.0, width, 170.0), upper, t.sky_mid)
	b.gradient_rect(Rect2(LEFT, 550.0, width, 170.0), t.sky_mid, t.sky_low)
	b.gradient_rect(Rect2(LEFT, 720.0, width, 140.0), t.sky_low, t.sky_horizon)
	b.gradient_rect(Rect2(LEFT, 860.0, width, BOTTOM - 860.0), t.sky_horizon, t.mist)
	b.flush(ci)
	# The sun's glow spreads along the horizon.
	soft(ci, Vector2(SUN_POSITION.x - 200.0, 790.0), Vector2(3200.0, 300.0), Color(t.sky_horizon.lightened(0.15), 0.4))


static func _sun(ci: CanvasItem, b: InkBatch, t: AtmosphereTheme) -> void:
	var center: Vector2 = SUN_POSITION
	soft(ci, center, Vector2(1500.0, 1500.0), Color(t.sun_halo, 0.2))
	soft(ci, center, Vector2(800.0, 800.0), Color(t.sun_halo, 0.34))
	soft(ci, center, Vector2(380.0, 380.0), Color(t.sun_halo.lightened(0.2), 0.55))
	b.circle(center, t.sun_radius, t.sun_core)
	b.flush(ci)
	if t.eclipse:
		# A dark disc with a burning ring.
		var ring: PackedVector2Array = InkBrush.ellipse_points(center, Vector2(t.sun_radius + 3.0, t.sun_radius + 3.0), 48)
		ring.append(ring[0])
		b.stroke(ring, 7.0, 7.0, t.sun_halo.lightened(0.25))
	else:
		soft(ci, center, Vector2(t.sun_radius * 2.6, t.sun_radius * 2.6), Color(t.sun_core, 0.35))


## Layered clouds: a shaded body with a gold-lit underside (the sun is low), flat below, lumpy above.
static func _clouds(b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme, y_min: float, y_max: float, count: int,
		size_scale: float) -> void:
	for i: int in count:
		var center: Vector2 = Vector2(LEFT + (float(i) + rng.randf_range(0.0, 0.8)) * FOG_TILE / float(count), rng.randf_range(y_min, y_max))
		_cloud(b, rng, t, center, rng.randf_range(420.0, 980.0) * size_scale, rng.randf_range(38.0, 84.0) * size_scale)


static func _cloud(b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme, center: Vector2, width: float, height: float) -> void:
	var steps: int = 18
	var phase: float = rng.randf() * TAU
	var tops: PackedVector2Array = PackedVector2Array()
	var bottoms: PackedVector2Array = PackedVector2Array()
	for k: int in steps + 1:
		var u: float = float(k) / float(steps)
		var x: float = center.x - width * 0.5 + u * width
		var envelope: float = pow(maxf(sin(PI * u), 0.0), 0.7)
		var bump: float = 0.55 + 0.45 * sin(u * 13.0 + phase) * sin(u * 5.0 + phase * 0.5)
		tops.append(Vector2(x, center.y - height * (0.35 + 0.65 * bump) * envelope))
		bottoms.append(Vector2(x, center.y + height * 0.28 * envelope * (0.85 + 0.15 * sin(u * 9.0 + phase))))
	var outline: PackedVector2Array = tops.duplicate()
	for k: int in range(bottoms.size() - 1, -1, -1):
		outline.append(bottoms[k])
	b.fill(outline, Color(t.cloud_shadow, t.cloud_alpha * 0.9))
	# The lit underside fades up into the shaded body.
	var lifted: PackedVector2Array = PackedVector2Array()
	var edge: PackedColorArray = PackedColorArray()
	var fade: PackedColorArray = PackedColorArray()
	for k: int in bottoms.size():
		lifted.append(bottoms[k].lerp(tops[k], 0.55))
		edge.append(Color(t.cloud_lit, t.cloud_alpha * 0.95))
		fade.append(Color(t.cloud_lit, 0.0))
	b.ribbon(bottoms, lifted, edge, fade)
	b.stroke(bottoms, 2.6, 2.6, Color(t.cloud_lit.lightened(0.3), 0.7 * t.cloud_alpha))


## Beams of light from the sun, fanned across the scene and fading out. The layer is drawn
## additively and pulses (RegionBackdrop), so they read as light through fog.
static func _rays(b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	var beams: int = 9
	var centre_angle: float = (Vector2(700.0, 900.0) - SUN_POSITION).angle()
	for i: int in beams:
		var angle: float = centre_angle + lerpf(-0.5, 0.5, (float(i) + rng.randf_range(-0.3, 0.3)) / float(beams - 1))
		var spread: float = rng.randf_range(0.018, 0.042)
		var length: float = rng.randf_range(1300.0, 1900.0)
		var strength: float = rng.randf_range(0.07, 0.15)
		var side: Vector2 = Vector2.from_angle(angle + PI * 0.5)
		var wide_a: PackedVector2Array = PackedVector2Array()
		var wide_b: PackedVector2Array = PackedVector2Array()
		var wide_colors: PackedColorArray = PackedColorArray()
		var core_a: PackedVector2Array = PackedVector2Array()
		var core_b: PackedVector2Array = PackedVector2Array()
		var core_colors: PackedColorArray = PackedColorArray()
		for k: int in 7:
			var u: float = float(k) / 6.0
			var distance: float = 140.0 + u * length
			var middle: Vector2 = SUN_POSITION + Vector2.from_angle(angle) * distance
			var half: float = distance * spread
			var alpha: float = strength * smoothstep(0.0, 0.18, u) * (1.0 - u)
			wide_a.append(middle + side * half)
			wide_b.append(middle - side * half)
			wide_colors.append(Color(t.ray_color, alpha * 0.3))
			core_a.append(middle + side * half * 0.4)
			core_b.append(middle - side * half * 0.4)
			core_colors.append(Color(t.ray_color, alpha))
		b.ribbon(wide_a, wide_b, wide_colors, wide_colors)
		b.ribbon(core_a, core_b, core_colors, core_colors)


# --- Land -----------------------------------------------------------------------

## Peaked ridge: sharp tops from 1 - |sin|, softened by a gentle wave.
static func _ridge_y(x: float, base_y: float, amplitude: float, phases: Vector3) -> float:
	var h: float = 0.58 * pow(1.0 - absf(sin(x * 0.0016 + phases.x)), 1.6)
	h += 0.32 * pow(1.0 - absf(sin(x * 0.0043 + phases.y)), 1.3)
	h += 0.1 * (0.5 + 0.5 * sin(x * 0.021 + phases.z))
	return base_y - amplitude * h


static func _mountains(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme, base_y: float,
		amplitude: float, color: Color, fade_y: float) -> void:
	var phases: Vector3 = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		tops.append(Vector2(x, _ridge_y(x, base_y, amplitude, phases)))
		x += 20.0
	b.ridge_fill(tops, fade_y, color, t.mist)
	b.gradient_rect(Rect2(LEFT, fade_y, RIGHT - LEFT, BOTTOM - fade_y), t.mist, t.mist)
	# A warm light along the ridge where the low sun catches it.
	b.stroke(tops, 3.0, 3.0, color.lerp(t.sky_horizon, 0.35))


static func _mist(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme, y_min: float, y_max: float,
		count: int, width_range: Vector2, height_range: Vector2, alpha_range: Vector2) -> void:
	for i: int in count:
		var center: Vector2 = Vector2(LEFT + (float(i) + rng.randf_range(0.0, 0.8)) * FOG_TILE / float(count),
				rng.randf_range(y_min, y_max))
		soft(ci, center, Vector2(rng.randf_range(width_range.x, width_range.y), rng.randf_range(height_range.x, height_range.y)),
				Color(t.mist, rng.randf_range(alpha_range.x, alpha_range.y)))


static func _hills(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	var phase: float = rng.randf() * TAU
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		var y: float = 790.0 - 70.0 * (0.5 + 0.5 * sin(x * 0.0024 + phase)) - 30.0 * (0.5 + 0.5 * sin(x * 0.0071 + phase * 2.0))
		tops.append(Vector2(x, y))
		x += 24.0
	var pagoda_x: float = 660.0
	var pagoda_y: float = 790.0 - 70.0 * (0.5 + 0.5 * sin(pagoda_x * 0.0024 + phase)) - 30.0 * (0.5 + 0.5 * sin(pagoda_x * 0.0071 + phase * 2.0))
	_pagoda(b, Vector2(pagoda_x, pagoda_y + 6.0), t.mountain_mid)
	b.ridge_fill(tops, 900.0, t.mountain_mid, t.mist)


## A three-tier pagoda silhouette standing on `base`.
static func _pagoda(b: InkBatch, base: Vector2, color: Color) -> void:
	var y: float = base.y
	var widths: Array[float] = [62.0, 52.0, 42.0]
	for tier: int in widths.size():
		var w: float = widths[tier]
		var body_h: float = 34.0 if tier == 0 else 26.0
		b.fill_convex(PackedVector2Array([Vector2(base.x - w * 0.4, y), Vector2(base.x + w * 0.4, y),
				Vector2(base.x + w * 0.36, y - body_h), Vector2(base.x - w * 0.36, y - body_h)]), color)
		y -= body_h
		# Roof with upturned eaves.
		b.fill(PackedVector2Array([Vector2(base.x - w * 0.95, y - 6.0), Vector2(base.x - w * 0.7, y + 1.0),
				Vector2(base.x + w * 0.7, y + 1.0), Vector2(base.x + w * 0.95, y - 6.0),
				Vector2(base.x + w * 0.55, y - 9.0), Vector2(base.x, y - 16.0), Vector2(base.x - w * 0.55, y - 9.0)]), color)
		y -= 12.0
	b.limb(Vector2(base.x, y), Vector2(base.x, y - 34.0), 4.0, 2.0, color)
	for ring: int in 3:
		b.circle(Vector2(base.x, y - 8.0 - ring * 8.0), 3.0, color)


static func _bamboo_far(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	# Groves at both sides; only a couple of hazy stalks in the middle of the field.
	var clusters: Array[Vector3] = [Vector3(-600.0, 420.0, 15.0), Vector3(900.0, 1300.0, 2.0), Vector3(1560.0, 2750.0, 17.0)]
	for cluster: Vector3 in clusters:
		var sparse: bool = cluster.z < 6.0
		for i: int in int(cluster.z):
			var x: float = lerpf(cluster.x, cluster.y, (float(i) + rng.randf_range(0.1, 0.9)) / cluster.z)
			var haze: float = rng.randf_range(0.0, 0.3) + (0.4 if sparse else 0.0)
			var color: Color = t.bamboo_far.lerp(t.mist, haze)
			_bamboo_stalk(b, rng, x, rng.randf_range(9.0, 15.0), color, GROUND_Y + 30.0, -260.0, 1.0, true)


static func _bamboo_near(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	for range_x: Vector2 in [Vector2(-760.0, -240.0), Vector2(2120.0, 2760.0)]:
		for i: int in 5:
			var x: float = lerpf(range_x.x, range_x.y, (float(i) + rng.randf_range(0.1, 0.9)) / 5.0)
			_bamboo_stalk(b, rng, x, rng.randf_range(22.0, 32.0), t.bamboo_near, GROUND_Y + 60.0, -400.0, 1.6, false)


## Far bamboo dissolves into the sky toward the top (ink wash); returns the alpha at height y.
static func _haze_alpha(y: float, fade: bool) -> float:
	return lerpf(0.3, 1.0, smoothstep(-200.0, 520.0, y)) if fade else 1.0


## One bamboo stalk with node rings and drooping leaf clusters.
static func _bamboo_stalk(b: InkBatch, rng: RandomNumberGenerator, x: float, width: float, base_color: Color,
		bottom_y: float, top_y: float, leaf_scale: float, fade: bool) -> void:
	var lean: float = rng.randf_range(-0.05, 0.05)
	var y: float = bottom_y
	var half: float = width * 0.5
	while y > top_y:
		var next_y: float = maxf(y - rng.randf_range(70.0, 115.0) * leaf_scale, top_y)
		var x0: float = x + (bottom_y - y) * lean
		var x1: float = x + (bottom_y - next_y) * lean
		var color: Color = Color(base_color, _haze_alpha(next_y, fade))
		b.fill_convex(PackedVector2Array([Vector2(x0 - half, y), Vector2(x0 + half, y),
				Vector2(x1 + half * 0.97, next_y + 3.0), Vector2(x1 - half * 0.97, next_y + 3.0)]), color)
		b.fill_convex(PackedVector2Array([Vector2(x1 - half - 1.5, next_y + 2.2), Vector2(x1 + half + 1.5, next_y + 2.2),
				Vector2(x1 + half + 1.5, next_y + 0.6), Vector2(x1 - half - 1.5, next_y + 0.6)]), color)
		y = next_y
	var clusters: int = rng.randi_range(2, 4)
	for c: int in clusters:
		var cy: float = rng.randf_range(top_y + 60.0, lerpf(top_y, bottom_y, 0.62))
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var root: Vector2 = Vector2(x + (bottom_y - cy) * lean, cy)
		var color: Color = Color(base_color, _haze_alpha(cy, fade))
		var twig_end: Vector2 = root + Vector2(side * rng.randf_range(18.0, 40.0), -rng.randf_range(8.0, 22.0)) * leaf_scale
		b.limb(root, twig_end, 2.4 * leaf_scale, 1.6 * leaf_scale, color)
		for leaf: int in rng.randi_range(4, 7):
			var angle: float = (PI * 0.5 - side * rng.randf_range(0.5, 1.35)) if side > 0.0 else (PI * 0.5 + rng.randf_range(0.5, 1.35))
			_leaf(b, twig_end, Vector2.from_angle(angle), rng.randf_range(30.0, 55.0) * leaf_scale,
					rng.randf_range(6.0, 9.0) * leaf_scale, color)


static func _leaf(b: InkBatch, base: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	var normal: Vector2 = direction.orthogonal()
	b.fill_convex(PackedVector2Array([base, base + direction * length * 0.32 + normal * width * 0.5,
			base + direction * length, base + direction * length * 0.32 - normal * width * 0.5]), color)


static func _mist_low(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	# A light band right behind the fighters' legs, then rolling fog banks over it.
	b.gradient_rect(Rect2(LEFT, 760.0, FOG_TILE, 80.0), Color(t.mist, 0.0), Color(t.mist, 0.5))
	b.gradient_rect(Rect2(LEFT, 840.0, FOG_TILE, 60.0), Color(t.mist, 0.5), Color(t.mist, 0.65))
	b.flush(ci)
	_mist(ci, b, rng, t, 760.0, 880.0, 16, Vector2(500.0, 1000.0), Vector2(80.0, 160.0), Vector2(0.35, 0.6))


static func _ground(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		tops.append(Vector2(x, GROUND_Y - 1.5 + 1.5 * sin(x * 0.031) + sin(x * 0.0083 + 1.3)))
		x += 16.0
	var mid: Color = t.ground_top.lerp(t.ground_bottom, 0.75)
	b.ridge_fill(tops, 950.0, t.ground_top, mid)
	b.gradient_rect(Rect2(LEFT, 950.0, RIGHT - LEFT, BOTTOM - 950.0), mid, t.ground_bottom)
	# Dry-brush streaks in the soil.
	for i: int in 46:
		var y: float = rng.randf_range(902.0, 1300.0)
		var start: float = rng.randf_range(LEFT, RIGHT)
		var length: float = rng.randf_range(80.0, 380.0)
		var points: PackedVector2Array = PackedVector2Array([Vector2(start, y), Vector2(start + length * 0.5, y + rng.randf_range(-2.0, 2.0)),
				Vector2(start + length, y + rng.randf_range(-3.0, 3.0))])
		b.stroke(points, rng.randf_range(3.0, 7.0), 1.0, Color(t.ground_bottom, rng.randf_range(0.2, 0.45)))
	# Pebbles along the edge, kept small so feet stay readable (the grass is the reed layers').
	var tuft: Color = t.ground_top.lerp(InkPalette.INK_BACK, 0.55)
	for i: int in 26:
		var base: Vector2 = Vector2(rng.randf_range(LEFT, RIGHT), GROUND_Y + 3.0)
		b.ellipse(base, Vector2(rng.randf_range(5.0, 9.0), rng.randf_range(2.5, 4.0)), tuft, 10)


# --- Reeds and pampas grass (swaying; vertex alpha = sway weight) ---------------

## Tall pampas and reeds behind the fighters, standing on the ground line: pale stalks with feathery
## plumes, in drifts. Their light colour keeps the dark fighters readable in front.
static func _reeds_back(b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	var x: float = LEFT
	while x < RIGHT:
		x += rng.randf_range(16.0, 44.0)
		var drift: float = 0.5 + 0.5 * sin(x * 0.0061 + 1.3) * sin(x * 0.0023)
		if rng.randf() > 0.3 + 0.7 * drift:
			continue
		var base: Vector2 = Vector2(x, GROUND_Y + rng.randf_range(0.0, 7.0))
		var height: float = rng.randf_range(80.0, 190.0)
		var stalk: Color = t.reed_stalk.lerp(t.mist, rng.randf_range(0.0, 0.25))
		_reed(b, rng, base, height, rng.randf_range(1.5, 2.6), stalk, t.reed_plume, rng.randf() < 0.55)
		for blade: int in 2:
			_blade(b, rng, base + Vector2(rng.randf_range(-6.0, 6.0), 0.0), rng.randf_range(40.0, 95.0), stalk)


## In front: low grass below the fighters' feet, and tall pampas framing both edges of the field.
static func _reeds_front(b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	var tint: Color = t.reed_stalk.lerp(t.ground_bottom, 0.35)
	for i: int in 70:
		var base: Vector2 = Vector2(rng.randf_range(LEFT, RIGHT), GROUND_Y + rng.randf_range(58.0, 118.0))
		for blade: int in rng.randi_range(2, 3):
			_blade(b, rng, base + Vector2(rng.randf_range(-8.0, 8.0), 0.0), rng.randf_range(26.0, 54.0), tint)
	for range_x: Vector2 in [Vector2(-520.0, 30.0), Vector2(1960.0, 2520.0)]:
		for i: int in 16:
			var base: Vector2 = Vector2(rng.randf_range(range_x.x, range_x.y), GROUND_Y + rng.randf_range(40.0, 120.0))
			var height: float = rng.randf_range(170.0, 330.0)
			_reed(b, rng, base, height, rng.randf_range(2.4, 3.6), tint, t.reed_plume.lerp(t.reed_stalk, 0.3), true)


## One stalk: a tapered ribbon whose alpha runs 0 (root) to 1 (tip) for the sway shader, with an
## optional feathery plume at the top.
static func _reed(b: InkBatch, rng: RandomNumberGenerator, base: Vector2, height: float, width: float, color: Color,
		plume: Color, with_plume: bool) -> void:
	var lean: float = rng.randf_range(-0.1, 0.16)
	var steps: int = 5
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var tip: Vector2 = base
	for i: int in steps + 1:
		var u: float = float(i) / float(steps)
		var centre: Vector2 = base + Vector2(lean * height * u * u, -height * u)
		var half: float = lerpf(width, 0.5, u)
		outer.append(centre + Vector2(half, 0.0))
		inner.append(centre - Vector2(half, 0.0))
		colors.append(Color(color, u))
		tip = centre
	b.ribbon(outer, inner, colors, colors)
	if not with_plume:
		return
	# Plume: a slim feathered cone at the top of the stalk, plus two thin side feathers.
	var plume_len: float = height * 0.3
	var p_outer: PackedVector2Array = PackedVector2Array()
	var p_inner: PackedVector2Array = PackedVector2Array()
	var p_colors: PackedColorArray = PackedColorArray()
	for i: int in 5:
		var u: float = float(i) / 4.0
		var centre: Vector2 = tip + Vector2(0.0, plume_len * (0.5 - u) * 0.9)
		var half: float = 7.0 * sin(PI * clampf(u * 0.92 + 0.04, 0.0, 1.0)) * (0.55 + height / 400.0)
		p_outer.append(centre + Vector2(half, 0.0))
		p_inner.append(centre - Vector2(half, 0.0))
		p_colors.append(Color(plume, 0.8 + 0.2 * u))
	b.ribbon(p_outer, p_inner, p_colors, p_colors)
	for side: float in [-1.0, 1.0]:
		var f_a: PackedVector2Array = PackedVector2Array()
		var f_b: PackedVector2Array = PackedVector2Array()
		var f_colors: PackedColorArray = PackedColorArray()
		for k: int in 3:
			var u: float = float(k) / 2.0
			var point: Vector2 = tip + Vector2(side * 11.0 * u, plume_len * (0.35 - u * 0.75))
			f_a.append(point + Vector2(1.2 * (1.0 - u), 0.0))
			f_b.append(point - Vector2(1.2 * (1.0 - u), 0.0))
			f_colors.append(Color(plume, 0.85 + 0.15 * u))
		b.ribbon(f_a, f_b, f_colors, f_colors)


## A grass blade: a thin curved ribbon bending to one side, alpha 0 to 1 root to tip.
static func _blade(b: InkBatch, rng: RandomNumberGenerator, base: Vector2, length: float, color: Color) -> void:
	var bend: float = rng.randf_range(-0.5, 0.5)
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in 5:
		var u: float = float(i) / 4.0
		var centre: Vector2 = base + Vector2(bend * length * u * u, -length * u)
		var half: float = lerpf(2.2, 0.2, u)
		outer.append(centre + Vector2(half, 0.0))
		inner.append(centre - Vector2(half, 0.0))
		colors.append(Color(color, u))
	b.ribbon(outer, inner, colors, colors)
