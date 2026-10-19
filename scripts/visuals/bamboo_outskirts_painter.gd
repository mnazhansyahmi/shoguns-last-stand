class_name BambooOutskirtsPainter
extends RefCounted
## Paints the Bamboo Outskirts backdrop (ink wash at dusk) one layer at a time, for
## BackdropLayer._draw(). Coordinates are battlefield world pixels; the ground line is y 880.
## Every layer is seeded, so it looks the same each time it is drawn. Layers behind the fighters
## stay light (docs/ART_BIBLE.md, contrast rules); dark near bamboo only frames the edges.

enum Layer { SKY, MOON, DISTANT_MOUNTAINS, MOUNTAINS, MIST_HIGH, HILLS, BAMBOO_FAR, MIST_LOW,
		BAMBOO_NEAR, GROUND, FRONT_FOG }

const GROUND_Y: float = 880.0
const LEFT: float = -900.0
const RIGHT: float = 2800.0
const TOP: float = -700.0
const BOTTOM: float = 1700.0
## Drifting layers repeat every this many pixels (BackdropLayer.tile_width must match).
const FOG_TILE: float = 3600.0


static func paint(ci: CanvasItem, layer: Layer, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + int(layer) * 104729
	match layer:
		Layer.SKY:
			_sky(ci, rng)
		Layer.MOON:
			_moon(ci)
		Layer.DISTANT_MOUNTAINS:
			_mountains(ci, rng, 760.0, 430.0, InkPalette.MOUNTAIN_FAR.lerp(InkPalette.SKY_HORIZON, 0.5), 840.0)
		Layer.MOUNTAINS:
			_mountains(ci, rng, 800.0, 320.0, InkPalette.MOUNTAIN_FAR, 870.0)
		Layer.MIST_HIGH:
			_mist(ci, rng, 600.0, 770.0, 18, Vector2(420.0, 900.0), Vector2(60.0, 140.0), Vector2(0.3, 0.5))
		Layer.HILLS:
			_hills(ci, rng)
		Layer.BAMBOO_FAR:
			_bamboo_far(ci, rng)
		Layer.MIST_LOW:
			_mist_low(ci, rng)
		Layer.BAMBOO_NEAR:
			_bamboo_near(ci, rng)
		Layer.GROUND:
			_ground(ci, rng)
		Layer.FRONT_FOG:
			_mist(ci, rng, GROUND_Y - 6.0, GROUND_Y + 26.0, 12, Vector2(320.0, 700.0), Vector2(26.0, 46.0), Vector2(0.08, 0.13))


## A soft elliptical wash (glow texture with normal blending).
static func soft(ci: CanvasItem, center: Vector2, size: Vector2, color: Color) -> void:
	ci.draw_texture_rect(InkBrush.glow_texture(), Rect2(center - size * 0.5, size), false, color)


# --- Layers -------------------------------------------------------------------

static func _sky(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	var upper: Color = InkPalette.SKY_TOP.lerp(InkPalette.SKY_HORIZON, 0.45)
	InkBrush.gradient_rect(ci, Rect2(LEFT, TOP, RIGHT - LEFT, 300.0 - TOP), InkPalette.SKY_TOP, upper)
	InkBrush.gradient_rect(ci, Rect2(LEFT, 300.0, RIGHT - LEFT, 520.0), upper, InkPalette.SKY_HORIZON)
	InkBrush.gradient_rect(ci, Rect2(LEFT, 820.0, RIGHT - LEFT, BOTTOM - 820.0), InkPalette.SKY_HORIZON, InkPalette.MIST)
	# Faint cloud washes.
	for i: int in 9:
		var center: Vector2 = Vector2(rng.randf_range(LEFT, RIGHT), rng.randf_range(80.0, 460.0))
		soft(ci, center, Vector2(rng.randf_range(400.0, 900.0), rng.randf_range(24.0, 60.0)),
				Color(InkPalette.SKY_HORIZON, rng.randf_range(0.18, 0.32)))


static func _moon(ci: CanvasItem) -> void:
	var center: Vector2 = Vector2(1480.0, 230.0)
	soft(ci, center, Vector2(760.0, 760.0), Color(InkPalette.MOON_HALO, 0.2))
	soft(ci, center, Vector2(340.0, 340.0), Color(InkPalette.MOON_HALO, 0.35))
	ci.draw_circle(center, 74.0, InkPalette.MOON)
	var shade: Color = Color(InkPalette.MOON_HALO, 0.35)
	soft(ci, center + Vector2(-22.0, -14.0), Vector2(46.0, 38.0), shade)
	soft(ci, center + Vector2(18.0, 20.0), Vector2(34.0, 30.0), shade)
	soft(ci, center + Vector2(30.0, -28.0), Vector2(22.0, 20.0), shade)
	# Cloud wisps crossing the moon.
	var wisp: Color = Color(InkPalette.SKY_TOP.lerp(InkPalette.SKY_HORIZON, 0.6), 0.75)
	soft(ci, center + Vector2(-30.0, 34.0), Vector2(420.0, 30.0), wisp)
	soft(ci, center + Vector2(60.0, -16.0), Vector2(260.0, 18.0), Color(wisp, 0.55))


## Peaked ridge: sharp tops from 1 - |sin|, softened by a gentle wave.
static func _ridge_y(x: float, base_y: float, amplitude: float, phases: Vector3) -> float:
	var h: float = 0.58 * pow(1.0 - absf(sin(x * 0.0016 + phases.x)), 1.6)
	h += 0.32 * pow(1.0 - absf(sin(x * 0.0043 + phases.y)), 1.3)
	h += 0.1 * (0.5 + 0.5 * sin(x * 0.021 + phases.z))
	return base_y - amplitude * h


static func _mountains(ci: CanvasItem, rng: RandomNumberGenerator, base_y: float, amplitude: float,
		color: Color, fade_y: float) -> void:
	var phases: Vector3 = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		tops.append(Vector2(x, _ridge_y(x, base_y, amplitude, phases)))
		x += 20.0
	InkBrush.ridge_fill(ci, tops, fade_y, color, InkPalette.MIST)
	InkBrush.gradient_rect(ci, Rect2(LEFT, fade_y, RIGHT - LEFT, BOTTOM - fade_y), InkPalette.MIST, InkPalette.MIST)
	InkBrush.stroke(ci, tops, 3.0, 3.0, color.darkened(0.12))


static func _mist(ci: CanvasItem, rng: RandomNumberGenerator, y_min: float, y_max: float, count: int,
		width_range: Vector2, height_range: Vector2, alpha_range: Vector2) -> void:
	for i: int in count:
		var center: Vector2 = Vector2(LEFT + (float(i) + rng.randf_range(0.0, 0.8)) * FOG_TILE / float(count),
				rng.randf_range(y_min, y_max))
		soft(ci, center, Vector2(rng.randf_range(width_range.x, width_range.y), rng.randf_range(height_range.x, height_range.y)),
				Color(InkPalette.MIST, rng.randf_range(alpha_range.x, alpha_range.y)))


static func _hills(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	var phase: float = rng.randf() * TAU
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		var y: float = 790.0 - 70.0 * (0.5 + 0.5 * sin(x * 0.0024 + phase)) - 30.0 * (0.5 + 0.5 * sin(x * 0.0071 + phase * 2.0))
		tops.append(Vector2(x, y))
		x += 24.0
	var pagoda_x: float = 660.0
	var pagoda_y: float = 790.0 - 70.0 * (0.5 + 0.5 * sin(pagoda_x * 0.0024 + phase)) - 30.0 * (0.5 + 0.5 * sin(pagoda_x * 0.0071 + phase * 2.0))
	_pagoda(ci, Vector2(pagoda_x, pagoda_y + 6.0), InkPalette.MOUNTAIN_MID)
	InkBrush.ridge_fill(ci, tops, 900.0, InkPalette.MOUNTAIN_MID, InkPalette.MIST)


## A three-tier pagoda silhouette standing on `base`.
static func _pagoda(ci: CanvasItem, base: Vector2, color: Color) -> void:
	var y: float = base.y
	var widths: Array[float] = [62.0, 52.0, 42.0]
	for tier: int in widths.size():
		var w: float = widths[tier]
		var body_h: float = 34.0 if tier == 0 else 26.0
		InkBrush.fill_convex(ci, PackedVector2Array([Vector2(base.x - w * 0.4, y), Vector2(base.x + w * 0.4, y),
				Vector2(base.x + w * 0.36, y - body_h), Vector2(base.x - w * 0.36, y - body_h)]), color)
		y -= body_h
		# Roof with upturned eaves.
		InkBrush.fill(ci, PackedVector2Array([Vector2(base.x - w * 0.95, y - 6.0), Vector2(base.x - w * 0.7, y + 1.0),
				Vector2(base.x + w * 0.7, y + 1.0), Vector2(base.x + w * 0.95, y - 6.0),
				Vector2(base.x + w * 0.55, y - 9.0), Vector2(base.x, y - 16.0), Vector2(base.x - w * 0.55, y - 9.0)]), color)
		y -= 12.0
	InkBrush.limb(ci, Vector2(base.x, y), Vector2(base.x, y - 34.0), 4.0, 2.0, color)
	for ring: int in 3:
		ci.draw_circle(Vector2(base.x, y - 8.0 - ring * 8.0), 3.0, color)


static func _bamboo_far(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	# Groves at both sides; only a couple of hazy stalks in the middle of the field.
	var clusters: Array[Vector3] = [Vector3(-600.0, 420.0, 15.0), Vector3(900.0, 1300.0, 2.0), Vector3(1560.0, 2750.0, 17.0)]
	for cluster: Vector3 in clusters:
		var sparse: bool = cluster.z < 6.0
		for i: int in int(cluster.z):
			var x: float = lerpf(cluster.x, cluster.y, (float(i) + rng.randf_range(0.1, 0.9)) / cluster.z)
			var haze: float = rng.randf_range(0.0, 0.3) + (0.4 if sparse else 0.0)
			var color: Color = InkPalette.BAMBOO_FAR.lerp(InkPalette.MIST, haze)
			_bamboo_stalk(ci, rng, x, rng.randf_range(9.0, 15.0), color, GROUND_Y + 30.0, -260.0, 1.0, true)


static func _bamboo_near(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	for range_x: Vector2 in [Vector2(-760.0, -240.0), Vector2(2120.0, 2760.0)]:
		for i: int in 5:
			var x: float = lerpf(range_x.x, range_x.y, (float(i) + rng.randf_range(0.1, 0.9)) / 5.0)
			_bamboo_stalk(ci, rng, x, rng.randf_range(22.0, 32.0), InkPalette.BAMBOO_NEAR, GROUND_Y + 60.0, -400.0, 1.6, false)


## Far bamboo dissolves into the sky toward the top (ink wash); returns the alpha at height y.
static func _haze_alpha(y: float, fade: bool) -> float:
	return lerpf(0.3, 1.0, smoothstep(-200.0, 520.0, y)) if fade else 1.0


## One bamboo stalk with node rings and drooping leaf clusters.
static func _bamboo_stalk(ci: CanvasItem, rng: RandomNumberGenerator, x: float, width: float, base_color: Color,
		bottom_y: float, top_y: float, leaf_scale: float, fade: bool) -> void:
	var lean: float = rng.randf_range(-0.05, 0.05)
	var y: float = bottom_y
	var half: float = width * 0.5
	while y > top_y:
		var next_y: float = maxf(y - rng.randf_range(70.0, 115.0) * leaf_scale, top_y)
		var x0: float = x + (bottom_y - y) * lean
		var x1: float = x + (bottom_y - next_y) * lean
		var color: Color = Color(base_color, _haze_alpha(next_y, fade))
		InkBrush.fill_convex(ci, PackedVector2Array([Vector2(x0 - half, y), Vector2(x0 + half, y),
				Vector2(x1 + half * 0.97, next_y + 3.0), Vector2(x1 - half * 0.97, next_y + 3.0)]), color)
		InkBrush.fill_convex(ci, PackedVector2Array([Vector2(x1 - half - 1.5, next_y + 2.2), Vector2(x1 + half + 1.5, next_y + 2.2),
				Vector2(x1 + half + 1.5, next_y + 0.6), Vector2(x1 - half - 1.5, next_y + 0.6)]), color)
		y = next_y
	var clusters: int = rng.randi_range(2, 4)
	for c: int in clusters:
		var cy: float = rng.randf_range(top_y + 60.0, lerpf(top_y, bottom_y, 0.62))
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var root: Vector2 = Vector2(x + (bottom_y - cy) * lean, cy)
		var color: Color = Color(base_color, _haze_alpha(cy, fade))
		var twig_end: Vector2 = root + Vector2(side * rng.randf_range(18.0, 40.0), -rng.randf_range(8.0, 22.0)) * leaf_scale
		InkBrush.limb(ci, root, twig_end, 2.4 * leaf_scale, 1.6 * leaf_scale, color)
		for leaf: int in rng.randi_range(4, 7):
			var angle: float = (PI * 0.5 - side * rng.randf_range(0.5, 1.35)) if side > 0.0 else (PI * 0.5 + rng.randf_range(0.5, 1.35))
			_leaf(ci, twig_end, Vector2.from_angle(angle), rng.randf_range(30.0, 55.0) * leaf_scale,
					rng.randf_range(6.0, 9.0) * leaf_scale, color)


static func _leaf(ci: CanvasItem, base: Vector2, direction: Vector2, length: float, width: float, color: Color) -> void:
	var normal: Vector2 = direction.orthogonal()
	InkBrush.fill_convex(ci, PackedVector2Array([base, base + direction * length * 0.32 + normal * width * 0.5,
			base + direction * length, base + direction * length * 0.32 - normal * width * 0.5]), color)


static func _mist_low(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	# A light band right behind the fighters' legs, then rolling fog banks over it.
	InkBrush.gradient_rect(ci, Rect2(LEFT, 760.0, FOG_TILE, 80.0), Color(InkPalette.MIST, 0.0), Color(InkPalette.MIST, 0.5))
	InkBrush.gradient_rect(ci, Rect2(LEFT, 840.0, FOG_TILE, 60.0), Color(InkPalette.MIST, 0.5), Color(InkPalette.MIST, 0.65))
	_mist(ci, rng, 760.0, 880.0, 16, Vector2(500.0, 1000.0), Vector2(80.0, 160.0), Vector2(0.35, 0.6))


static func _ground(ci: CanvasItem, rng: RandomNumberGenerator) -> void:
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		tops.append(Vector2(x, GROUND_Y - 1.5 + 1.5 * sin(x * 0.031) + sin(x * 0.0083 + 1.3)))
		x += 16.0
	var mid: Color = InkPalette.GROUND_TOP.lerp(InkPalette.GROUND_BOTTOM, 0.75)
	InkBrush.ridge_fill(ci, tops, 1010.0, InkPalette.GROUND_TOP, mid)
	InkBrush.gradient_rect(ci, Rect2(LEFT, 1010.0, RIGHT - LEFT, BOTTOM - 1010.0), mid, InkPalette.GROUND_BOTTOM)
	# Dry-brush streaks in the soil.
	for i: int in 46:
		var y: float = rng.randf_range(902.0, 1300.0)
		var start: float = rng.randf_range(LEFT, RIGHT)
		var length: float = rng.randf_range(80.0, 380.0)
		var points: PackedVector2Array = PackedVector2Array([Vector2(start, y), Vector2(start + length * 0.5, y + rng.randf_range(-2.0, 2.0)),
				Vector2(start + length, y + rng.randf_range(-3.0, 3.0))])
		InkBrush.stroke(ci, points, rng.randf_range(3.0, 7.0), 1.0, Color(InkPalette.GROUND_BOTTOM, rng.randf_range(0.2, 0.45)))
	# Grass tufts and pebbles along the edge, kept small so feet stay readable.
	var tuft: Color = InkPalette.GROUND_TOP.lerp(InkPalette.INK_BACK, 0.55)
	for i: int in 70:
		var tx: float = rng.randf_range(LEFT, RIGHT)
		var base: Vector2 = Vector2(tx, GROUND_Y + 1.0)
		if rng.randf() < 0.25:
			InkBrush.ellipse(ci, base + Vector2(0.0, 2.0), Vector2(rng.randf_range(5.0, 9.0), rng.randf_range(2.5, 4.0)), tuft, 10)
			continue
		for blade: int in rng.randi_range(3, 5):
			var tip: Vector2 = base + Vector2(rng.randf_range(-7.0, 7.0), -rng.randf_range(6.0, 13.0))
			InkBrush.fill_convex(ci, PackedVector2Array([base + Vector2(-1.6, 0.0), tip, base + Vector2(1.6, 0.0)]), tuft)
