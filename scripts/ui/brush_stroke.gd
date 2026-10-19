class_name BrushStroke
extends Control
## A single horizontal brush stroke (thin, swelling, thin) across the control, used as an accent
## line under titles. Drawn by code.

@export var color: Color = InkPalette.SAMURAI_RED
## Thickest point of the stroke, as a fraction of the control's height.
@export_range(0.1, 1.0) var weight: float = 0.8


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var mid_y: float = size.y * 0.5
	var thick: float = size.y * weight
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var t: float = float(i) / 8.0
		left.append(Vector2(size.x * 0.42 * t, mid_y + sin(t * 2.4) * size.y * 0.08))
		right.append(Vector2(size.x * (0.42 + 0.58 * t), mid_y + sin(2.4 + t * 1.6) * size.y * 0.08))
	InkBrush.stroke(self, left, thick * 0.15, thick, color)
	InkBrush.stroke(self, right, thick, thick * 0.08, color)
