class_name DamageNumber
extends Node2D
## Floating damage text: pops in, drifts up and fades out, then frees itself.
## Pauses with the battle and slows down during hit-stop like everything else in the world.

const LIFETIME: float = 0.75
const RISE: float = 70.0
const FONT_SIZE: int = 40
## Solid ink outline so numbers read on the pale mist and over dark fighters alike.
const OUTLINE_SIZE: int = 12
const POP_TIME: float = 0.12

## Rapid hits on one target within this long (seconds of the number's age) add into one number.
const MERGE_WINDOW: float = 0.4
## Vertical gap kept between numbers that would otherwise overlap.
const SPACING: float = 46.0

var text: String = ""
var color: Color = Color.WHITE
var size_factor: float = 1.0
## Summed damage when this number stands for several hits (0 for plain text numbers).
var value: float = 0.0
var heavy: bool = false
## Instance id of whoever was hit (0 = none): hits on the same target merge into this number.
var victim_id: int = 0

var _age: float = 0.0
var _drift_x: float = 0.0


func setup(label: String, label_color: Color, scale_factor: float = 1.0) -> void:
	text = label
	color = label_color
	size_factor = scale_factor
	_drift_x = randf_range(-8.0, 8.0)


## Sets this number to a damage amount (shown rounded, with "!" for a heavy hit).
func set_damage(amount: float, is_heavy: bool) -> void:
	value = amount
	heavy = heavy or is_heavy
	text = str(roundi(value)) + ("!" if heavy else "")


## Another hit on the same target: add it in, pop again and stay on screen a little longer.
func merge(amount: float, is_heavy: bool, label_color: Color, scale_factor: float) -> void:
	set_damage(value + amount, is_heavy)
	color = label_color if heavy else color
	size_factor = maxf(size_factor, scale_factor)
	_age = minf(_age, LIFETIME * 0.25)
	queue_redraw()


## True while a new hit on the same target should still join this number.
func can_merge() -> bool:
	return _age <= MERGE_WINDOW and not is_queued_for_deletion()


func _ready() -> void:
	z_index = 50
	_apply_animation()


func _process(delta: float) -> void:
	_age += delta
	position += Vector2(_drift_x, -RISE) * (delta / LIFETIME)
	_apply_animation()
	if _age >= LIFETIME:
		queue_free()


func get_age() -> float:
	return _age


func _apply_animation() -> void:
	var pop: float = 1.0 + 0.4 * maxf(0.0, 1.0 - _age / POP_TIME)
	scale = Vector2.ONE * size_factor * pop
	modulate.a = 1.0 - clampf((_age - LIFETIME * 0.5) / (LIFETIME * 0.5), 0.0, 1.0)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var origin: Vector2 = Vector2(-80.0, 0.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, FONT_SIZE, OUTLINE_SIZE, InkPalette.INK)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, FONT_SIZE, color)
