extends Control
## Stationary painted landscape. Only the extracted character is animated.
var _painting: LivingMenuPainting
var _overlay: Node2D
var _clock: float = 0.0
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
	_overlay.name = "StaticMenuWash"
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlays)
	resized.connect(_place_scene)
	_place_scene()


func _place_scene() -> void:
	var factor: float = maxf(size.x / LivingMenuPainting.ART.get_width(), size.y / LivingMenuPainting.ART.get_height()) * 1.015
	_scene_rect = Rect2((size - LivingMenuPainting.ART.get_size() * factor) * 0.5, LivingMenuPainting.ART.get_size() * factor)
	_painting.scale = Vector2.ONE * factor
	_painting.position = _scene_rect.position
	_overlay.queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	_painting.reduced_motion = GameSettings.reduced_decorative_motion
	_painting.set_time(_clock)


func get_moon_position() -> Vector2:
	return _painting.position + _scene_rect.size * Vector2(0.738, 0.18)


func get_portrait_rect() -> Rect2:
	return Rect2(_painting.position + _scene_rect.size * Vector2(0.72, 0.02), _scene_rect.size * Vector2(0.27, 0.84))


func get_foot_contacts() -> PackedVector2Array:
	var soles: PackedVector2Array = PackedVector2Array()
	for pixel: Vector2 in [Vector2(1288, 864), Vector2(1484, 889)]:
		soles.append(_painting.position + (pixel * LivingMenuPainting.CHARACTER_SCALE + LivingMenuPainting.CHARACTER_OFFSET) * _painting.scale)
	return soles


func _draw_overlays() -> void:
	var shade: Color = Color(0.035, 0.027, 0.04)
	_overlay.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x * 0.55, 0), Vector2(size.x * 0.55, size.y), Vector2(0, size.y)]),
		PackedColorArray([Color(shade, 0.72), Color(shade, 0), Color(shade, 0), Color(shade, 0.72)]))
