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
	InkFigure.Kind.FALLEN_DAIMYO: Rect2(-17, -33, 35, 35),
}
const WIDTHS: Dictionary = {
	InkFigure.Kind.ASHIGARU: 21.0, InkFigure.Kind.YUMI_ARCHER: 21.0,
	InkFigure.Kind.SHRINE_HEALER: 20.0, InkFigure.Kind.SPEAR_GUARDIAN: 33.0,
	InkFigure.Kind.ONMYOJI: 23.0, InkFigure.Kind.HATAMOTO: 27.0,
	InkFigure.Kind.HOLLOW_SOLDIER: 21.0, InkFigure.Kind.ONI_BRUTE: 41.0,
	InkFigure.Kind.FALLEN_DAIMYO: 36.0,
}
static var _atlases: Dictionary = {}
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


static func paint_tail(kind: InkFigure.Kind, ci: CanvasItem, points: PackedVector2Array, width: float) -> void:
	SamuraiSpriteArt.paint_cloth(ci, SamuraiSpriteArt.smooth_ribbon(points), width, true, region(kind, 14), atlas(kind))
