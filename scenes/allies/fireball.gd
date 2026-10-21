class_name Fireball
extends Node2D
## The Onmyoji's attack: an ink-fire ball launched from his staff that flies at the enemy it was aimed at and
## explodes where it lands, burning every enemy within the blast radius once (through the normal hitbox
## validation, so allies are never hurt). Flies on until it hits something or runs out of range.

const SPEED: float = 760.0
const MAX_LIFETIME: float = 3.0
const TRAIL_POINTS: int = 14
## Close enough to an enemy's body (beyond its half width) to hit it.
const HIT_MARGIN: float = 16.0

var _source: Node
var _damage: float = 0.0
var _knockback: float = 0.0
var _radius: float = 110.0
var _target: Enemy
var _aim: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _trail: PackedVector2Array = PackedVector2Array()
var _exploded: bool = false
var _phase: float = 0.0
var _smoother: MotionSmoother


## Call before adding to the tree. `target` may be null: the ball then flies to `aim_point`.
func setup(source: Node, damage: float, knockback: float, blast_radius: float, target: Enemy, aim_point: Vector2) -> void:
	_source = source
	_damage = damage
	_knockback = knockback
	_radius = blast_radius
	_target = target
	_aim = aim_point


func _ready() -> void:
	z_index = 4
	_phase = randf() * TAU
	_trail.append(global_position)
	_smoother = MotionSmoother.attach(self, [], true)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_age += delta
	if is_instance_valid(_target) and not _target.is_dead():
		_aim = _target.global_position + Vector2(0.0, -50.0)
	var to_aim: Vector2 = _aim - global_position
	var step: float = SPEED * delta
	if to_aim.length() <= step:
		global_position = _aim
		_explode(_aim.x)
		return
	global_position += to_aim.normalized() * step
	_record_trail()
	var hit: Enemy = _enemy_in_the_way()
	if hit != null:
		_explode(hit.global_position.x)
	elif _age >= MAX_LIFETIME:
		queue_free()
	queue_redraw()


## The enemy body the ball is touching, if any.
func _enemy_in_the_way() -> Enemy:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_inside_tree() or enemy.is_dead():
			continue
		var below_head: bool = global_position.y > enemy.global_position.y - 230.0 and global_position.y < enemy.global_position.y + 30.0
		if below_head and absf(enemy.global_position.x - global_position.x) <= enemy.get_half_width() + HIT_MARGIN:
			return enemy
	return null


## The small explosion: every enemy within the blast radius of `center_x` is hurt once.
func _explode(center_x: float) -> void:
	if _exploded:
		return
	_exploded = true
	var blast: HitboxComponent = HitboxComponent.new()
	blast.name = "BlastHitbox"
	blast.faction = Faction.Type.DEFENDERS
	if is_instance_valid(_source):
		blast.source = _source
	add_child(blast)
	blast.global_position = Vector2(center_x, global_position.y)
	blast.activate(_damage, _knockback, -1.0, false)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_inside_tree() or enemy.is_dead():
			continue
		if absf(enemy.global_position.x - center_x) <= _radius + enemy.get_half_width():
			blast.try_hit(enemy.get_hurtbox())
	blast.deactivate()
	AudioManager.play(&"explosion")
	var burst: FireBurst = FireBurst.new()
	burst.setup(_radius)
	get_parent().add_child(burst)
	burst.global_position = global_position
	queue_free()


func has_exploded() -> bool:
	return _exploded


func _record_trail() -> void:
	_trail.append(global_position)
	while _trail.size() > TRAIL_POINTS:
		_trail.remove_at(0)


func _draw() -> void:
	if _smoother != null:
		draw_set_transform(_smoother.get_draw_offset())
	var direction: Vector2 = Vector2.RIGHT
	if _trail.size() >= 2:
		var back: Vector2 = _trail[0] - global_position
		if back.length() > 1.0:
			direction = -back.normalized()
	var flicker: float = 0.5 + 0.5 * sin(_age * 38.0 + _phase)
	# The trail: ink smoke over flame, thinning behind the ball (drawn in this node's space).
	var smoke: PackedVector2Array = PackedVector2Array()
	var flame: PackedVector2Array = PackedVector2Array()
	for i: int in _trail.size():
		var along: float = float(i) / float(maxi(_trail.size() - 1, 1))
		var wobble: Vector2 = direction.orthogonal() * sin(_age * 22.0 + float(i) * 0.9 + _phase) * 5.0 * (1.0 - along)
		smoke.append(to_local(_trail[i]) + wobble)
		flame.append(to_local(_trail[i]) + wobble * 0.5)
	if smoke.size() >= 2:
		InkBrush.stroke(self, smoke, 1.0, 16.0, Color(InkPalette.INK, 0.65))
		InkBrush.stroke(self, flame, 1.0, 20.0, Color(InkPalette.HATAMOTO_ORANGE, 0.55))
	# The ball: a dark ink rim, flame, a hot core and tongues licking back.
	draw_circle(Vector2.ZERO, 19.0 + 2.0 * flicker, Color(InkPalette.INK, 0.8))
	draw_circle(Vector2.ZERO, 16.0 + 2.0 * flicker, InkPalette.ONI_EMBER)
	draw_circle(Vector2.ZERO, 12.0, InkPalette.HATAMOTO_ORANGE)
	draw_circle(Vector2.ZERO, 6.5 + flicker, InkPalette.PAPER)
	for k: int in 3:
		var angle: float = direction.angle() + PI + (float(k) - 1.0) * 0.55 + sin(_age * 30.0 + float(k) * 2.0) * 0.18
		var tip: Vector2 = Vector2.from_angle(angle) * (30.0 + 8.0 * flicker + 4.0 * float(k % 2))
		var base: Vector2 = Vector2.from_angle(angle + PI * 0.5) * 9.0
		draw_colored_polygon(PackedVector2Array([base, tip, -base]), Color(InkPalette.HATAMOTO_ORANGE, 0.9))
		draw_colored_polygon(PackedVector2Array([base * 0.5, tip * 0.75, -base * 0.5]), Color(InkPalette.PAPER, 0.7))
