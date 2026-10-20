class_name SpiritSlash
extends Node2D
## Piercing spirit projectile. Hits each enemy once, then expires after its range.

const MAX_LIFETIME: float = 3.0

@onready var _hitbox: HitboxComponent = $Hitbox

var spawn_position: Vector2 = Vector2.ZERO
var _direction: float = 1.0
var _damage: float = 45.0
var _speed: float = 950.0
var _range: float = 1100.0
var _knockback: float = 220.0
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
	if is_instance_valid(_source):
		_hitbox.source = _source
	_hitbox.knockback_direction_x = _direction
	_hitbox.spirit = true
	_hitbox.activate(_damage, _knockback)


func _physics_process(delta: float) -> void:
	var step: float = _speed * delta
	position.x += _direction * step
	_travelled += step
	_age += delta
	modulate.a = 1.0 - clampf(_travelled / _range, 0.0, 1.0) * 0.7
	if _travelled >= _range or _age >= MAX_LIFETIME:
		_hitbox.deactivate()
		queue_free()
