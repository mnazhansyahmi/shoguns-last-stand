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
}
const CELLS: Dictionary = {
	&"head": 0, &"torso": 1, &"skirt": 2, &"hem": 2,
	&"upper_f": 4, &"fore_f": 5, &"thigh_f": 6, &"shin_f": 7,
	&"upper_b": 8, &"fore_b": 9, &"thigh_b": 10, &"shin_b": 11,
	&"foot_f": 12, &"foot_b": 13,
	&"pauldron_front": 4, &"pauldron_back": 8,
}
const HEAD_RECTS: Dictionary = {
	InkFigure.Kind.ASHIGARU: Rect2(-14, -21, 28, 23),
	InkFigure.Kind.YUMI_ARCHER: Rect2(-10, -20, 22, 22),
	InkFigure.Kind.SHRINE_HEALER: Rect2(-10, -22, 22, 24),
	InkFigure.Kind.SPEAR_GUARDIAN: Rect2(-13, -31, 29, 33),
	InkFigure.Kind.ONMYOJI: Rect2(-11, -29, 22, 31),
	InkFigure.Kind.HATAMOTO: Rect2(-16, -34, 32, 36),
	InkFigure.Kind.HOLLOW_SOLDIER: Rect2(-12, -20, 26, 22),
	InkFigure.Kind.ONI_BRUTE: Rect2(-18, -27, 39, 29),
	# The helmet sits down on his collar (its painted cords hang over the cuirass).
	InkFigure.Kind.FALLEN_DAIMYO: Rect2(-17, -28, 35, 35),
}
const WIDTHS: Dictionary = {
	InkFigure.Kind.ASHIGARU: 21.0, InkFigure.Kind.YUMI_ARCHER: 21.0,
	InkFigure.Kind.SHRINE_HEALER: 20.0, InkFigure.Kind.SPEAR_GUARDIAN: 33.0,
	InkFigure.Kind.ONMYOJI: 23.0, InkFigure.Kind.HATAMOTO: 27.0,
	InkFigure.Kind.HOLLOW_SOLDIER: 21.0, InkFigure.Kind.ONI_BRUTE: 41.0,
	InkFigure.Kind.FALLEN_DAIMYO: 36.0,
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
	return NAMES.has(kind) and CELLS.has(part_name)


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
		part.region = region(kind, 3 if kind == InkFigure.Kind.HATAMOTO and part_name == &"hem" else CELLS[part_name])
		part.filter_clip = true
		_textures[key] = part
	return _textures[key]


static func frame(kind: InkFigure.Kind, part_name: StringName) -> Transform2D:
	var key: String = "%d:%s" % [kind, part_name]
	if _frames.has(key): return _frames[key]
	var source: Rect2 = region(kind, 3 if kind == InkFigure.Kind.HATAMOTO and part_name == &"hem" else CELLS[part_name])
	var spec: FigureKinds.Spec = FigureKinds.spec(kind)
	var rect: Rect2
	var bone: float = 0.0
	var width: float = 0.0
	if String(part_name).begins_with("thigh"):
		bone = spec.thigh
		width = spec.thigh_w.x * 1.15
	elif String(part_name).begins_with("shin"):
		bone = spec.shin
		width = minf(spec.shin_w.x, 9.0)
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
		&"head": rect = HEAD_RECTS[kind]
		&"torso":
			var body_width: float = WIDTHS[kind]
			rect = Rect2(-body_width * 0.5, spec.shoulder_front.y - 3.0, body_width, -spec.shoulder_front.y + 6.0)
			if kind == InkFigure.Kind.ONI_BRUTE: rect = Rect2(-20.5, -46.0, 41.0, 49.0)
		&"foot_f", &"foot_b": rect = Rect2(-3.5, -7.0, spec.foot + 3.5, 9.5)
		&"pauldron_front", &"pauldron_back": rect = Rect2(-8.0, -3.0, 16.0, 14.0)
		_:
			var skirt_height: float = 22.0
			if kind in [InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.ONMYOJI]: skirt_height = 35.0
			var skirt_width: float = float(WIDTHS[kind]) * 1.15
			rect = Rect2(-skirt_width * 0.5, -4.0, skirt_width, skirt_height)
			if part_name == &"hem" and kind == InkFigure.Kind.HATAMOTO:
				rect = Rect2(-34.0, -99.0, 23.0, 36.0)
			elif part_name == &"hem" and kind == InkFigure.Kind.YUMI_ARCHER:
				rect = Rect2(-20.0, -27.0, 16.0, 44.0)
			elif part_name == &"hem" and kind == InkFigure.Kind.FALLEN_DAIMYO:
				rect = Rect2(-24.0, -33.0, 23.0, 76.0)
	_frames[key] = Transform2D(0.0, rect.size / source.size, 0.0, rect.position)
	return _frames[key]


static func bounds(kind: InkFigure.Kind, part_name: StringName) -> PackedVector2Array:
	var key: String = "%d:%s" % [kind, part_name]
	if not _bounds.has(key):
		var source: Rect2 = region(kind, 3 if kind == InkFigure.Kind.HATAMOTO and part_name == &"hem" else CELLS[part_name])
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
	var center: Vector2
	var radii: Vector2
	var source: Vector2
	if back:
		var hole: Array = ARMHOLES[kind]
		center = hole[0]
		radii = hole[1]
		source = Vector2(source_region.size.x - center.x, center.y)
	else:
		var spec: FigureKinds.Spec = FigureKinds.spec(kind)
		center = torso_frame.affine_inverse() * spec.shoulder_front
		var radius: float = spec.arm_w.x * 1.35 * CAP_RADIUS
		radii = Vector2(radius / torso_frame.x.length(), radius / torso_frame.y.length())
		source = center
	var atlas_size: Vector2 = atlas(kind).get_size()
	var vertices: PackedVector2Array = PackedVector2Array([center])
	var uvs: PackedVector2Array = PackedVector2Array([(source_region.position + source) / atlas_size])
	var colors: PackedColorArray = PackedColorArray([Color.WHITE])
	var mirror: Vector2 = Vector2(-1.0, 1.0) if back else Vector2.ONE
	for ring: float in [PATCH_FEATHER, 1.0]:
		for i: int in PATCH_POINTS:
			var offset: Vector2 = Vector2.from_angle(TAU * float(i) / float(PATCH_POINTS)) * radii * ring
			vertices.append(center + offset)
			var sample: Vector2 = (source + offset * mirror).clamp(Vector2.ZERO, source_region.size)
			uvs.append((source_region.position + sample) / atlas_size)
			colors.append(Color(1.0, 1.0, 1.0, 1.0 if ring < 1.0 else 0.0))
	var indices: PackedInt32Array = PackedInt32Array()
	for i: int in PATCH_POINTS:
		var a: int = 1 + i
		var b: int = 1 + (i + 1) % PATCH_POINTS
		indices.append_array(PackedInt32Array([0, a, b, a, a + PATCH_POINTS, b, b, a + PATCH_POINTS, b + PATCH_POINTS]))
	_patches[key] = [indices, vertices, colors, uvs]
	return _patches[key]


static func paint_tail(kind: InkFigure.Kind, ci: CanvasItem, points: PackedVector2Array, width: float) -> void:
	SamuraiSpriteArt.paint_cloth(ci, SamuraiSpriteArt.smooth_ribbon(points), width, true, region(kind, 14), atlas(kind))
