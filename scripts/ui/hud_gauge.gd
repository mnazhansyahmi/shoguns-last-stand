class_name HudGauge
extends Control
## Base of the battle HUD's drawn gauges (the Ultimate ring round the portrait medallion, the katana health blade, the
## spirit bar and the gate bar): a 0..1 `ratio` with its `value_text`, an optional key badge and a `pulsing` flag.
## Drawing is kept cheap: a gauge redraws only when its value changes (or for the moment a hit flashes it). Glows and
## warnings that pulse every frame are `Layer`s, child canvases painted once and then only faded with `modulate`, and
## the few parts that really move each frame (flowing ink) get a small layer of their own. Text is shaped once per value
## (cached `TextLine`s) and drawn with an ink outline so numbers stay readable over any sky.

const TEXT_OUTLINE: int = 6
const TEXT_CACHE_SIZE: int = 12

var ratio: float = 1.0
var value_text: String = ""
## The keyboard key of what the gauge stands for, on a small badge ("" = none).
var key_hint: String = ""
## Something the gauge stands for is ready: it glows and pulses.
var pulsing: bool = false

## Seconds of animation so far (drives pulses and flowing ink).
var _clock: float = 0.0
var _batch: InkBatch = InkBatch.new()
var _text_lines: Dictionary = {}


## A child canvas over (or, with show_behind_parent, under) the gauge, painted by `painter.call(layer)`.
class Layer extends Control:
	var painter: Callable

	func _draw() -> void:
		painter.call(self)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_processing()


func set_value(current: float, maximum: float) -> void:
	set_ratio_text(current / maxf(maximum, 0.001), "%d / %d" % [ceili(current), roundi(maximum)])


func set_ratio_text(new_ratio: float, text: String) -> void:
	var clamped: float = clampf(new_ratio, 0.0, 1.0)
	if is_equal_approx(clamped, ratio) and text == value_text:
		return
	var old: float = ratio
	ratio = clamped
	value_text = text
	_on_ratio_changed(old, clamped)
	_refresh_processing()
	queue_redraw()


func set_pulsing(enabled: bool) -> void:
	if enabled == pulsing:
		return
	pulsing = enabled
	_on_pulsing_changed()
	_refresh_processing()
	queue_redraw()


func set_key_hint(text: String) -> void:
	if text == key_hint:
		return
	key_hint = text
	queue_redraw()


## Advances the gauge's own animation by `delta` (what `_process` does each frame; tests call it directly).
func advance(delta: float) -> void:
	_clock += delta
	_step(delta)
	_refresh_processing()


func _process(delta: float) -> void:
	advance(delta)


## Override: true while the gauge has something moving on it.
func _is_animating() -> bool:
	return pulsing


## Override: the value went from `old` to `new` (start a ghost trail, a flash...).
func _on_ratio_changed(_old: float, _new: float) -> void:
	pass


## Override: `pulsing` changed.
func _on_pulsing_changed() -> void:
	pass


## Override: per-frame animation (fade layers, redraw what moves).
func _step(_delta: float) -> void:
	pass


func _refresh_processing() -> void:
	set_process(_is_animating())


## 0..1, a slow breathing pulse for "ready" and warning glows.
func _pulse(hz: float) -> float:
	return 0.5 + 0.5 * sin(_clock * TAU * hz)


## Adds a Layer the size of the gauge, painted by `painter` (a func taking the layer's CanvasItem).
func add_layer(layer_name: String, painter: Callable, behind: bool = false) -> Layer:
	var layer: Layer = Layer.new()
	layer.name = layer_name
	layer.painter = painter
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.show_behind_parent = behind
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	return layer


## A plate with brush-ink edges: a rectangle whose long edges waver a little and whose ends are ragged bristles,
## seeded so it never changes between frames.
static func ragged_plate(rect: Rect2, seed_value: int, roughness: float = 3.0, steps: int = 14) -> PackedVector2Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var top: PackedVector2Array = PackedVector2Array()
	var bottom: PackedVector2Array = PackedVector2Array()
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var x: float = lerpf(rect.position.x, rect.end.x, t)
		top.append(Vector2(x, rect.position.y + rng.randf_range(-roughness, roughness * 0.5)))
		bottom.append(Vector2(x, rect.end.y + rng.randf_range(-roughness * 0.5, roughness)))
	var outline: PackedVector2Array = top
	# Ragged right end: bristles of different lengths.
	for i: int in range(1, 5):
		var y: float = lerpf(rect.position.y, rect.end.y, float(i) / 5.0)
		outline.append(Vector2(rect.end.x + rng.randf_range(-roughness * 2.0, roughness * 3.0), y))
	bottom.reverse()
	outline.append_array(bottom)
	for i: int in range(4, 0, -1):
		var y: float = lerpf(rect.position.y, rect.end.y, float(i) / 5.0)
		outline.append(Vector2(rect.position.x - rng.randf_range(0.0, roughness * 2.0), y))
	return outline


static func rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


static func arc_points(center: Vector2, radius: float, from: float, to: float, steps: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in steps + 1:
		points.append(center + Vector2.from_angle(lerpf(from, to, float(i) / float(steps))) * radius)
	return points


static func shifted(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var moved: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + offset)
	return moved


## A line of even `width` round a closed shape, into `batch` (it laps past the start so the seam closes).
static func outline(batch: InkBatch, points: PackedVector2Array, width: float, color: Color) -> void:
	if points.size() < 2:
		return
	var loop: PackedVector2Array = points.duplicate()
	loop.append(points[0])
	loop.append(points[1])
	batch.stroke(loop, width, width, color)


## The shaped text (shaping is the costly part of drawing a string), kept for the last few values.
func _text_line(text: String, font_size: int) -> TextLine:
	var key: String = "%d|%s" % [font_size, text]
	var line: TextLine = _text_lines.get(key)
	if line == null:
		if _text_lines.size() >= TEXT_CACHE_SIZE:
			_text_lines.clear()
		line = TextLine.new()
		line.add_string(text, get_theme_default_font(), font_size)
		_text_lines[key] = line
	return line


## Draws `text` with an ink outline, its baseline at `at.y`. `align_right`: `at.x` is where the text ends.
func draw_outlined(at: Vector2, text: String, font_size: int, color: Color, align_right: bool = false) -> void:
	if text.is_empty():
		return
	var line: TextLine = _text_line(text, font_size)
	var x: float = at.x - line.get_line_width() if align_right else at.x
	var top_left: Vector2 = Vector2(x, at.y - line.get_line_ascent())
	line.draw_outline(get_canvas_item(), top_left, TEXT_OUTLINE, Color(InkPalette.INK, 0.92))
	line.draw(get_canvas_item(), top_left, color)


func text_width(text: String, font_size: int) -> float:
	return _text_line(text, font_size).get_line_width()


## The small square key badge ("I") centred on `center`: its plate goes into `_batch`, so flush the batch before calling
## draw_key_letter() for the letter on top.
func batch_key_badge(center: Vector2, side: float) -> void:
	if key_hint.is_empty():
		return
	var rect: Rect2 = Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	_batch.fill_convex(rect_points(rect), Color(InkPalette.INK, 0.95))
	outline(_batch, rect_points(rect), 2.0, InkPalette.GOLD)


func draw_key_letter(center: Vector2, side: float) -> void:
	if key_hint.is_empty():
		return
	var line: TextLine = _text_line(key_hint, roundi(side * 0.72))
	var top_left: Vector2 = center - Vector2(line.get_line_width() * 0.5, (line.get_line_ascent() + line.get_line_descent()) * 0.5)
	line.draw(get_canvas_item(), top_left, InkPalette.PARCHMENT)
