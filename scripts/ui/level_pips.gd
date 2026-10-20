class_name LevelPips
extends Control
## A row of pips for an upgrade's level: one per level, filled gold for the levels owned.

const PIP: float = 26.0
const GAP: float = 8.0

var level: int = 0
var max_level: int = 5


func set_levels(current: int, maximum: int) -> void:
	level = clampi(current, 0, maximum)
	max_level = maxi(maximum, 1)
	custom_minimum_size = Vector2(float(max_level) * PIP + float(max_level - 1) * GAP, PIP)
	queue_redraw()


func _draw() -> void:
	for i: int in max_level:
		var rect: Rect2 = Rect2(Vector2(float(i) * (PIP + GAP), 0.0), Vector2(PIP, PIP))
		if i < level:
			draw_rect(rect, InkPalette.GOLD_BRIGHT)
			draw_rect(rect, Color(InkPalette.GOLD, 0.9), false, 2.0)
		else:
			draw_rect(rect, Color(InkPalette.INK, 0.6))
			draw_rect(rect, Color(InkPalette.GOLD, 0.45), false, 2.0)
