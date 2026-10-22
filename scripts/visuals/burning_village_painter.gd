class_name BurningVillagePainter
extends RefCounted
## The land layers of Region 2, the Burning Village, for BambooOutskirtsPainter.paint(): the sky, sun, clouds, mist,
## ground and reeds are shared, but where Region 1 has bamboo this paints a village at dusk with its houses on fire.
##   HILLS        far ridge with small farmhouses and a watchtower, a few burning, thin smoke over them
##   BAMBOO_FAR   a row of thatched houses behind the fighters (light, as the art bible asks), the burning ones with
##                flames through broken roofs, lit windows and smoke columns rising into the sky
##   BAMBOO_NEAR  charred posts and a broken fence framing both edges, their tips still glowing
##   FIRES        the glow around every flame, drawn additively; the backdrop flickers it (RegionBackdrop)
## Every house comes from house_sites(), so the flames, the glow layer and the smoke all agree. Colours come from the
## theme (fire_core, fire_glow, smoke and the usual land colours).

const GROUND_Y: float = BambooOutskirtsPainter.GROUND_Y
const LEFT: float = BambooOutskirtsPainter.LEFT
const RIGHT: float = BambooOutskirtsPainter.RIGHT
## The row of houses stands on this line (hidden in the low mist behind the fighters' legs).
const HOUSE_BASE_Y: float = GROUND_Y + 24.0
const HOUSE_SEED: int = 4021


## Paints `layer` for a burning-village theme. Returns false for the layers it leaves to the shared painter.
static func paint(ci: CanvasItem, b: InkBatch, layer: BambooOutskirtsPainter.Layer, rng: RandomNumberGenerator,
		t: AtmosphereTheme) -> bool:
	match layer:
		BambooOutskirtsPainter.Layer.HILLS:
			_hills(ci, b, rng, t)
		BambooOutskirtsPainter.Layer.BAMBOO_FAR:
			_houses(ci, b, t)
		BambooOutskirtsPainter.Layer.BAMBOO_NEAR:
			_charred_posts(b, rng, t)
		BambooOutskirtsPainter.Layer.FIRES:
			_fire_glow(ci, t)
		_:
			return false
	return true


## The village row: x, width, wall height and how strongly it burns (0 = not burning), always the same.
static func house_sites(t: AtmosphereTheme) -> Array[Vector4]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = HOUSE_SEED
	var sites: Array[Vector4] = []
	var x: float = LEFT + 60.0
	while x < RIGHT - 80.0:
		var width: float = rng.randf_range(190.0, 290.0)
		# Fewer houses in the middle of the field, where the fighters are.
		var middle: bool = x > 380.0 and x < 1500.0
		var gap: float = rng.randf_range(160.0, 320.0) if middle else rng.randf_range(30.0, 110.0)
		var height: float = rng.randf_range(110.0, 150.0)
		var burn: float = rng.randf()
		var burning: float = clampf((t.fire_intensity - burn * 0.8) * 2.2, 0.0, 1.0) if burn < 0.85 else 0.0
		sites.append(Vector4(x + width * 0.5, width, height, burning))
		x += width + gap
	return sites


# --- Far ridge ------------------------------------------------------------------

static func _hills(ci: CanvasItem, b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	var phase: float = rng.randf() * TAU
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = LEFT
	while x <= RIGHT:
		tops.append(Vector2(x, _hill_y(x, phase)))
		x += 24.0
	var color: Color = t.mountain_mid
	# Small farmhouses along the ridge, and the watchtower.
	var fires: Array[Vector3] = []
	var hx: float = LEFT + rng.randf_range(40.0, 160.0)
	while hx < RIGHT:
		var w: float = rng.randf_range(44.0, 70.0)
		var base: Vector2 = Vector2(hx, _hill_y(hx, phase) + 8.0)
		_farmhouse(b, base, w, w * 0.42, color)
		if rng.randf() < 0.25 + 0.5 * t.fire_intensity:
			fires.append(Vector3(base.x + rng.randf_range(-w * 0.2, w * 0.2), base.y - w * 0.62, w * 0.5))
		hx += w + rng.randf_range(120.0, 420.0)
	var tower_x: float = 660.0
	_watchtower(b, Vector2(tower_x, _hill_y(tower_x, phase) + 6.0), color)
	fires.append(Vector3(tower_x, _hill_y(tower_x, phase) - 118.0, 30.0))
	b.ridge_fill(tops, 900.0, color, t.mist)
	for fire: Vector3 in fires:
		_flame(b, Vector2(fire.x, fire.y), fire.z * 0.7, fire.z * 0.3, t, fire.x * 0.37)
	b.flush(ci)
	# Thin smoke over the far fires and a warm haze where they burn.
	for fire: Vector3 in fires:
		BambooOutskirtsPainter.soft(ci, Vector2(fire.x, fire.y), Vector2(fire.z * 5.0, fire.z * 3.0), Color(t.fire_glow, 0.16))
		_smoke_column(ci, Vector2(fire.x, fire.y - fire.z), fire.z * 1.6, 320.0, t, 0.12, fire.x)


static func _hill_y(x: float, phase: float) -> float:
	return 790.0 - 70.0 * (0.5 + 0.5 * sin(x * 0.0024 + phase)) - 30.0 * (0.5 + 0.5 * sin(x * 0.0071 + phase * 2.0))


## A small far farmhouse: low walls under a big thatched roof.
static func _farmhouse(b: InkBatch, base: Vector2, width: float, wall: float, color: Color) -> void:
	var half: float = width * 0.5
	b.fill_convex(PackedVector2Array([Vector2(base.x - half * 0.8, base.y), Vector2(base.x + half * 0.8, base.y),
			Vector2(base.x + half * 0.8, base.y - wall), Vector2(base.x - half * 0.8, base.y - wall)]), color)
	b.fill_convex(PackedVector2Array([Vector2(base.x - half, base.y - wall + 2.0), Vector2(base.x + half, base.y - wall + 2.0),
			Vector2(base.x + half * 0.3, base.y - wall - width * 0.42), Vector2(base.x - half * 0.3, base.y - wall - width * 0.42)]), color)


## The village watchtower: four legs, a platform and a small roof.
static func _watchtower(b: InkBatch, base: Vector2, color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		b.limb(base + Vector2(side * 20.0, 0.0), base + Vector2(side * 12.0, -96.0), 4.0, 3.0, color)
	b.limb(base + Vector2(-18.0, -40.0), base + Vector2(14.0, -70.0), 2.0, 2.0, color)
	b.limb(base + Vector2(18.0, -40.0), base + Vector2(-14.0, -70.0), 2.0, 2.0, color)
	b.fill_convex(PackedVector2Array([base + Vector2(-22.0, -94.0), base + Vector2(22.0, -94.0),
			base + Vector2(22.0, -102.0), base + Vector2(-22.0, -102.0)]), color)
	b.fill_convex(PackedVector2Array([base + Vector2(-30.0, -112.0), base + Vector2(30.0, -112.0),
			base + Vector2(0.0, -132.0)]), color)


# --- The row of houses ------------------------------------------------------------

static func _houses(ci: CanvasItem, b: InkBatch, t: AtmosphereTheme) -> void:
	var sites: Array[Vector4] = house_sites(t)
	# The thatch a little darker than the walls so the roofs read through the smoke.
	var wall: Color = t.bamboo_far.lerp(t.mist, 0.15)
	var roof: Color = t.bamboo_far.darkened(0.12)
	var charred: Color = t.bamboo_far.lerp(t.bamboo_near, 0.45)
	for site: Vector4 in sites:
		_house(b, Vector2(site.x, HOUSE_BASE_Y), site.y, site.z, site.w, wall, roof, charred, t)
	b.flush(ci)
	# Smoke columns from the burning houses, leaning with the wind.
	for site: Vector4 in sites:
		if site.w > 0.0:
			var top: Vector2 = Vector2(site.x, HOUSE_BASE_Y - site.z - site.y * 0.5)
			_smoke_column(ci, top, site.y * 0.55, 560.0 + 300.0 * site.w, t, 0.3 + 0.2 * site.w, site.x)


## One thatched minka: plastered walls with posts, a steep hipped roof, and when burning a broken roof with rafters
## showing, windows lit from inside and flames climbing out.
static func _house(b: InkBatch, base: Vector2, width: float, wall: float, burning: float, wall_color: Color,
		roof_color: Color, charred: Color, t: AtmosphereTheme) -> void:
	var half: float = width * 0.5
	var eave_y: float = base.y - wall
	b.fill_convex(PackedVector2Array([Vector2(base.x - half * 0.86, base.y), Vector2(base.x + half * 0.86, base.y),
			Vector2(base.x + half * 0.86, eave_y), Vector2(base.x - half * 0.86, eave_y)]), wall_color)
	# Posts between the wall panels.
	for k: int in 4:
		var px: float = base.x - half * 0.86 + width * 0.86 * float(k) / 3.0
		b.limb(Vector2(px, base.y), Vector2(px, eave_y), 3.0, 3.0, charred if burning > 0.0 else wall_color.darkened(0.12))
	# Windows: dark slits, or lit by the fire inside.
	for k: int in 2:
		var wx: float = base.x + (float(k) - 0.5) * width * 0.4
		var window: Color = t.fire_glow.lerp(t.fire_core, 0.3) if burning > 0.3 else wall_color.darkened(0.2)
		b.fill_convex(PackedVector2Array([Vector2(wx - 14.0, eave_y + wall * 0.3), Vector2(wx + 14.0, eave_y + wall * 0.3),
				Vector2(wx + 14.0, eave_y + wall * 0.62), Vector2(wx - 14.0, eave_y + wall * 0.62)]), window)
	var roof_h: float = width * 0.55
	var ridge_y: float = eave_y - roof_h
	if burning <= 0.0:
		b.fill_convex(PackedVector2Array([Vector2(base.x - half * 1.08, eave_y + 6.0), Vector2(base.x + half * 1.08, eave_y + 6.0),
				Vector2(base.x + half * 0.34, ridge_y), Vector2(base.x - half * 0.34, ridge_y)]), roof_color)
		b.fill_convex(PackedVector2Array([Vector2(base.x - half * 0.4, ridge_y + 4.0), Vector2(base.x + half * 0.4, ridge_y + 4.0),
				Vector2(base.x + half * 0.36, ridge_y - 7.0), Vector2(base.x - half * 0.36, ridge_y - 7.0)]), roof_color.darkened(0.1))
		return
	# A burning roof: the thatch is gone in a ragged hole, the rafters show, the flames climb out.
	var hole: float = clampf(0.35 + 0.45 * burning, 0.0, 0.85)
	var left_edge: float = base.x - half * 0.34 * hole
	var right_edge: float = base.x + half * 0.34 * hole
	b.fill(PackedVector2Array([Vector2(base.x - half * 1.08, eave_y + 6.0), Vector2(left_edge - half * 0.3, eave_y + 6.0),
			Vector2(left_edge - half * 0.05, eave_y - roof_h * 0.45), Vector2(left_edge, eave_y - roof_h * 0.62),
			Vector2(base.x - half * 0.34, ridge_y + roof_h * 0.1)]), roof_color)
	b.fill(PackedVector2Array([Vector2(right_edge + half * 0.3, eave_y + 6.0), Vector2(base.x + half * 1.08, eave_y + 6.0),
			Vector2(base.x + half * 0.34, ridge_y + roof_h * 0.25), Vector2(right_edge + half * 0.08, eave_y - roof_h * 0.5)]), roof_color)
	for k: int in 4:
		var u: float = (float(k) + 0.5) / 4.0
		var foot: Vector2 = Vector2(lerpf(base.x - half * 0.9, base.x + half * 0.9, u), eave_y + 4.0)
		b.limb(foot, Vector2(lerpf(base.x - half * 0.3, base.x + half * 0.3, u), ridge_y + roof_h * 0.2), 3.2, 2.0, charred)
	# Tongues of fire licking out of the hole: the middle ones tallest, never much taller than the roof.
	var flames: int = 3 + int(burning * 3.0)
	for k: int in flames:
		var u: float = (float(k) + 0.5) / float(flames)
		var fx: float = lerpf(left_edge - half * 0.15, right_edge + half * 0.15, u)
		var height: float = roof_h * (0.35 + 0.4 * burning) * (0.6 + 0.4 * sin(PI * u)) * (0.8 + 0.2 * sin(u * 9.0 + base.x))
		_flame(b, Vector2(fx, eave_y - roof_h * 0.35), height, width * 0.09, t, base.x * 0.13 + float(k) * 1.7)


## A tongue of fire standing on `base`: an outer flame and a hot core, licking up and to the side.
static func _flame(b: InkBatch, base: Vector2, height: float, width: float, t: AtmosphereTheme, phase: float) -> void:
	for layer: int in 2:
		var scale_h: float = 1.0 if layer == 0 else 0.62
		var scale_w: float = 1.0 if layer == 0 else 0.5
		var color: Color = t.fire_glow if layer == 0 else t.fire_core
		var outline: PackedVector2Array = PackedVector2Array()
		var steps: int = 7
		for k: int in steps + 1:
			var u: float = float(k) / float(steps)
			var y: float = base.y - height * scale_h * u
			var sway: float = sin(u * 3.2 + phase) * width * 0.5 * u
			outline.append(Vector2(base.x - width * scale_w * (1.0 - u) * (0.8 + 0.2 * sin(u * 7.0 + phase)) + sway, y))
		for k: int in range(steps, -1, -1):
			var u: float = float(k) / float(steps)
			var y: float = base.y - height * scale_h * u
			var sway: float = sin(u * 3.2 + phase) * width * 0.5 * u
			outline.append(Vector2(base.x + width * scale_w * (1.0 - u) * (0.8 + 0.2 * cos(u * 6.0 + phase)) + sway, y))
		b.fill(outline, color)


## A column of smoke from `base` up to `length` above it: soft washes, widening and leaning downwind as they rise.
static func _smoke_column(ci: CanvasItem, base: Vector2, width: float, length: float, t: AtmosphereTheme, alpha: float,
		phase: float) -> void:
	var puffs: int = 7
	for k: int in puffs:
		var u: float = float(k) / float(puffs - 1)
		var center: Vector2 = base + Vector2(u * u * length * 0.45 + sin(u * 4.0 + phase) * 14.0, -u * length)
		var size: Vector2 = Vector2(width * (1.0 + 2.2 * u), width * (0.9 + 1.4 * u))
		BambooOutskirtsPainter.soft(ci, center, size, Color(t.smoke, alpha * (1.0 - 0.6 * u)))


# --- Near edges -------------------------------------------------------------------

## Burnt posts and a broken fence at both edges of the field (dark, like Region 1's near bamboo), embers on their tips.
static func _charred_posts(b: InkBatch, rng: RandomNumberGenerator, t: AtmosphereTheme) -> void:
	for range_x: Vector2 in [Vector2(-760.0, -240.0), Vector2(2120.0, 2760.0)]:
		var tips: Array[Vector2] = []
		for i: int in 5:
			var x: float = lerpf(range_x.x, range_x.y, (float(i) + rng.randf_range(0.1, 0.9)) / 5.0)
			var height: float = rng.randf_range(220.0, 520.0)
			var lean: float = rng.randf_range(-0.12, 0.12)
			var top: Vector2 = Vector2(x + height * lean, GROUND_Y + 60.0 - height)
			var w: float = rng.randf_range(16.0, 28.0)
			b.fill(PackedVector2Array([Vector2(x - w * 0.5, GROUND_Y + 60.0), Vector2(x + w * 0.5, GROUND_Y + 60.0),
					top + Vector2(w * 0.35, 6.0), top + Vector2(w * 0.1, -4.0), top + Vector2(-w * 0.2, 8.0),
					top + Vector2(-w * 0.4, 2.0)]), t.bamboo_near)
			tips.append(top)
		# A fallen fence rail between neighbouring posts.
		for i: int in tips.size() - 1:
			if rng.randf() < 0.6:
				var y0: float = GROUND_Y + rng.randf_range(-120.0, -40.0)
				var y1: float = y0 + rng.randf_range(-40.0, 60.0)
				b.limb(Vector2(tips[i].x, y0), Vector2(tips[i + 1].x, y1), 7.0, 6.0, t.bamboo_near)
		for tip: Vector2 in tips:
			b.circle(tip + Vector2(0.0, 4.0), 4.0, Color(t.fire_glow, 0.9))
			b.circle(tip + Vector2(0.0, 4.0), 2.0, t.fire_core)


# --- Glow -------------------------------------------------------------------------

## The light of every flame, drawn additively at the house row's depth.
static func _fire_glow(ci: CanvasItem, t: AtmosphereTheme) -> void:
	for site: Vector4 in house_sites(t):
		if site.w <= 0.0:
			continue
		var center: Vector2 = Vector2(site.x, HOUSE_BASE_Y - site.z - site.y * 0.3)
		BambooOutskirtsPainter.soft(ci, center, Vector2(site.y * 2.6, site.y * 2.0), Color(t.fire_glow, 0.22 * site.w))
		BambooOutskirtsPainter.soft(ci, center, Vector2(site.y * 1.2, site.y * 1.0), Color(t.fire_core, 0.18 * site.w))
		BambooOutskirtsPainter.soft(ci, Vector2(site.x, HOUSE_BASE_Y - 10.0), Vector2(site.y * 3.0, 90.0), Color(t.fire_glow, 0.12 * site.w))
