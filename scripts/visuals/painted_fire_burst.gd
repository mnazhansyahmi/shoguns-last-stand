class_name PaintedFireBurst
extends Node2D
## Bounded visual-only fire burst/trail. All damage stays with existing hitboxes.
var span: Vector2 = Vector2(300, 220)
var duration: float = 0.8
var trail: bool = false
var _age: float = 0.0
var _flame: PaintedFlame


func _ready() -> void:
	z_index = 4
	_flame = PaintedFlame.new()
	_flame.cell = 3 if trail else 1
	_flame.flame_size = span
	add_child(_flame)


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	var p: float = _age / duration
	modulate.a = 1.0 - smoothstep(0.2, 1.0, p)
	scale = Vector2(signf(scale.x), 1.0) * (0.65 + 0.35 * smoothstep(0.0, 0.2, p))
