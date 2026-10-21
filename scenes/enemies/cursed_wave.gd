class_name CursedWave
extends Node2D
## The Fallen Daimyo's cursed wave: a crescent of dark light racing along the ground. It passes through
## everything on its way (the player, allies and the gate are each hit once) and fades at the end of its
## range. Damage only flows through a HitboxComponent, like every other attack.

const MAX_LIFETIME: float = 4.0
const FADE_DISTANCE: float = 160.0
const BODY: Vector2 = Vector2(54.0, 130.0)

## A wall of flame (the Burning General) instead of the cursed crescent: the same wave, fire colours. Set before adding.
var fire: bool = false
var _direction: float = -1.0
var _damage: float = 30.0
var _speed: float = 460.0
var _range: float = 1100.0
var _knockback: float = 300.0
var _source: Node
var _travelled: float = 0.0
var _age: float = 0.0
var _hitbox: HitboxComponent
var _smoother: MotionSmoother


## Call before adding to the tree. `start_position` is on the ground.
func setup(direction: float, damage: float, speed: float, max_range: float, knockback: float, source: Node, start_position: Vector2) -> void:
	_direction = 1.0 if direction >= 0.0 else -1.0
	_damage = damage
	_speed = speed
	_range = max_range
	_knockback = knockback
	_source = source
	position = start_position


func _ready() -> void:
	z_index = 2
	scale.x = _direction
	_smoother = MotionSmoother.attach(self, [], true)
	_hitbox = HitboxComponent.new()
	_hitbox.name = "Hitbox"
	_hitbox.faction = Faction.Type.ENEMIES
	add_child(_hitbox)
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = BODY
	shape_node.shape = rect
	shape_node.position = Vector2(0.0, -BODY.y * 0.5)
	_hitbox.add_child(shape_node)
	if is_instance_valid(_source):
		_hitbox.source = _source
	_hitbox.knockback_direction_x = _direction
	_hitbox.activate(_damage, _knockback, -1.0, false)


func _physics_process(delta: float) -> void:
	var step: float = _speed * delta
	position.x += _direction * step
	_travelled += step
	_age += delta
	queue_redraw()
	if _travelled >= _range or _age >= MAX_LIFETIME:
		_hitbox.deactivate()
		queue_free()


## 0..1: how solid it is (it fades over the last stretch of its range).
func get_strength() -> float:
	return clampf((_range - _travelled) / FADE_DISTANCE, 0.0, 1.0)


func _draw() -> void:
	if _smoother != null:
		draw_set_transform(_smoother.get_draw_offset())
	var strength: float = get_strength()
	var pulse: float = 0.5 + 0.5 * sin(_age * 22.0)
	var batch: InkBatch = InkBatch.new()
	# A crescent standing on the ground, its points leaning back: dark body, cursed edge.
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var t: float = float(i) / 12.0
		var y: float = -BODY.y * t
		var bulge: float = sin(PI * t)
		outer.append(Vector2(BODY.x * 0.55 * bulge + 4.0, y))
		inner.append(Vector2(BODY.x * 0.05 * bulge - 8.0 * (1.0 - bulge), y))
	var ring: PackedVector2Array = outer.duplicate()
	var reversed: PackedVector2Array = inner.duplicate()
	reversed.reverse()
	ring.append_array(reversed)
	var body: Color = InkPalette.ONI_EMBER if fire else InkPalette.INK
	var accent: Color = InkPalette.HATAMOTO_ORANGE if fire else InkPalette.DAIMYO_CURSE
	batch.fill(ring, Color(body, 0.9 * strength))
	var edge: PackedVector2Array = outer.duplicate()
	batch.stroke(edge, 7.0, 3.0, Color(accent, (0.7 + 0.25 * pulse) * strength))
	batch.stroke(edge, 2.6, 1.2, Color(InkPalette.PAPER, 0.8 * strength))
	# Trailing wisps along the ground.
	for k: int in 3:
		var from: Vector2 = Vector2(-10.0 - 26.0 * float(k), -6.0 - 22.0 * float(k))
		batch.stroke(PackedVector2Array([from, from + Vector2(-60.0, 8.0)]), 5.0, 1.0, Color(accent, (0.3 - 0.07 * float(k)) * strength))
	batch.draw(self)
