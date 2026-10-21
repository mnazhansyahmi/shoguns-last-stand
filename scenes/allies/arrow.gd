class_name Arrow
extends Node2D
## Single-target projectile: hits the first hostile hurtbox, then is removed.

const MAX_LIFETIME: float = 3.0

@onready var _hitbox: HitboxComponent = $Hitbox

var spawn_position: Vector2 = Vector2.ZERO
var _direction: float = 1.0
var _damage: float = 12.0
var _speed: float = 900.0
var _range: float = 700.0
var _knockback: float = 80.0
var _source: Node
var _travelled: float = 0.0
var _age: float = 0.0


## Call before adding to the tree.
func setup(direction: float, damage: float, speed: float, max_range: float, knockback: float, source: Node, start_position: Vector2) -> void:
	_direction = 1.0 if direction >= 0.0 else -1.0
	_damage = damage
	_speed = speed
	_range = max_range
	_knockback = knockback
	_source = source
	spawn_position = start_position


func _ready() -> void:
	global_position = spawn_position
	scale.x = _direction
	MotionSmoother.attach(self, [$Shaft as Node2D, $Head as Node2D, $Fletching as Node2D] as Array[Node2D])
	if is_instance_valid(_source):
		_hitbox.source = _source
	_hitbox.knockback_direction_x = _direction
	_hitbox.hit_landed.connect(_on_hit_landed)
	_hitbox.activate(_damage, _knockback)


func _physics_process(delta: float) -> void:
	var step: float = _speed * delta
	position.x += _direction * step
	_travelled += step
	_age += delta
	if _travelled >= _range or _age >= MAX_LIFETIME:
		_expire()


func _on_hit_landed(_hurtbox: HurtboxComponent) -> void:
	_expire()


func _expire() -> void:
	_hitbox.deactivate()
	queue_free()
