class_name BossFootDust
extends InkEffect
## A bounded contact puff: six soft wisps, no emitter or persistent geometry.

func _init() -> void:
	lifetime = 0.48
	z_index = 1


func _draw() -> void:
	var p: float = progress()
	for i: int in 6:
		var side: float = float(i) - 2.5
		var center: Vector2 = Vector2(side * (3.0 + p * 17.0), -3.0 - sin(p * PI * 0.65) * (4.0 + float(i % 3) * 5.0))
		BambooOutskirtsPainter.soft(self, center, Vector2(14.0 + 22.0 * p, 7.0 + 8.0 * p), Color(0.39, 0.30, 0.23, (1.0 - p) * 0.23))
