extends Control
## A single shared scene underneath stable menu controls. No figure/rock compositing.
const LEAF_COUNT: int = 18
var _painting: LivingMenuPainting
var _overlay: Node2D
var _clock: float = 0.0
var _seeds: PackedVector4Array = PackedVector4Array()
var _scene_rect: Rect2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop: Node2D = get_parent().get_node_or_null("Backdrop") as Node2D
	if backdrop != null:
		backdrop.hide()
		backdrop.process_mode = Node.PROCESS_MODE_DISABLED
	_painting = LivingMenuPainting.new()
	_painting.name = "ScenePainting"
	add_child(_painting)
	_overlay = Node2D.new()
	_overlay.name = "LeavesAndWash"
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlays)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 19
	for i: int in LEAF_COUNT: _seeds.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.6, 1.3), rng.randf() * TAU))
	resized.connect(_place_scene)
	_place_scene()


func _place_scene() -> void:
	var factor: float = maxf(size.x / LivingMenuPainting.ART.get_width(), size.y / LivingMenuPainting.ART.get_height()) * 1.015
	_scene_rect = Rect2((size - LivingMenuPainting.ART.get_size() * factor) * 0.5, LivingMenuPainting.ART.get_size() * factor)
	_painting.scale = Vector2.ONE * factor
	_painting.position = _scene_rect.position


func _process(delta: float) -> void:
	_clock += delta
	var amount: float = 0.15 if GameSettings.reduced_decorative_motion else 1.0
	_painting.reduced_motion = GameSettings.reduced_decorative_motion
	_painting.set_time(_clock)
	_painting.position = _scene_rect.position + Vector2(sin(_clock * 0.12) * 3, cos(_clock * 0.10) * 1.5) * amount
	_overlay.queue_redraw()


func get_moon_position() -> Vector2:
	return _painting.position + _scene_rect.size * Vector2(0.738, 0.18)


func get_portrait_rect() -> Rect2:
	return Rect2(_painting.position + _scene_rect.size * Vector2(0.72, 0.02), _scene_rect.size * Vector2(0.27, 0.84))


func get_foot_contacts() -> PackedVector2Array:
	return PackedVector2Array([_painting.position + _scene_rect.size * Vector2(0.77, 0.822),
		_painting.position + _scene_rect.size * Vector2(0.878, 0.843)])


func _draw_overlays() -> void:
	var shade: Color = Color(0.035, 0.027, 0.04)
	_overlay.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x * 0.55, 0), Vector2(size.x * 0.55, size.y), Vector2(0, size.y)]),
		PackedColorArray([Color(shade, 0.72), Color(shade, 0), Color(shade, 0), Color(shade, 0.72)]))
	var amount: float = 0.15 if GameSettings.reduced_decorative_motion else 1.0
	for i: int in _seeds.size():
		var seed_value: Vector4 = _seeds[i]
		var travel: float = _clock * seed_value.z * 32.0 * amount
		var point: Vector2 = Vector2(fposmod(seed_value.x * (size.x + 100) - travel, size.x + 100) - 50,
			fposmod(seed_value.y * (size.y + 100) + travel * 0.5, size.y + 100) - 50)
		var angle: float = seed_value.w + _clock * 0.7 * amount
		var dir: Vector2 = Vector2.from_angle(angle) * (9.0 if i % 3 == 0 else 14.0)
		var normal: Vector2 = dir.orthogonal() * 0.25
		var color: Color = Color(0.91, 0.65, 0.56, 0.65) if i % 3 == 0 else Color(0.52, 0.19, 0.10, 0.8)
		_overlay.draw_colored_polygon(PackedVector2Array([point - dir, point + normal, point + dir, point - normal]), color)
