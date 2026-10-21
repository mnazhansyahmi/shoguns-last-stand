class_name InkMenuButton
extends Button
## A main-menu button in the ink style. Its theme variation (BrushButton / BrushButtonSub) strips the normal button
## boxes and sets the gold serif text; this class draws what a box cannot: a brush-stroke background with rough, ragged
## ink edges (built once per size), and, when the button is hovered or focused, a crimson brush underline that sweeps
## in from the left, a slight scale-up and a soft katana slash sound. An optional small line (`sub_caption`) is drawn
## under the label. Keyboard, gamepad and touch use the ordinary Button behaviour.

const SWEEP_TIME: float = 0.22
const HOVER_SCALE: float = 1.045
## The body of the stroke leaves this fraction of the height clear above and below.
const BODY_INSET: float = 0.1
const SUB_CAPTION_SIZE: int = 26
const EDGE_STEPS: int = 20

## The small line under the label ("Stage 3 - Misty Grove"); "" for none. Use the BrushButtonSub variation for a button
## that has one, so the label leaves room for it.
var sub_caption: String = "":
	set(value):
		sub_caption = value
		queue_redraw()

var _sweep: float = 0.0
var _target: float = 0.0
## The slash sound is only played once the menu has been up a moment (the first focus when it opens is silent).
var _armed: bool = false
var _body: PackedVector2Array = PackedVector2Array()
var _body_triangles: PackedInt32Array = PackedInt32Array()
var _bleed: PackedVector2Array = PackedVector2Array()
var _bleed_triangles: PackedInt32Array = PackedInt32Array()
var _top_edge: PackedVector2Array = PackedVector2Array()
var _bottom_edge: PackedVector2Array = PackedVector2Array()
var _streaks: Array[PackedVector2Array] = []
var _batch: InkBatch = InkBatch.new()


func _ready() -> void:
	set_process(false)
	mouse_entered.connect(_refresh_active)
	mouse_exited.connect(_refresh_active)
	focus_entered.connect(_refresh_active)
	focus_exited.connect(_refresh_active)
	resized.connect(_on_resized)
	_on_resized()
	get_tree().create_timer(0.35).timeout.connect(_arm)


func _arm() -> void:
	_armed = true


## 0 = idle, 1 = the underline has fully swept in.
func get_sweep() -> float:
	return _sweep


## True while the button is hovered or focused.
func is_active() -> bool:
	return _target > 0.5


func _refresh_active() -> void:
	var active: bool = is_hovered() or has_focus()
	var was_active: bool = _target > 0.5
	_target = 1.0 if active else 0.0
	if active and not was_active and _armed:
		AudioManager.play(&"menu_hover", 1.3)
	set_process(true)


func _on_resized() -> void:
	pivot_offset = size * 0.5
	_rebuild_shape()
	queue_redraw()


func _process(delta: float) -> void:
	_sweep = move_toward(_sweep, _target, delta / SWEEP_TIME)
	scale = Vector2.ONE * lerpf(1.0, HOVER_SCALE, ease(_sweep, -2.0))
	queue_redraw()
	if is_equal_approx(_sweep, _target):
		set_process(false)


## The stroke: a ragged-edged body, a slightly larger faint "bleed" of ink behind it and a few dry-brush streaks.
## Seeded by the node's name, so each button has its own stroke and it never changes between frames.
func _rebuild_shape() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(str(name))
	var w: float = size.x
	var h: float = size.y
	var inset: float = h * BODY_INSET
	_top_edge = PackedVector2Array()
	_bottom_edge = PackedVector2Array()
	for i: int in EDGE_STEPS + 1:
		var x: float = w * float(i) / float(EDGE_STEPS)
		var wobble: float = sin(float(i) * 0.7 + rng.randf() * 0.4) * 2.0
		_top_edge.append(Vector2(x, inset + wobble + rng.randf_range(-4.0, 4.0)))
		_bottom_edge.append(Vector2(x, h - inset + wobble * 0.6 + rng.randf_range(-4.0, 4.0)))
	# The two ends are ragged: bristles of different lengths.
	var right_end: PackedVector2Array = _ragged_end(rng, w, inset, h - inset, -1.0)
	var left_end: PackedVector2Array = _ragged_end(rng, 0.0, inset, h - inset, 1.0)
	var outline: PackedVector2Array = PackedVector2Array()
	outline.append_array(_top_edge)
	outline.append_array(right_end)
	var bottom_reversed: PackedVector2Array = _bottom_edge.duplicate()
	bottom_reversed.reverse()
	outline.append_array(bottom_reversed)
	left_end.reverse()
	outline.append_array(left_end)
	_body = outline
	_body_triangles = Geometry2D.triangulate_polygon(_body)
	if _body_triangles.is_empty():
		# A stroke that crossed itself: fall back to a plain bar rather than draw nothing.
		_body = PackedVector2Array([Vector2(0.0, inset), Vector2(w, inset), Vector2(w, h - inset), Vector2(0.0, h - inset)])
		_body_triangles = Geometry2D.triangulate_polygon(_body)
	var centre: Vector2 = size * 0.5
	_bleed = PackedVector2Array()
	for point: Vector2 in _body:
		_bleed.append(centre + (point - centre) * Vector2(1.012, 1.07) + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-1.0, 3.0)))
	_bleed_triangles = Geometry2D.triangulate_polygon(_bleed)
	_streaks.clear()
	for i: int in 5:
		var y: float = rng.randf_range(inset + 10.0, h - inset - 10.0)
		var x0: float = rng.randf_range(w * 0.03, w * 0.35)
		var x1: float = rng.randf_range(w * 0.55, w * 0.97)
		var streak: PackedVector2Array = PackedVector2Array()
		for k: int in 7:
			var t: float = float(k) / 6.0
			streak.append(Vector2(lerpf(x0, x1, t), y + sin(t * 3.1 + float(i)) * 1.6))
		_streaks.append(streak)


## One short end of the stroke as jagged bristle points from `y0` to `y1` at x = `x`; `toward` is the direction the
## body lies in (+1 for the left end, -1 for the right end).
static func _ragged_end(rng: RandomNumberGenerator, x: float, y0: float, y1: float, toward: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var count: int = 7
	for i: int in count:
		var t: float = float(i) / float(count - 1)
		var reach: float = rng.randf_range(-20.0, 6.0) if i % 2 == 0 else rng.randf_range(8.0, 30.0)
		points.append(Vector2(x + toward * reach, lerpf(y0, y1, t)))
	return points


func _draw() -> void:
	if _body.is_empty():
		return
	var lit: float = ease(_sweep, -2.0)
	var pressed_dim: float = 0.0 if not is_pressed() else 0.25
	_batch.clear()
	_batch.fill_triangulated(_bleed, _bleed_triangles, Color(InkPalette.INK, 0.34 + 0.1 * lit))
	var body_color: Color = Color(InkPalette.INK, 0.94).lerp(Color(InkPalette.CRIMSON.darkened(0.55), 0.96), lit * 0.5 + pressed_dim)
	_batch.fill_triangulated(_body, _body_triangles, body_color)
	for streak: PackedVector2Array in _streaks:
		_batch.stroke(streak, 3.2, 0.8, Color(InkPalette.GOLD, 0.1 + 0.08 * lit))
	var edge: Color = Color(InkPalette.GOLD, 0.45 + 0.4 * lit)
	_batch.stroke(_top_edge, 1.6, 1.6, edge)
	_batch.stroke(_bottom_edge, 1.6, 1.6, edge)
	_batch.draw(self)
	if _sweep > 0.0:
		_draw_underline()
	_draw_label()
	if not sub_caption.is_empty():
		var font: Font = get_theme_default_font()
		var left: float = float(get_theme_stylebox(&"normal").content_margin_left)
		draw_string(font, Vector2(left, size.y - size.y * BODY_INSET - 15.0), sub_caption, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - left - 24.0, SUB_CAPTION_SIZE, Color(InkPalette.PARCHMENT_DIM, 0.95))


## The gold serif label, on top of the stroke (the theme makes the button's own text invisible). Gold at rest, brighter
## when hovered or focused, paper white while pressed.
func _draw_label() -> void:
	var font: Font = get_theme_font(&"font")
	var font_size: int = get_theme_font_size(&"font_size")
	var margins: StyleBox = get_theme_stylebox(&"normal")
	var left: float = margins.content_margin_left
	var area_height: float = size.y - margins.content_margin_top - margins.content_margin_bottom
	var baseline: float = margins.content_margin_top + (area_height - font.get_height(font_size)) * 0.5 + font.get_ascent(font_size)
	var color: Color = InkPalette.GOLD.lerp(InkPalette.GOLD_BRIGHT, ease(_sweep, -2.0))
	if is_pressed():
		color = InkPalette.PAPER
	var width: float = size.x - left - margins.content_margin_right
	draw_string_outline(font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 8, Color(InkPalette.INK, 0.95))
	draw_string(font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)


## The crimson brush underline, dragged in from the left as `_sweep` rises: it thins out toward the tip.
func _draw_underline() -> void:
	# Under the label; with a small line below the label it goes under that line instead, at the foot of the stroke.
	var y: float = size.y * 0.7 if sub_caption.is_empty() else size.y * (1.0 - BODY_INSET) - 9.0
	var from_x: float = size.x * 0.06
	var length: float = size.x * 0.88 * ease(_sweep, -2.0)
	if length < 4.0:
		return
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var t: float = float(i) / 8.0
		points.append(Vector2(from_x + length * t, y + sin(t * 4.2 + 0.6) * 2.4))
	var brush: InkBatch = InkBatch.new()
	brush.stroke(points, 11.0, 2.0, Color(InkPalette.SAMURAI_RED, 0.97))
	brush.stroke(points, 3.5, 1.0, Color(InkPalette.PAPER, 0.22))
	brush.draw(self)
