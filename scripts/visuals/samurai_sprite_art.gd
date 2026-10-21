class_name SamuraiSpriteArt
extends RefCounted
## Original painted layers derived from the approved slim swordsman. Regions and joint
## anchors are authored once; all instances share AtlasTextures and rigid draw transforms.

const ATLAS: Texture2D = preload("res://assets/art/samurai/slim_parts.png")
const PORTRAIT: Texture2D = preload("res://assets/art/samurai/slim_menu.png")
const PORTRAIT_REGION: Rect2 = Rect2(2, 18, 1020, 1495)
const SOURCES: Dictionary = {
	&"head": Rect2(130, 116, 196, 235), &"mane": Rect2(941, 98, 305, 238),
	&"torso": Rect2(330, 68, 297, 291), &"skirt": Rect2(639, 70, 299, 298),
	&"upper_f": Rect2(42, 412, 261, 225), &"fore_f": Rect2(337, 442, 277, 166),
	&"thigh_f": Rect2(640, 391, 303, 248), &"shin_f": Rect2(955, 440, 260, 150),
	&"upper_b": Rect2(32, 687, 281, 250), &"fore_b": Rect2(336, 743, 280, 154),
	&"thigh_b": Rect2(639, 680, 300, 251), &"shin_b": Rect2(980, 737, 240, 170),
	&"foot_f": Rect2(68, 971, 232, 192), &"foot_b": Rect2(352, 972, 241, 190),
	&"weapon": Rect2(936, 1047, 309, 62),
}
const RECTS: Dictionary = {
	&"head": Rect2(-8.0, -18.5, 20.0, 24.0),
	&"mane": Rect2(-35.0, -24.0, 31.0, 19.0),
	&"torso": Rect2(-10.5, -36.0, 22.0, 39.0),
	&"skirt": Rect2(-13.5, -4.5, 27.0, 29.0),
	&"foot_f": Rect2(-3.5, -7.0, 12.5, 9.5),
	&"foot_b": Rect2(-3.5, -7.0, 12.5, 9.5),
	&"weapon": Rect2(-25.0, -5.0, 100.0, 8.5),
}
## Pixel-space proximal/distal joints in each cropped layer, target bone length and
## cross-axis pixel scale. This corrects the painter's natural diagonal cloth direction.
const JOINTS: Dictionary = {
	&"upper_f": [Vector2(22, 42), Vector2(230, 87), 13.0, 0.060],
	&"fore_f": [Vector2(26, 54), Vector2(242, 110), 13.0, 0.042],
	&"thigh_f": [Vector2(39, 60), Vector2(264, 170), 23.0, 0.075],
	&"shin_f": [Vector2(29, 65), Vector2(230, 93), 23.0, 0.058],
	&"upper_b": [Vector2(35, 55), Vector2(245, 93), 13.0, 0.056],
	&"fore_b": [Vector2(28, 53), Vector2(240, 100), 13.0, 0.042],
	&"thigh_b": [Vector2(35, 91), Vector2(266, 151), 23.0, 0.072],
	&"shin_b": [Vector2(32, 95), Vector2(225, 60), 23.0, 0.056],
}

static var _textures: Dictionary = {}
static var _frames: Dictionary = {}

## Authored cloth within the same atlas: no solid geometric substitute over the paint.
const SASH_REGION: Rect2 = Rect2(634, 1000, 296, 190)
const SLEEVE_REGION: Rect2 = Rect2(110, 515, 180, 115)


static func paint_cloth(ci: CanvasItem, points: PackedVector2Array, width: float, sash: bool) -> void:
	if points.size() < 2:
		return
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var region: Rect2 = SASH_REGION if sash else SLEEVE_REGION
	var atlas_size: Vector2 = ATLAS.get_size()
	for side: int in 2:
		for step: int in points.size():
			var i: int = step if side == 0 else points.size() - 1 - step
			var t: float = float(i) / float(points.size() - 1)
			var tangent: Vector2 = points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]
			var normal: Vector2 = tangent.normalized().orthogonal()
			vertices.append(points[i] + normal * width * (0.5 if side == 0 else -0.5))
			var uv: Vector2 = Vector2(1.0 - t, float(side)) if sash else Vector2(float(side), t)
			uvs.append((region.position + uv * region.size) / atlas_size)
	# A cloth chain can curl across itself. Explicit strip triangles remain valid
	# where polygon ear-clipping cannot triangulate a self-crossing outline.
	var indices: PackedInt32Array = PackedInt32Array()
	var count: int = points.size()
	for i: int in count - 1:
		var opposite: int = count * 2 - 1 - i
		indices.append_array(PackedInt32Array([i, i + 1, opposite, i + 1, opposite - 1, opposite]))
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, vertices,
			PackedColorArray([Color.WHITE]), uvs, PackedInt32Array(), PackedFloat32Array(), ATLAS.get_rid())


static func has_part(part_name: StringName) -> bool:
	return SOURCES.has(part_name)


static func texture(part_name: StringName) -> AtlasTexture:
	if not _textures.has(part_name):
		var art: AtlasTexture = AtlasTexture.new()
		art.atlas = ATLAS
		art.region = SOURCES[part_name]
		art.filter_clip = true
		_textures[part_name] = art
	return _textures[part_name]


static func frame(part_name: StringName) -> Transform2D:
	if not _frames.has(part_name):
		if JOINTS.has(part_name):
			var anchors: Array = JOINTS[part_name]
			var a: Vector2 = anchors[0]
			var b: Vector2 = anchors[1]
			var scale: Vector2 = Vector2(float(anchors[2]) / a.distance_to(b), float(anchors[3]))
			_frames[part_name] = Transform2D(0.0, scale, 0.0, Vector2.ZERO) * Transform2D((b - a).angle(), a).affine_inverse()
		else:
			var rect: Rect2 = RECTS[part_name]
			var source: Rect2 = SOURCES[part_name]
			_frames[part_name] = Transform2D(0.0, rect.size / source.size, 0.0, rect.position)
	return _frames[part_name]


## Draw-space bounds for ground checks and silhouette sampling. Textures are presentation
## layers, not collision shapes; metadata keeps those tests independent of a GPU.
static func bounds(part_name: StringName) -> PackedVector2Array:
	var source: Rect2 = SOURCES[part_name]
	return frame(part_name) * PackedVector2Array([Vector2.ZERO, Vector2(source.size.x, 0.0),
			source.size, Vector2(0.0, source.size.y)])


static func build_body(parts: Dictionary) -> void:
	for part_name: StringName in SOURCES:
		# Bounds are conservative; independent feet end at the same sole as the solver.
		var batch: InkBatch = InkBatch.new()
		batch.fill_convex(bounds(part_name), InkPalette.INK)
		parts[part_name] = batch
