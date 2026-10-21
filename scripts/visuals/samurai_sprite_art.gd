class_name SamuraiSpriteArt
extends RefCounted
## Original painted layers derived from the approved slim swordsman. Regions and joint
## anchors are authored once; all instances share AtlasTextures and rigid draw transforms.

const ATLAS: Texture2D = preload("res://assets/art/samurai/body_trunk.png")
const ARMS: Texture2D = preload("res://assets/art/samurai/body_arms.png")
const LEGS: Texture2D = preload("res://assets/art/samurai/body_legs.png")
const DETAILS: Texture2D = preload("res://assets/art/samurai/body_details.png")
const FLOW: Texture2D = preload("res://assets/art/samurai/body_flow.png")
const LEGACY: Texture2D = preload("res://assets/art/samurai/slim_parts.png")
const HEAD: Texture2D = preload("res://assets/art/roster/samurai_head.png")
## Same logical body-part layout; four detail sheets give each bone layer more pixels.
const SOURCES: Dictionary = SamuraiBodyLayout.SOURCES
const RECTS: Dictionary = {
	&"head": Rect2(-8.0, -17.5, 20.0, 21.0),
	&"mane": Rect2(-35.0, -21.0, 31.0, 19.0),
	&"torso": Rect2(-12.5, -36.0, 26.0, 39.0),
	&"skirt": Rect2(-16.0, -4.5, 34.0, 29.0),
	&"foot_f": Rect2(-3.5, -7.0, 14.0, 9.5),
	&"foot_b": Rect2(-3.5, -7.0, 14.0, 9.5),
	&"weapon": Rect2(-25.0, -5.0, 100.0, 8.5),
}
## Pixel-space proximal/distal joints in each cropped layer, target bone length and
## cross-axis pixel scale. This corrects the painter's natural diagonal cloth direction.
const JOINTS: Dictionary = SamuraiBodyLayout.JOINTS

## The ponytail keeps at least this fraction of its length between root and tip, bends by at most this fraction of
## that span, and is drawn along this many points (hair_spine()).
const HAIR_MIN_SPAN: float = 0.7
const HAIR_MAX_BEND: float = 0.3
const HAIR_SPINE_POINTS: int = 8

static var _textures: Dictionary = {}
static var _frames: Dictionary = {}
static var _ribbon_indices: Dictionary = {}
static var _bounds: Dictionary = {}
static var _source_image: Image
static var _images: Dictionary = {}

## Authored cloth within the same atlas: no solid geometric substitute over the paint.
const SASH_REGION: Rect2 = SamuraiBodyLayout.SOURCES[&"sash"]
const SLEEVE_REGION: Rect2 = SamuraiBodyLayout.SOURCES[&"sleeve_f"]


## The ponytail's spine from its hair chain: one gentle curve from the root toward where the chain's tip points, never
## shorter than HAIR_MIN_SPAN of the chain's length. A chain bunched up by a sudden stop or a cut would otherwise fold
## the painted tuft over itself into a dark blot.
static func hair_spine(points: PackedVector2Array) -> PackedVector2Array:
	var length: float = 0.0
	for i: int in range(1, points.size()):
		length += points[i].distance_to(points[i - 1])
	var root: Vector2 = points[0]
	var reach: Vector2 = points[-1] - root
	var span: float = maxf(reach.length(), length * HAIR_MIN_SPAN)
	var direction: Vector2 = reach.normalized() if reach.length() > 0.01 else Vector2.LEFT
	reach = direction * span
	var middle: Vector2 = root + reach * 0.5
	var control: Vector2 = middle + (points[points.size() / 2] - middle).limit_length(span * HAIR_MAX_BEND)
	var spine: PackedVector2Array = PackedVector2Array()
	for i: int in HAIR_SPINE_POINTS:
		var u: float = float(i) / float(HAIR_SPINE_POINTS - 1)
		spine.append(root.lerp(control, u).lerp(control.lerp(root + reach, u), u))
	return spine


static func smooth_ribbon(points: PackedVector2Array) -> PackedVector2Array:
	var smooth: PackedVector2Array = PackedVector2Array()
	for i: int in points.size() - 1:
		for step: int in 3:
			smooth.append(points[i].cubic_interpolate(points[i + 1], points[maxi(0, i - 1)],
					points[mini(points.size() - 1, i + 2)], float(step) / 3.0))
	smooth.append(points[-1])
	return smooth


## `end_width` >= 0 tapers the strip from `width` at the first point to it at the last (a bow limb, an arrow).
static func paint_cloth(ci: CanvasItem, points: PackedVector2Array, width: float, sash: bool,
		source_region: Rect2 = Rect2(), atlas: Texture2D = FLOW, end_width: float = -1.0) -> void:
	if points.size() < 2:
		return
	var vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var region: Rect2 = SASH_REGION if sash else SLEEVE_REGION
	if source_region.has_area():
		region = source_region
	var atlas_size: Vector2 = atlas.get_size()
	for side: int in 2:
		for step: int in points.size():
			var i: int = step if side == 0 else points.size() - 1 - step
			var t: float = float(i) / float(points.size() - 1)
			var tangent: Vector2 = points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]
			var normal: Vector2 = tangent.normalized().orthogonal()
			var across: float = width if end_width < 0.0 else lerpf(width, end_width, t)
			vertices.append(points[i] + normal * across * (0.5 if side == 0 else -0.5))
			var uv: Vector2 = Vector2(1.0 - t, float(side)) if sash else Vector2(float(side), t)
			uvs.append((region.position + uv * region.size) / atlas_size)
	# A cloth chain can curl across itself. Explicit strip triangles remain valid
	# where polygon ear-clipping cannot triangulate a self-crossing outline.
	var count: int = points.size()
	if not _ribbon_indices.has(count):
		var triangles: PackedInt32Array = PackedInt32Array()
		for i: int in count - 1:
			var opposite: int = count * 2 - 1 - i
			triangles.append_array(PackedInt32Array([i, i + 1, opposite, i + 1, opposite - 1, opposite]))
		_ribbon_indices[count] = triangles
	var indices: PackedInt32Array = _ribbon_indices[count]
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, vertices,
			PackedColorArray([Color.WHITE]), uvs, PackedInt32Array(), PackedFloat32Array(), atlas.get_rid())


## The layer drawn through its own painted outline (the largest alpha shape in its region, grown a little to keep its
## soft edge) as [indices, vertices, colours, uvs] in layer pixels, so a neighbour's pixels inside the rectangle are
## left out. Empty if the outline cannot be triangulated (then the plain layer is drawn).
static func outline_mesh(part_name: StringName) -> Array:
	var key: String = "%s:mesh" % part_name
	if _bounds.has(key):
		return _bounds[key]
	if _source_image == null: _source_image = ATLAS.get_image()
	var source: Rect2 = SOURCES[part_name]
	var mask: BitMap = BitMap.new()
	mask.create_from_image_alpha(_source_image.get_region(Rect2i(source)), 0.05)
	var outline: PackedVector2Array = PackedVector2Array()
	var most: float = 0.0
	for polygon: PackedVector2Array in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, Vector2i(source.size)), 1.0):
		var area: float = absf(_area(polygon))
		if area > most:
			most = area
			outline = polygon
	var grown: Array[PackedVector2Array] = Geometry2D.offset_polygon(outline, 2.0)
	if not grown.is_empty():
		outline = grown[0]
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	var mesh: Array = []
	if not indices.is_empty():
		var uvs: PackedVector2Array = PackedVector2Array()
		var colors: PackedColorArray = PackedColorArray()
		for point: Vector2 in outline:
			uvs.append((source.position + point.clamp(Vector2.ZERO, source.size)) / ATLAS.get_size())
			colors.append(Color.WHITE)
		mesh = [indices, outline, colors, uvs]
	_bounds[key] = mesh
	return mesh


static func _area(polygon: PackedVector2Array) -> float:
	var area: float = 0.0
	for i: int in polygon.size():
		area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return area * 0.5


## All instances share their detail plate; no per-frame texture allocation.
static func atlas_for(part_name: StringName) -> Texture2D:
	if part_name == &"head": return HEAD
	if part_name == &"weapon": return LEGACY
	if part_name in [&"mane", &"sash"]: return FLOW
	if part_name in [&"upper_f", &"fore_f", &"upper_b", &"fore_b"]: return ARMS
	if part_name in [&"thigh_f", &"shin_f", &"thigh_b", &"shin_b"]: return LEGS
	if part_name in [&"foot_f", &"foot_b", &"sleeve_f", &"sleeve_b"]: return DETAILS
	return ATLAS


static func has_part(part_name: StringName) -> bool:
	return SOURCES.has(part_name)


static func texture(part_name: StringName) -> AtlasTexture:
	if not _textures.has(part_name):
		var art: AtlasTexture = AtlasTexture.new()
		art.atlas = atlas_for(part_name)
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
	if not _bounds.has(part_name):
		var atlas: Texture2D = atlas_for(part_name)
		if not _images.has(atlas): _images[atlas] = atlas.get_image()
		_bounds[part_name] = alpha_bounds(_images[atlas], SOURCES[part_name], frame(part_name))
	return _bounds[part_name]


## Actual painted contour, excluding transparent padding and the empty wedge
## above a sandal's toes. A convex box/hull would falsely join two planted legs.
static func alpha_bounds(image: Image, source: Rect2, transform: Transform2D) -> PackedVector2Array:
	var cropped: Image = image.get_region(Rect2i(source))
	var mask: BitMap = BitMap.new()
	mask.create_from_image_alpha(cropped, 0.1)
	var contours: Array[PackedVector2Array] = mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, cropped.get_size()), 1.0)
	var outline: PackedVector2Array = PackedVector2Array()
	var most: float = 0.0
	for polygon: PackedVector2Array in contours:
		var area: float = 0.0
		for i: int in polygon.size(): area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
		if absf(area) > most:
			most = absf(area)
			outline = polygon
	return transform * outline


static func build_body(parts: Dictionary) -> void:
	for part_name: StringName in SOURCES:
		if not FigurePainter.layout(InkFigure.Kind.SAMURAI).has(part_name): continue
		if FigurePainter.DYNAMIC_PARTS.has(part_name): continue
		# Bounds are conservative; independent feet end at the same sole as the solver.
		var batch: InkBatch = InkBatch.new()
		batch.fill(bounds(part_name), InkPalette.INK)
		parts[part_name] = batch
