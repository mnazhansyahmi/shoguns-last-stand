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
const ROCK: Texture2D = preload("res://assets/art/samurai/title_rock.png")
const ROCK_ANCHOR: Vector2 = Vector2(900.0, 187.5)
const ROCK_SCALE: float = 0.7

var _portrait: PortraitMotion
var _clock: float = 0.0
var _leaf_seeds: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
		_portrait.scale = Vector2.ONE * SAMURAI_HEIGHT / PortraitMotion.ART_HEIGHT


func get_portrait_rect() -> Rect2:
	var unit: float = SAMURAI_HEIGHT / PortraitMotion.ART_HEIGHT
	var top_left: Vector2 = -PortraitMotion.FOOT_ANCHOR * unit
	return Rect2(_portrait.position + top_left, PortraitMotion.ART.get_size() * unit)


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
	var rock_rect: Rect2 = Rect2(ledge - ROCK_ANCHOR * ROCK_SCALE, ROCK.get_size() * ROCK_SCALE)
	draw_texture_rect(ROCK, rock_rect, false, Color(0.65, 0.62, 0.72))
	# Small contact shadows follow the two fixed soles, not the hair/cloth wind.
	for foot: Vector2 in [Vector2(-51.0, -7.0), Vector2(49.0, -11.0)]:
		for layer: int in 3:
			draw_set_transform(ledge + foot + Vector2(-5.0, 2.0), 0.0, Vector2(1.0, 0.12))
			draw_circle(Vector2.ZERO, 37.0 - layer * 6.0, Color(InkPalette.INK, 0.12 + layer * 0.08))
	draw_set_transform(Vector2.ZERO)


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
