class_name UltimateCinematic
extends Control
## Screen-space slash marks. The skill owns timing, movement and delayed damage.
var age: float = 0.0
var marks: PackedVector2Array = PackedVector2Array()
var blood_enabled: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_time(seconds: float) -> void:
	age = seconds
	queue_redraw()


func _draw() -> void:
	var view: Vector2 = get_viewport_rect().size
	var dark: float = smoothstep(0, 0.1, age) * (1.0 - smoothstep(0.55, 0.95, age))
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.035, 0.012, 0.025, dark * 0.55))
	var fade: float = 1.0 - smoothstep(0.6, 0.95, age)
	for i: int in marks.size():
		var reveal: float = smoothstep(0.06 + i * 0.048, 0.14 + i * 0.048, age)
		if reveal <= 0: continue
		var angle: float = -0.28 if i % 2 == 0 else 0.33
		var extent: Vector2 = Vector2.from_angle(angle) * (180.0 + (i % 3) * 40)
		var start: Vector2 = marks[i] - extent
		var end: Vector2 = start.lerp(marks[i] + extent, reveal)
		_stroke(start, end, 13.0, Color(0.9, 0.055, 0.03, 0.13 * fade))
		_stroke(start, end, 5.5, Color(1.0, 0.21, 0.08, 0.45 * fade))
		_stroke(start, end, 1.9, Color(1.0, 0.77, 0.48, 0.95 * fade))
		_stroke(start.lerp(end, 0.08), end, 0.7, Color(1.0, 0.96, 0.85, fade))
		if age >= UltimateSkill.IMPACT_TIME and blood_enabled:
			var blast: float = clampf((age - UltimateSkill.IMPACT_TIME) / 0.25, 0.0, 1.0)
			for drop: int in 5:
				var offset: Vector2 = Vector2.from_angle(drop * 1.7 + i) * (18.0 + blast * 65.0)
				draw_circle(marks[i] + offset, (3.0 + drop % 3) * (1.0 - blast), Color(0.16, 0.008, 0.013, 0.8 * (1.0 - blast)))
	var flash: float = 1.0 - smoothstep(UltimateSkill.IMPACT_TIME, UltimateSkill.IMPACT_TIME + 0.08, age)
	if age >= UltimateSkill.IMPACT_TIME:
		draw_rect(Rect2(Vector2.ZERO, view), Color(1.0, 0.87, 0.65, flash * 0.6))


func _stroke(start: Vector2, end: Vector2, width: float, color: Color) -> void:
	var normal: Vector2 = (end - start).normalized().orthogonal() * width
	draw_colored_polygon(PackedVector2Array([start, start.lerp(end, 0.25) + normal,
		start.lerp(end, 0.7) + normal * 0.65, end, start.lerp(end, 0.7) - normal * 0.65,
		start.lerp(end, 0.25) - normal]), color)
