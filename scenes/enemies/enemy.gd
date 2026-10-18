class_name Enemy
extends CharacterBody2D
## Generic enemy driven by an EnemyData resource.
## FSM: SPAWN -> ADVANCE -> ACQUIRE_TARGET -> ATTACK -> RECOVER, with HURT and DEAD.

signal defeated(enemy: Enemy)

enum State { SPAWN, ADVANCE, ACQUIRE_TARGET, ATTACK, RECOVER, HURT, DEAD }
enum AttackPhase { WINDUP, ACTIVE }

const TARGET_GROUPS: Dictionary = {
	EnemyData.TargetKind.PLAYER: &"player",
	EnemyData.TargetKind.ALLY: &"allies",
	EnemyData.TargetKind.GATE: &"gate",
}
const SCAN_INTERVAL: float = 0.2
const FRICTION: float = 1800.0
const CORPSE_TIME: float = 0.8
const LOSE_TARGET_FACTOR: float = 1.5
const INTERRUPT_ATTACK_DELAY: float = 0.3

@export var data: EnemyData

@onready var _visual: PlaceholderVisual = $Visual
@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var _health_bar: WorldHealthBar = $HealthBar

var facing: int = -1

var _state: State = State.SPAWN
var _state_time: float = 0.0
var _attack: AttackProfile
var _attack_phase: AttackPhase = AttackPhase.WINDUP
var _attack_cooldown_left: float = 0.0
var _target: Node2D
var _scan_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)


## Call before adding to the tree.
func setup(enemy_data: EnemyData) -> void:
	data = enemy_data


func _ready() -> void:
	add_to_group("enemies")
	if data == null:
		push_error("Enemy '%s': no EnemyData assigned, using defaults." % name)
		data = EnemyData.new()
	_attack = data.attack
	if _attack == null:
		push_error("Enemy '%s': EnemyData '%s' has no attack, using defaults." % [name, data.display_name])
		_attack = AttackProfile.new()
	_apply_data()
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_health.max_health = data.max_health
	_health.reset()
	_set_facing(-1)
	_change_state(State.SPAWN)
	_visual.play_state(&"spawn")


func _physics_process(delta: float) -> void:
	_state_time += delta
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	if not is_on_floor():
		velocity.y += _gravity * delta
	match _state:
		State.SPAWN:
			velocity.x = 0.0
			if _state_time >= data.spawn_duration:
				_change_state(State.ADVANCE)
		State.ADVANCE:
			_process_advance(delta)
		State.ACQUIRE_TARGET:
			_process_acquire_target(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVER:
			_brake(delta)
			if _state_time >= _attack.recovery:
				_attack_cooldown_left = _attack.cooldown
				_resume()
		State.HURT:
			_brake(delta)
			if _state_time >= data.hurt_duration:
				_resume()
		State.DEAD:
			_brake(delta)
	move_and_slide()


# --- Public API -------------------------------------------------------------

func is_dead() -> bool:
	return _state == State.DEAD


func get_state() -> State:
	return _state


func get_state_name() -> String:
	return State.keys()[_state]


## Current target, or null if there is none or it has been freed.
func get_target() -> Node2D:
	return _target if _has_valid_target() else null


func get_half_width() -> float:
	return data.body_size.x * 0.5 if data != null else 20.0


## Picks the nearest valid target of the highest-priority kind within aggro range.
func select_target() -> Node2D:
	for kind: EnemyData.TargetKind in data.target_priorities:
		var group: StringName = TARGET_GROUPS.get(kind, &"")
		if group == &"":
			continue
		var best: Node2D = null
		var best_distance: float = data.aggro_range
		for node: Node in get_tree().get_nodes_in_group(group):
			var candidate: Node2D = node as Node2D
			if not _is_valid_candidate(candidate):
				continue
			var distance: float = absf(_target_x(candidate) - global_position.x)
			if distance <= best_distance:
				best = candidate
				best_distance = distance
		if best != null:
			return best
	return null


# --- States -----------------------------------------------------------------

func _process_advance(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		var found: Node2D = select_target()
		if found != null:
			_target = found
			_change_state(State.ACQUIRE_TARGET)
			return
	_walk(-1, delta)


func _process_acquire_target(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		var preferred: Node2D = select_target()
		if preferred != null:
			_target = preferred
	if not _has_valid_target():
		_change_state(State.ADVANCE)
		return
	var dx: float = _target_x(_target) - global_position.x
	if absf(dx) > data.aggro_range * LOSE_TARGET_FACTOR:
		_target = null
		_change_state(State.ADVANCE)
		return
	var direction: int = -1 if dx < 0.0 else 1
	if absf(dx) <= data.attack_range:
		_set_facing(direction)
		_brake(delta)
		_visual.play_state(&"idle")
		if _attack_cooldown_left <= 0.0:
			_start_attack()
	else:
		_walk(direction, delta)


func _start_attack() -> void:
	_attack_phase = AttackPhase.WINDUP
	_change_state(State.ATTACK)
	_visual.play_state(&"windup")


func _process_attack(delta: float) -> void:
	_brake(delta)
	match _attack_phase:
		AttackPhase.WINDUP:
			if _state_time >= _attack.windup:
				_attack_phase = AttackPhase.ACTIVE
				_hitbox_shape.position = Vector2(_attack.hitbox_offset.x * facing, _attack.hitbox_offset.y)
				_hitbox.knockback_direction_x = facing
				_hitbox.activate(data.attack_damage * _attack.damage_multiplier, _attack.knockback, _attack.active_time)
				_visual.play_state(&"strike")
		AttackPhase.ACTIVE:
			if _state_time >= _attack.windup + _attack.active_time:
				_change_state(State.RECOVER)


func _resume() -> void:
	if _has_valid_target():
		_change_state(State.ACQUIRE_TARGET)
	else:
		_change_state(State.ADVANCE)
	_visual.play_state(&"idle")


# --- Movement ---------------------------------------------------------------

func _walk(direction: int, delta: float) -> void:
	_set_facing(direction)
	var desired: float = 0.0 if _is_blocked_by_other_enemy(direction) else direction * data.move_speed
	velocity.x = move_toward(velocity.x, desired, data.move_speed * 8.0 * delta)
	_visual.play_state(&"run" if absf(velocity.x) > 1.0 else &"idle")


func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


## Collision avoidance: queue behind another living enemy instead of stacking on it.
func _is_blocked_by_other_enemy(direction: int) -> bool:
	var my_half: float = get_half_width()
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self:
			continue
		var other: Enemy = node as Enemy
		if other == null or other.is_dead():
			continue
		var dx: float = other.global_position.x - global_position.x
		var spacing: float = (my_half + other.get_half_width()) * 0.85
		if absf(dx) >= spacing:
			continue
		if absf(dx) < 1.0:
			# Exactly overlapping: deterministic tie-break so only one waits.
			if get_instance_id() > other.get_instance_id():
				return true
			continue
		if (dx < 0.0) == (direction < 0):
			return true
	return false


# --- Targets ----------------------------------------------------------------

## True if the stored target still exists and is targetable; clears it otherwise.
## Checks the member directly: passing a freed object to a typed parameter is a script error.
func _has_valid_target() -> bool:
	if not is_instance_valid(_target) or not _is_valid_candidate(_target):
		_target = null
		return false
	return true


## For live candidates from the scene tree, or a target already checked with is_instance_valid.
func _is_valid_candidate(target: Node2D) -> bool:
	if target == null or not target.is_inside_tree():
		return false
	if target.has_method("is_targetable"):
		return target.call("is_targetable")
	return true


## The gate exposes its front edge; other targets use their origin.
func _target_x(target: Node2D) -> float:
	if target.has_method("get_front_x"):
		return target.call("get_front_x")
	return target.global_position.x


# --- Signal handlers --------------------------------------------------------

func _on_hit_received(hit: HitData) -> void:
	_visual.flash_hit()
	velocity.x = hit.knockback.x * (1.0 - data.knockback_resistance)
	if _health.is_dead() or not data.interruptible:
		return
	_hitbox.deactivate()
	_attack_cooldown_left = maxf(_attack_cooldown_left, INTERRUPT_ATTACK_DELAY)
	_change_state(State.HURT)
	_visual.play_state(&"hurt")


func _on_died() -> void:
	_hitbox.deactivate()
	_hurtbox.set_enabled(false)
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	_health_bar.visible = false
	_change_state(State.DEAD)
	_visual.play_state(&"dead")
	defeated.emit(self)
	var tween: Tween = create_tween()
	tween.tween_interval(CORPSE_TIME)
	tween.tween_callback(queue_free)


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.set_values(current, maximum)


func _change_state(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0


func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	_visual.set_facing(direction)


# --- Placeholder visuals from data -----------------------------------------

func _apply_data() -> void:
	UnitRig.build_collision(_body_shape, _hurtbox_shape, _hitbox_shape, data.body_size, _attack.hitbox_size)
	var head_top: float = UnitRig.build_visual($Visual/Rig, data.body_size, data.body_color,
			data.head_color, data.weapon_length, data.headgear)
	_health_bar.position = Vector2(0.0, head_top - 22.0)
	_health_bar.bar_size = Vector2(clampf(data.body_size.x * 1.4, 56.0, 140.0), 8.0)
