class_name DamageNumber
extends Node2D
## Floating damage text: pops in, drifts up and fades out, then frees itself.
## Pauses with the battle and slows down during hit-stop like everything else in the world.

const LIFETIME: float = 0.75
const RISE: float = 70.0
const FONT_SIZE: int = 34
const POP_TIME: float = 0.12

var text: String = ""
var color: Color = Color.WHITE
var size_factor: float = 1.0

var _age: float = 0.0
var _drift_x: float = 0.0


func setup(label: String, label_color: Color, scale_factor: float = 1.0) -> void:
	text = label
	color = label_color
	size_factor = scale_factor
	_drift_x = randf_range(-20.0, 20.0)


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
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, FONT_SIZE, 8, Color(InkPalette.INK, 0.9))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, FONT_SIZE, color)
