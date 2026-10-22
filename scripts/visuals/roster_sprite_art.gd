class_name RosterSpriteArt
extends RefCounted
## Original painted costume layers, shared by kind. Every limb is registered to
## its bone, not scaled with the whole character or baked into a flat portrait.
## Atlas cell bounds and silhouettes are read once; posing only moves nodes.

const NAMES: Dictionary = {
	InkFigure.Kind.ASHIGARU: "ashigaru", InkFigure.Kind.YUMI_ARCHER: "yumi_archer",
	InkFigure.Kind.SHRINE_HEALER: "shrine_healer", InkFigure.Kind.SPEAR_GUARDIAN: "spear_guardian",
	InkFigure.Kind.ONMYOJI: "onmyoji", InkFigure.Kind.HATAMOTO: "hatamoto",
	InkFigure.Kind.HOLLOW_SOLDIER: "hollow_soldier", InkFigure.Kind.ONI_BRUTE: "oni_brute",
	InkFigure.Kind.FALLEN_DAIMYO: "fallen_daimyo",
	InkFigure.Kind.SPECTRAL_ARCHER: "spectral_archer", InkFigure.Kind.SHIELD_BEARER: "shield_bearer",
	InkFigure.Kind.FLYING_SPIRIT: "flying_spirit", InkFigure.Kind.BURNING_GENERAL: "burning_general",
}
const CELLS: Dictionary = {
	&"head": 0, &"torso": 1, &"skirt": 2, &"hem": 2,
	&"upper_f": 4, &"fore_f": 5, &"thigh_f": 6, &"shin_f": 7,
	&"upper_b": 8, &"fore_b": 9, &"thigh_b": 10, &"shin_b": 11,
	&"foot_f": 12, &"foot_b": 13,
	&"pauldron_front": 4, &"pauldron_back": 8,
}
## Where each painted head sits on its neck pivot: low enough that its neck tucks into the collar in every pose
## (a test checks the head and torso shapes overlap).
const HEAD_RECTS: Dictionary = {
	InkFigure.Kind.ASHIGARU: Rect2(-14, -21, 28, 23),
	InkFigure.Kind.YUMI_ARCHER: Rect2(-10, -18, 22, 22),
	InkFigure.Kind.SHRINE_HEALER: Rect2(-10, -20, 22, 24),
	InkFigure.Kind.SPEAR_GUARDIAN: Rect2(-13, -30, 29, 33),
	InkFigure.Kind.ONMYOJI: Rect2(-11, -27, 22, 31),
	InkFigure.Kind.HATAMOTO: Rect2(-13, -28, 26, 30),
	InkFigure.Kind.HOLLOW_SOLDIER: Rect2(-12, -17, 26, 22),
	# His cut neck tucks in behind the shoulders (the head is drawn behind the torso, see NECKS).
	InkFigure.Kind.ONI_BRUTE: Rect2(-21, -21, 39, 29),
	# The helmet sits down on his collar (its painted cords hang over the cuirass).
	InkFigure.Kind.FALLEN_DAIMYO: Rect2(-17, -26, 35, 35),
	InkFigure.Kind.SPECTRAL_ARCHER: Rect2(-11, -19, 24, 25),
	InkFigure.Kind.SHIELD_BEARER: Rect2(-14, -25, 29, 30),
	InkFigure.Kind.FLYING_SPIRIT: Rect2(-12, -18, 26, 30),
	InkFigure.Kind.BURNING_GENERAL: Rect2(-17, -26, 35, 35),
}
const WIDTHS: Dictionary = {
	InkFigure.Kind.ASHIGARU: 21.0, InkFigure.Kind.YUMI_ARCHER: 21.0,
	InkFigure.Kind.SHRINE_HEALER: 20.0, InkFigure.Kind.SPEAR_GUARDIAN: 33.0,
	InkFigure.Kind.ONMYOJI: 23.0, InkFigure.Kind.HATAMOTO: 27.0,
	InkFigure.Kind.HOLLOW_SOLDIER: 21.0, InkFigure.Kind.ONI_BRUTE: 41.0,
	InkFigure.Kind.FALLEN_DAIMYO: 33.0,
	InkFigure.Kind.SPECTRAL_ARCHER: 23.0, InkFigure.Kind.SHIELD_BEARER: 34.0,
	InkFigure.Kind.FLYING_SPIRIT: 25.0, InkFigure.Kind.BURNING_GENERAL: 34.0,
}
## The painted torsos are three-quarter views with an open armhole on their left (back) side, and every upper arm is a
## sleeve tube with an open shoulder end: assembled as is they read as paper-doll sockets. Each armhole (centre and
## radii in torso-cell pixels) is closed with the torso's own closed right shoulder, mirrored; the front arm's open end
## is covered by a cap of the torso's shoulder drawn over it ("shoulder_f"). See shoulder_patch().
const ARMHOLES: Dictionary = {
	InkFigure.Kind.ASHIGARU: [Vector2(19, 96), Vector2(34, 64)],
	InkFigure.Kind.YUMI_ARCHER: [Vector2(23, 115), Vector2(38, 64)],
	InkFigure.Kind.ONI_BRUTE: [Vector2(22, 66), Vector2(36, 48)],
	InkFigure.Kind.SHRINE_HEALER: [Vector2(19, 96), Vector2(30, 62)],
	InkFigure.Kind.SPEAR_GUARDIAN: [Vector2(26, 106), Vector2(40, 68)],
	InkFigure.Kind.ONMYOJI: [Vector2(19, 100), Vector2(32, 64)],
	InkFigure.Kind.HATAMOTO: [Vector2(29, 100), Vector2(42, 72)],
	InkFigure.Kind.FALLEN_DAIMYO: [Vector2(52, 90), Vector2(54, 78)],
	InkFigure.Kind.SPECTRAL_ARCHER: [Vector2(20, 90), Vector2(32, 55)],
	InkFigure.Kind.SHIELD_BEARER: [Vector2(25, 90), Vector2(38, 60)],
	InkFigure.Kind.FLYING_SPIRIT: [Vector2(20, 90), Vector2(32, 55)],
	InkFigure.Kind.BURNING_GENERAL: [Vector2(35, 90), Vector2(42, 65)],
}
## Kinds whose painted head ends in a cut neck: their head is drawn behind the torso, and a neck of the torso's own
## skin (centre, radii, sampled around; torso-cell pixels) rises from the shoulders into the head's jaw, so the head
## sits on the body instead of floating in front of the chest.
const NECKS: Dictionary = {
	InkFigure.Kind.ONI_BRUTE: [Vector2(150, 2), Vector2(38, 30), Vector2(140, 52)],
}
## A bare-headed look for a crowd (no painted head without its hat exists): the head drawn below its hat brim (the
## cut follows under the brim, left to right, past its torn edge) and a soft cap of its own hair over the skull
## (centre, radii, sampled around), all in head-cell pixels. See bare_head_mesh().
const BARE_HEADS: Dictionary = {
	InkFigure.Kind.HOLLOW_SOLDIER: [
		[Vector2(0, 182), Vector2(72, 172), Vector2(112, 136), Vector2(168, 102), Vector2(236, 100), Vector2(299, 114)],
		Vector2(166, 106), Vector2(68, 42), Vector2(126, 128)],
}
## Inside this fraction of its radius a patch is fully opaque; it fades to nothing at its rim.
const PATCH_FEATHER: float = 0.72
const PATCH_POINTS: int = 20
## The front shoulder cap's radius, as a fraction of the painted upper arm's width.
const CAP_RADIUS: float = 0.62
## An upper arm's painted layer starts this fraction of its length past the shoulder joint.
const ARM_TRIM: float = 0.03

static var _atlases: Dictionary = {}
static var _patches: Dictionary = {}
static var _images: Dictionary = {}
static var _regions: Dictionary = {}
static var _textures: Dictionary = {}
static var _frames: Dictionary = {}
static var _bounds: Dictionary = {}


static func has_part(kind: InkFigure.Kind, part_name: StringName) -> bool:
	if kind in [InkFigure.Kind.SHIELD_BEARER, InkFigure.Kind.BURNING_GENERAL] and part_name == &"weapon":
		return true
	if kind == InkFigure.Kind.SPECTRAL_ARCHER and part_name == &"quiver":
		return true
	return NAMES.has(kind) and CELLS.has(part_name)


static func cell_for(kind: InkFigure.Kind, part_name: StringName) -> int:
	if part_name == &"weapon": return 15
	if part_name == &"quiver": return 3
	if part_name == &"hem" and kind in [InkFigure.Kind.HATAMOTO, InkFigure.Kind.BURNING_GENERAL]: return 3
	return CELLS[part_name]


static func atlas(kind: InkFigure.Kind) -> Texture2D:
	if not _atlases.has(kind):
		_atlases[kind] = load("res://assets/art/roster/%s.png" % NAMES[kind]) as Texture2D
	return _atlases[kind]


static func region(kind: InkFigure.Kind, cell: int) -> Rect2:
	var key: int = int(kind) * 16 + cell
	if not _regions.has(key):
		if not _images.has(kind): _images[kind] = atlas(kind).get_image()
		_regions[key] = RosterAtlasRegions.REGIONS[kind][cell]
	return _regions[key]


static func texture(kind: InkFigure.Kind, part_name: StringName) -> AtlasTexture:
	var key: String = "%d:%s" % [kind, part_name]
	if not _textures.has(key):
		var part: AtlasTexture = AtlasTexture.new()
		part.atlas = atlas(kind)
		part.region = region(kind, cell_for(kind, part_name))
		part.filter_clip = true
		_textures[key] = part
	return _textures[key]


static func frame(kind: InkFigure.Kind, part_name: StringName) -> Transform2D:
	var key: String = "%d:%s" % [kind, part_name]
	if _frames.has(key): return _frames[key]
	var source: Rect2 = region(kind, cell_for(kind, part_name))
	if part_name == &"weapon" and WeaponRegistration.POINTS.has(kind):
		_frames[key] = WeaponRegistration.frame(kind, source)
		return _frames[key]
	var spec: FigureKinds.Spec = FigureKinds.spec(kind)
	var rect: Rect2
	var bone: float = 0.0
	var width: float = 0.0
	if String(part_name).begins_with("thigh"):
		bone = spec.thigh
		width = spec.thigh_w.x * 1.15
	elif String(part_name).begins_with("shin"):
		bone = spec.shin
		width = spec.shin_w.x if kind in [InkFigure.Kind.FALLEN_DAIMYO, InkFigure.Kind.BURNING_GENERAL] else minf(spec.shin_w.x, 9.0)
	elif String(part_name).begins_with("upper"):
		bone = spec.upper_arm
		width = spec.arm_w.x * 1.35
	elif String(part_name).begins_with("fore"):
		bone = spec.fore_arm
		width = spec.fore_w.x * 1.3
	if bone > 0.0:
		# The atlas contract puts proximal/distal joint centers at 12/88%.
		var axes: Vector2 = Vector2(bone / (source.size.x * 0.76), width / source.size.y)
		_frames[key] = Transform2D(0.0, axes, 0.0, -Vector2(source.size.x * 0.12, source.size.y * 0.5) * axes)
		if kind == InkFigure.Kind.ONI_BRUTE and String(part_name).begins_with("upper"):
			var a: Vector2 = source.size * Vector2(0.15, 0.32)
			var b: Vector2 = source.size * Vector2(0.88, 0.70)
			_frames[key] = Transform2D(0.0, Vector2(bone / a.distance_to(b), width / source.size.y), 0.0, Vector2.ZERO) * Transform2D((b - a).angle(), a).affine_inverse()
		return _frames[key]
	match part_name:
		&"weapon":
			rect = Rect2(-15.0, -4.0, 111.0 if kind == InkFigure.Kind.BURNING_GENERAL else 88.0, 8.0)
		&"quiver": rect = Rect2(-21.0, -35.0, 15.0, 36.0)
		&"head": rect = HEAD_RECTS[kind]
		&"torso":
			var body_width: float = WIDTHS[kind]
			rect = Rect2(-body_width * 0.5, spec.shoulder_front.y - 3.0, body_width, -spec.shoulder_front.y + 6.0)
			if kind == InkFigure.Kind.ONI_BRUTE: rect = Rect2(-20.5, -46.0, 41.0, 49.0)
		&"foot_f", &"foot_b": rect = Rect2(-3.5, -7.0, spec.foot + 3.5, 9.5)
		&"pauldron_front", &"pauldron_back": rect = Rect2(-8.0, -3.0, 16.0, 14.0)
		_:
			var skirt_height: float = 22.0
			if kind == InkFigure.Kind.FLYING_SPIRIT: skirt_height = 53.0
			if kind in [InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.ONMYOJI]: skirt_height = 35.0
			var skirt_width: float = float(WIDTHS[kind]) * 1.15
			rect = Rect2(-skirt_width * 0.5, -4.0, skirt_width, skirt_height)
			if part_name == &"hem" and kind == InkFigure.Kind.HATAMOTO:
				rect = Rect2(-34.0, -99.0, 23.0, 36.0)
			elif part_name == &"hem" and kind == InkFigure.Kind.YUMI_ARCHER:
				rect = Rect2(-20.0, -27.0, 16.0, 44.0)
			elif part_name == &"hem" and kind in [InkFigure.Kind.FALLEN_DAIMYO, InkFigure.Kind.BURNING_GENERAL]:
				rect = Rect2(-24.0, -29.0, 22.0, 68.0)
	_frames[key] = Transform2D(0.0, rect.size / source.size, 0.0, rect.position)
	return _frames[key]


static func bounds(kind: InkFigure.Kind, part_name: StringName) -> PackedVector2Array:
	var key: String = "%d:%s" % [kind, part_name]
	if not _bounds.has(key):
		var source: Rect2 = region(kind, cell_for(kind, part_name))
		_bounds[key] = SamuraiSpriteArt.alpha_bounds(_images[kind], source, frame(kind, part_name))
	return _bounds[key]


static func build_body(kind: InkFigure.Kind, parts: Dictionary) -> void:
	for part_name: StringName in CELLS:
		if not FigurePainter.layout(kind).has(part_name): continue
		var batch: InkBatch = InkBatch.new()
		batch.fill(bounds(kind, part_name), InkPalette.INK)
		parts[part_name] = batch
	if not ARMHOLES.has(kind):
		return
	# The front shoulder cap's own outline (torso space), like every other part's.
	var cap: InkBatch = InkBatch.new()
	var cap_patch: Array = shoulder_patch(kind, false)
	var cap_outline: PackedVector2Array = PackedVector2Array()
	var vertices: PackedVector2Array = cap_patch[1]
	for i: int in range(1 + PATCH_POINTS, 1 + PATCH_POINTS * 2):
		cap_outline.append(frame(kind, &"torso") * vertices[i])
	cap.fill_convex(cap_outline, InkPalette.INK)
	parts[&"shoulder_f"] = cap


## How many pixels to cut off an upper arm's proximal end so its open sleeve end never shows: up to just past its
## shoulder joint (the cut is under the shoulder cap or the torso).
static func arm_trim(kind: InkFigure.Kind, part_name: StringName) -> float:
	var joint: float = 0.15 if kind == InkFigure.Kind.ONI_BRUTE else 0.12
	return region(kind, CELLS[part_name]).size.x * (joint + ARM_TRIM)


## The head without its hat (BARE_HEADS) as one mesh [indices, vertices, colours, uvs] in head-cell pixels: the part
## below the brim, then the hair cap over it. Drawn with the head's own atlas in place of its layer.
static func bare_head_mesh(kind: InkFigure.Kind) -> Array:
	var key: String = "%d:bare" % kind
	if _patches.has(key):
		return _patches[key]
	var look: Array = BARE_HEADS[kind]
	var cell: Rect2 = region(kind, CELLS[&"head"])
	var atlas_size: Vector2 = atlas(kind).get_size()
	var below: PackedVector2Array = PackedVector2Array(look[0] as Array)
	below.append_array(PackedVector2Array([cell.size, Vector2(0.0, cell.size.y)]))
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for point: Vector2 in below:
		vertices.append(point)
		uvs.append((cell.position + point) / atlas_size)
		colors.append(Color.WHITE)
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(below)
	var cap: Array = _ellipse_patch_in(cell, atlas_size, look[1], look[2], look[3], false)
	var base: int = vertices.size()
	for index: int in (cap[0] as PackedInt32Array):
		indices.append(base + index)
	vertices.append_array(cap[1])
	colors.append_array(cap[2])
	uvs.append_array(cap[3])
	_patches[key] = [indices, vertices, colors, uvs]
	return _patches[key]


## A soft-edged ellipse of painted torso as [indices, vertices, colours, uvs], vertices in torso-cell pixels (draw it
## under the torso's frame with atlas()). `back` = the patch closing the armhole on the torso's left, sampled from
## its closed right shoulder mirrored; otherwise the cap over the front arm's open shoulder end, sampled in place
## from the torso's own front shoulder. Built once per kind.
static func shoulder_patch(kind: InkFigure.Kind, back: bool) -> Array:
	var key: String = "%d:%s" % [kind, back]
	if _patches.has(key):
		return _patches[key]
	var source_region: Rect2 = region(kind, CELLS[&"torso"])
	var torso_frame: Transform2D = frame(kind, &"torso")
	if back:
		var hole: Array = ARMHOLES[kind]
		var hole_center: Vector2 = hole[0]
		_patches[key] = _ellipse_patch(kind, hole_center, hole[1], Vector2(source_region.size.x - hole_center.x, hole_center.y), true)
	else:
		var spec: FigureKinds.Spec = FigureKinds.spec(kind)
		var center: Vector2 = torso_frame.affine_inverse() * spec.shoulder_front
		var radius: float = spec.arm_w.x * 1.35 * CAP_RADIUS
		# Broad deltoids and armour sit outside the torso's painted edge. Sample solid
		# chest paint there rather than a transparent shoulder-edge pixel.
		var sample: Vector2 = source_region.size * Vector2(0.72, 0.34) if kind in [InkFigure.Kind.ONI_BRUTE,
			InkFigure.Kind.FALLEN_DAIMYO, InkFigure.Kind.BURNING_GENERAL] else center
		_patches[key] = _ellipse_patch(kind, center, Vector2(radius / torso_frame.x.length(), radius / torso_frame.y.length()), sample, false)
	return _patches[key]


## Everything the torso part paints over its layer, as one mesh (one draw): the closed armhole and, for a kind in
## NECKS, the neck that joins the torso to the head drawn behind it. Empty if there is nothing to add.
static func torso_patch(kind: InkFigure.Kind) -> Array:
	var key: String = "%d:torso" % kind
	if _patches.has(key):
		return _patches[key]
	var meshes: Array = []
	if ARMHOLES.has(kind):
		meshes.append(shoulder_patch(kind, true))
	if NECKS.has(kind):
		var neck: Array = NECKS[kind]
		meshes.append(_ellipse_patch(kind, neck[0], neck[1], neck[2], false))
	var merged: Array = []
	for mesh: Array in meshes:
		if merged.is_empty():
			merged = [(mesh[0] as PackedInt32Array).duplicate(), (mesh[1] as PackedVector2Array).duplicate(),
					(mesh[2] as PackedColorArray).duplicate(), (mesh[3] as PackedVector2Array).duplicate()]
			continue
		var base: int = (merged[1] as PackedVector2Array).size()
		for index: int in (mesh[0] as PackedInt32Array):
			(merged[0] as PackedInt32Array).append(base + index)
		(merged[1] as PackedVector2Array).append_array(mesh[1])
		(merged[2] as PackedColorArray).append_array(mesh[2])
		(merged[3] as PackedVector2Array).append_array(mesh[3])
	_patches[key] = merged
	return merged


## A soft-edged ellipse of painted torso as [indices, vertices, colours, uvs], vertices in torso-cell pixels: drawn
## at `center` with `radii`, sampled around `source` (mirrored left-right when `mirror`). Opaque inside PATCH_FEATHER
## of its radius, fading to nothing at its rim, so no seam shows on the painting under it.
static func _ellipse_patch(kind: InkFigure.Kind, center: Vector2, radii: Vector2, source: Vector2, mirror: bool) -> Array:
	return _ellipse_patch_in(region(kind, CELLS[&"torso"]), atlas(kind).get_size(), center, radii, source, mirror)


## The same ellipse, sampled from any cell of an atlas.
static func _ellipse_patch_in(source_region: Rect2, atlas_size: Vector2, center: Vector2, radii: Vector2, source: Vector2,
		mirror: bool) -> Array:
	var vertices: PackedVector2Array = PackedVector2Array([center])
	var uvs: PackedVector2Array = PackedVector2Array([(source_region.position + source.clamp(Vector2.ZERO, source_region.size)) / atlas_size])
	var colors: PackedColorArray = PackedColorArray([Color.WHITE])
	var flip: Vector2 = Vector2(-1.0, 1.0) if mirror else Vector2.ONE
	for ring: float in [PATCH_FEATHER, 1.0]:
		for i: int in PATCH_POINTS:
			var offset: Vector2 = Vector2.from_angle(TAU * float(i) / float(PATCH_POINTS)) * radii * ring
			vertices.append(center + offset)
			var sample: Vector2 = (source + offset * flip).clamp(Vector2.ZERO, source_region.size)
			uvs.append((source_region.position + sample) / atlas_size)
			colors.append(Color(1.0, 1.0, 1.0, 1.0 if ring < 1.0 else 0.0))
	var indices: PackedInt32Array = PackedInt32Array()
	for i: int in PATCH_POINTS:
		var a: int = 1 + i
		var b: int = 1 + (i + 1) % PATCH_POINTS
		indices.append_array(PackedInt32Array([0, a, b, a, a + PATCH_POINTS, b, b, a + PATCH_POINTS, b + PATCH_POINTS]))
	return [indices, vertices, colors, uvs]


static func paint_tail(kind: InkFigure.Kind, ci: CanvasItem, points: PackedVector2Array, width: float) -> void:
	SamuraiSpriteArt.paint_cloth(ci, SamuraiSpriteArt.smooth_ribbon(points), width, true, region(kind, 14), atlas(kind))
