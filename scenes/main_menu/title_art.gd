extends Control
## Title screen artwork over the Bamboo Outskirts backdrop: a dark wash behind the menu column,
## an ink rock outcrop, the original painted samurai against the moon, and drifting bamboo
## leaves. Hair and free robe edges breathe in the wind; soles stay pinned. Ignores input.

## The backdrop's moon (BambooOutskirtsPainter) and its layer depth, to line the samurai up with it.
const MOON_POSITION: Vector2 = Vector2(1480.0, 230.0)
const MOON_DEPTH: float = 0.04
const DESIGN_CENTER: Vector2 = Vector2(960.0, 540.0)
const SAMURAI_HEIGHT: float = 540.0
## How far below the moon's centre the samurai's feet stand.
const LEDGE_DROP: float = 450.0
const LEAF_COUNT: int = 14

var _portrait: PortraitMotion
var _clock: float = 0.0
var _leaf_seeds: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait = PortraitMotion.new()
	_portrait.name = "Samurai"
	add_child(_portrait)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in LEAF_COUNT:
		_leaf_seeds.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.6, 1.4), rng.randf() * TAU))
	resized.connect(_place_figure)
	_place_figure()


func _process(delta: float) -> void:
	_clock += delta
	_portrait.reduced_motion = GameSettings.reduced_decorative_motion
	_portrait.set_time(_clock)
	queue_redraw()


## Where the moon is drawn on this screen (the backdrop shifts it on wide screens).
func get_moon_position() -> Vector2:
	return MOON_POSITION + BackdropLayer.parallax_offset(size * 0.5, DESIGN_CENTER, MOON_DEPTH)


func get_ledge_position() -> Vector2:
	return get_moon_position() + Vector2(10.0, LEDGE_DROP)


func _place_figure() -> void:
	if _portrait != null:
		_portrait.position = get_ledge_position() + Vector2(0.0, -8.0)
		_portrait.scale = Vector2(-1.0, 1.0) * SAMURAI_HEIGHT / 104.0


func get_portrait_rect() -> Rect2:
	var width: float = SAMURAI_HEIGHT * 0.68
	return Rect2(get_ledge_position() + Vector2(-width * 0.5, -8.0 - SAMURAI_HEIGHT), Vector2(width, SAMURAI_HEIGHT))


func _draw() -> void:
	# Dark wash behind the menu column (left) and along the bottom, so text reads on the art.
	var wash: Color = InkPalette.UI_CHARCOAL
	draw_polygon(PackedVector2Array([Vector2(0.0, 0.0), Vector2(size.x * 0.38, 0.0), Vector2(size.x * 0.38, size.y), Vector2(0.0, size.y)]),
			PackedColorArray([Color(wash, 0.96), Color(wash, 0.76), Color(wash, 0.76), Color(wash, 0.96)]))
	draw_polygon(PackedVector2Array([Vector2(size.x * 0.38, 0.0), Vector2(size.x * 0.68, 0.0),
			Vector2(size.x * 0.68, size.y), Vector2(size.x * 0.38, size.y)]),
			PackedColorArray([Color(wash, 0.76), Color(wash, 0.0), Color(wash, 0.0), Color(wash, 0.76)]))
	InkBrush.gradient_rect(self, Rect2(0.0, size.y * 0.72, size.x, size.y * 0.28), Color(wash, 0.0), Color(wash, 0.75))
	_draw_outcrop()
	_draw_leaves()


func _draw_outcrop() -> void:
	var ledge: Vector2 = get_ledge_position()
	var base_y: float = maxf(size.y, ledge.y + 200.0) + 10.0
	var rock: PackedVector2Array = PackedVector2Array([
		Vector2(ledge.x - 290.0, base_y), Vector2(ledge.x - 210.0, ledge.y + 240.0), Vector2(ledge.x - 180.0, ledge.y + 155.0),
		Vector2(ledge.x - 110.0, ledge.y + 55.0), Vector2(ledge.x - 95.0, ledge.y + 10.0), Vector2(ledge.x - 60.0, ledge.y - 8.0),
		Vector2(ledge.x + 60.0, ledge.y - 8.0), Vector2(ledge.x + 110.0, ledge.y + 18.0), Vector2(ledge.x + 165.0, ledge.y + 85.0),
		Vector2(ledge.x + 235.0, ledge.y + 130.0), Vector2(ledge.x + 290.0, ledge.y + 220.0), Vector2(size.x + 40.0, ledge.y + 270.0),
		Vector2(size.x + 40.0, base_y)])
	InkBrush.fill(self, rock, InkPalette.INK)
	InkBrush.stroke(self, PackedVector2Array([ledge + Vector2(-95.0, 10.0), ledge + Vector2(-60.0, -8.0),
			ledge + Vector2(60.0, -8.0), ledge + Vector2(110.0, 18.0)]), 2.0, 0.6, Color(InkPalette.GROUND_TOP, 0.6))
	# A few dry-brush cracks in the stone.
	var crack: Color = InkPalette.INK_DETAIL
	InkBrush.stroke(self, PackedVector2Array([ledge + Vector2(-90.0, 30.0), ledge + Vector2(-70.0, 90.0), ledge + Vector2(-110.0, 160.0)]), 4.0, 1.5, crack)
	InkBrush.stroke(self, PackedVector2Array([ledge + Vector2(70.0, 40.0), ledge + Vector2(120.0, 120.0), ledge + Vector2(100.0, 200.0)]), 4.0, 1.5, crack)
	InkBrush.stroke(self, PackedVector2Array([ledge + Vector2(-200.0, 160.0), ledge + Vector2(-160.0, 230.0)]), 3.0, 1.5, crack)


func _draw_leaves() -> void:
	var color: Color = Color(InkPalette.BAMBOO_NEAR, 0.85)
	for i: int in _leaf_seeds.size():
		var seed_value: Vector4 = _leaf_seeds[i]
		var speed: float = seed_value.z
		var travel: float = _clock * 70.0 * speed
		var x: float = fposmod(seed_value.x * (size.x + 400.0) - travel * 1.4, size.x + 400.0) - 200.0
		var y: float = fposmod(seed_value.y * (size.y + 200.0) + travel, size.y + 200.0) - 100.0
		var angle: float = seed_value.w + _clock * 1.5 * speed
		var length: float = 26.0 + 10.0 * speed
		var direction: Vector2 = Vector2.from_angle(angle)
		var normal: Vector2 = direction.orthogonal() * (3.5 + 1.5 * absf(sin(angle * 2.0)))
		var base: Vector2 = Vector2(x, y) - direction * length * 0.5
		InkBrush.fill_convex(self, PackedVector2Array([base, base + direction * length * 0.32 + normal,
				base + direction * length, base + direction * length * 0.32 - normal]), color)
