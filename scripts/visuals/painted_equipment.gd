class_name PaintedEquipment
extends RefCounted
## Painted material over the existing equipment frames. Weapon reach and the
## gameplay hit geometry remain the original authored shapes. Bow strings and
## arrows retain their live draw/release positions; wood follows their curves.

const WEAPONS: Dictionary = {
	InkFigure.Kind.ASHIGARU: 0, InkFigure.Kind.SPEAR_GUARDIAN: 1,
	InkFigure.Kind.HATAMOTO: 2, InkFigure.Kind.ONMYOJI: 3,
	InkFigure.Kind.SHRINE_HEALER: 4, InkFigure.Kind.HOLLOW_SOLDIER: 5,
	InkFigure.Kind.ONI_BRUTE: 6, InkFigure.Kind.FALLEN_DAIMYO: 7,
	InkFigure.Kind.SAMURAI: 11,
}
static var _atlas: Texture2D
static var _textures: Dictionary = {}
static var _frames: Dictionary = {}
static var _wood: Rect2


static func atlas() -> Texture2D:
	if _atlas == null: _atlas = load("res://assets/art/roster/equipment.png") as Texture2D
	return _atlas


static func cell(kind: InkFigure.Kind, name: StringName) -> int:
	if name == &"weapon": return WEAPONS.get(kind, -1)
	if name == &"shield": return 8
	if name == &"quiver": return 10
	if name == &"hem" and kind == InkFigure.Kind.HATAMOTO: return 9
	return -1


static func texture(kind: InkFigure.Kind, name: StringName) -> AtlasTexture:
	var index: int = cell(kind, name)
	if not _textures.has(index):
		var part: AtlasTexture = AtlasTexture.new()
		part.atlas = atlas()
		part.region = EquipmentAtlasRegions.REGIONS[index]
		part.filter_clip = true
		_textures[index] = part
	return _textures[index]


static func frame(kind: InkFigure.Kind, name: StringName) -> Transform2D:
	var key: String = "%d:%s" % [kind, name]
	if not _frames.has(key):
		var points: PackedVector2Array = FigurePainter._original_vertices(FigurePainter.part(kind, name))
		var target: Rect2 = Rect2(points[0], Vector2.ZERO)
		for point: Vector2 in points: target = target.expand(point)
		if name == &"hem": target = Rect2(-34, -99, 23, 36)
		if kind == InkFigure.Kind.SAMURAI: target = Rect2(-15.0, -4.0, 90.0, 8.0)
		var source: Rect2 = EquipmentAtlasRegions.REGIONS[cell(kind, name)]
		_frames[key] = Transform2D(0.0, target.size / source.size, 0.0, target.position)
	return _frames[key]


static func draw_bow(ci: CanvasItem, figure: InkFigure) -> void:
	# Only the wood surface changes: existing strings, nock, arrow and draw
	# animation keep their exact positions and gameplay release timing.
	FigurePainter.bow(figure.pose.bow_draw, figure.kind).draw(ci)
	var step: int = FigurePainter.bow_step(figure.pose.bow_draw)
	var drawn: float = float(step) / float(FigurePainter.BOW_STEPS)
	for side: int in 2:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 9:
			var t: float = float(i) / 8.0
			points.append(Vector2(FigurePainter._bow_bend(t, drawn), t * (-FigurePainter.BOW_UPPER if side == 0 else FigurePainter.BOW_LOWER)))
		_draw_wood(ci, points, 5.0)


static func draw_stowed_bow(ci: CanvasItem, batch: InkBatch) -> void:
	batch.draw(ci)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 15:
		points.append(FigurePainter._quadratic(Vector2(-10, -2), Vector2(-25.5, -32), Vector2(-20, -64), float(i) / 14.0))
	_draw_wood(ci, points, 2.0)


static func _draw_wood(ci: CanvasItem, points: PackedVector2Array, width: float) -> void:
	if not _wood.has_area():
		# A shaft's real painted wood, away from its metal head and cord.
		_wood = EquipmentAtlasRegions.WOOD
	SamuraiSpriteArt.paint_cloth(ci, points, width, true, _wood, atlas())
