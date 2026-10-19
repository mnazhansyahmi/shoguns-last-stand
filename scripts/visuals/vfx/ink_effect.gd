class_name InkEffect
extends Node2D
## Base for short code-drawn effects: ages over `lifetime`, redraws every frame, then frees
## itself. Effects are visual only: they never deal damage or block input. They pause with the
## battle and slow down during hit-stop like the rest of the world.

var lifetime: float = 0.3
var age: float = 0.0


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	_advance(delta)
	queue_redraw()


## 0 at the start, 1 at the end of the effect.
func progress() -> float:
	return clampf(age / maxf(lifetime, 0.001), 0.0, 1.0)


## Per-frame simulation for subclasses (particles).
func _advance(_delta: float) -> void:
	pass


## A random irregular blot (ink splat) as polygon points around `center`.
static func blot_points(rng: RandomNumberGenerator, center: Vector2, radius: float, squash: float, spikes: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in spikes * 2:
		var angle: float = TAU * float(i) / float(spikes * 2)
		var reach: float = radius * (rng.randf_range(0.95, 1.35) if i % 2 == 0 else rng.randf_range(0.55, 0.8))
		points.append(center + Vector2(cos(angle) * reach, sin(angle) * reach * squash))
	return points
