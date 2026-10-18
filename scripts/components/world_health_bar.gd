class_name WorldHealthBar
extends Node2D
## Simple health bar drawn in world space, centered on this node.

@export var bar_size: Vector2 = Vector2(120.0, 12.0)
@export var fill_color: Color = Color(0.85, 0.2, 0.2)
@export var back_color: Color = Color(0.0, 0.0, 0.0, 0.6)

var _ratio: float = 1.0


func set_values(current: float, maximum: float) -> void:
	set_ratio(current / maxf(maximum, 0.001))


func set_ratio(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = -bar_size * 0.5
	draw_rect(Rect2(origin - Vector2(3.0, 3.0), bar_size + Vector2(6.0, 6.0)), back_color)
	draw_rect(Rect2(origin, Vector2(bar_size.x * _ratio, bar_size.y)), fill_color)
