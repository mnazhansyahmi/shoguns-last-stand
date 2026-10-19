class_name Player
extends CharacterBody2D
## Player-controlled samurai. Time-based state machine (frame-rate independent).
## Damage only flows through HitboxComponent -> HurtboxComponent validation.

signal died
signal respawned
signal health_changed(current: float, maximum: float)
signal projectile_fired(projectile: Node2D)

enum State { IDLE, RUN, ATTACK, DASH, SPIRIT_SLASH, HURT, DEAD }
enum AttackPhase { WINDUP, ACTIVE, RECOVERY }

const SPIRIT_SLASH_SCENE: PackedScene = preload("res://scenes/player/spirit_slash.tscn")
const DEFAULT_STATS_PATH: String = "res://data/player/samurai_stats.tres"
const HURT_FRICTION: float = 1800.0
const RESPAWN_INVULNERABILITY: float = 1.5

@export var stats: PlayerStats
@export var min_x: float = 120.0
@export var max_x: float = 1860.0

@onready var _visual: PlaceholderVisual = $Visual
@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var _dash_cooldown: CooldownComponent = $DashCooldown
@onready var _heavy_cooldown: CooldownComponent = $HeavyCooldown
@onready var _spirit_slash_cooldown: CooldownComponent = $SpiritSlashCooldown

var facing: int = 1

var _state: State = State.IDLE
var _state_time: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var _combo: Array[AttackProfile] = []
var _combo_index: int = 0
var _current_attack: AttackProfile
var _attack_phase: AttackPhase = AttackPhase.WINDUP
var _is_heavy: bool = false
var _attack_buffered: bool = false
var _dash_direction: int = 1
var _dash_distance_left: float = 0.0
var _slash_fired: bool = false
var _hitbox_rect: RectangleShape2D


func _ready() -> void:
	add_to_group("player")
	if stats == null:
		push_warning("Player: no stats assigned, loading %s." % DEFAULT_STATS_PATH)
		stats = load(DEFAULT_STATS_PATH) as PlayerStats
	if stats == null:
		push_error("Player: could not load stats, using built-in defaults.")
		stats = PlayerStats.new()
	_hitbox_rect = RectangleShape2D.new()
	_hitbox_shape.shape = _hitbox_rect

	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	apply_stats(stats)

	_set_facing(facing)
	_visual.play_state(&"idle")


func _physics_process(delta: float) -> void:
	_state_time += delta
	if not is_on_floor():
		velocity.y += _gravity * delta
	match _state:
		State.IDLE, State.RUN:
			_process_free(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DASH:
			_process_dash(delta)
		State.SPIRIT_SLASH:
			_process_spirit_slash(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, HURT_FRICTION * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, min_x, max_x)


func _process(_delta: float) -> void:
	_visual.set_blinking(_health.is_invulnerable() and _state != State.DASH and _state != State.DEAD)


# --- Public API -------------------------------------------------------------

## Swaps in a stats resource (e.g. an upgraded copy for this battle) and refills health.
func apply_stats(new_stats: PlayerStats) -> void:
	if new_stats == null:
		push_error("Player: apply_stats() called with null stats; keeping current stats.")
		return
	stats = new_stats
	_combo = stats.get_combo()
	_dash_cooldown.duration = stats.dash_cooldown
	_heavy_cooldown.duration = stats.heavy_cooldown
	_spirit_slash_cooldown.duration = stats.spirit_slash_cooldown
	_health.max_health = stats.max_health
	_health.reset()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	_health.reset()
	_health.set_invulnerable_for(RESPAWN_INVULNERABILITY)
	_hurtbox.set_enabled(true)
	_hitbox.deactivate()
	_dash_cooldown.reset()
	_combo_index = 0
	_set_facing(1)
	_change_state(State.IDLE)
	_visual.play_state(&"idle")
	respawned.emit()


func is_targetable() -> bool:
	return _state != State.DEAD and not _health.is_dead()


func is_dead() -> bool:
	return _health.is_dead()


func get_health() -> HealthComponent:
	return _health


func get_state_name() -> String:
	return State.keys()[_state]


## {"dash"|"heavy"|"slash": Vector2(seconds_left, total_duration)} for HUD/touch cooldown fills.
func get_ability_cooldowns() -> Dictionary:
	return {
		"dash": Vector2(_dash_cooldown.time_left, _dash_cooldown.duration),
		"heavy": Vector2(_heavy_cooldown.time_left, _heavy_cooldown.duration),
		"slash": Vector2(_spirit_slash_cooldown.time_left, _spirit_slash_cooldown.duration),
	}


func get_dash_cooldown_left() -> float:
	return _dash_cooldown.time_left


func get_heavy_cooldown_left() -> float:
	return _heavy_cooldown.time_left


func get_spirit_slash_cooldown_left() -> float:
	return _spirit_slash_cooldown.time_left


# --- States -----------------------------------------------------------------

func _process_free(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	if _try_start_action(input_dir):
		return
	velocity.x = move_toward(velocity.x, input_dir * stats.move_speed, stats.acceleration * delta)
	var moving: bool = absf(input_dir) > 0.01
	if moving:
		_set_facing(int(signf(input_dir)))
	var next_state: State = State.RUN if moving else State.IDLE
	if next_state != _state:
		_change_state(next_state)
	_visual.play_state(&"run" if moving else &"idle")


func _try_start_action(input_dir: float) -> bool:
	if Input.is_action_just_pressed("dash") and _dash_cooldown.is_available():
		_start_dash(input_dir)
		return true
	if Input.is_action_just_pressed("spirit_slash") and _spirit_slash_cooldown.is_available():
		_start_spirit_slash(input_dir)
		return true
	if Input.is_action_just_pressed("heavy_attack") and _heavy_cooldown.is_available():
		_heavy_cooldown.start()
		_start_attack(stats.get_heavy_attack(), true, input_dir)
		return true
	if Input.is_action_just_pressed("attack"):
		_combo_index = 0
		_start_attack(_combo[0], false, input_dir)
		return true
	return false


func _start_attack(profile: AttackProfile, heavy: bool, input_dir: float) -> void:
	if absf(input_dir) > 0.01:
		_set_facing(int(signf(input_dir)))
	_current_attack = profile
	_is_heavy = heavy
	_attack_phase = AttackPhase.WINDUP
	_attack_buffered = false
	_change_state(State.ATTACK)
	_visual.play_state(&"heavy_windup" if heavy else &"windup")


func _process_attack(delta: float) -> void:
	# Dash cancels any attack phase.
	if Input.is_action_just_pressed("dash") and _dash_cooldown.is_available():
		_hitbox.deactivate()
		_start_dash(Input.get_axis("move_left", "move_right"))
		return
	if not _is_heavy and Input.is_action_just_pressed("attack"):
		_attack_buffered = true

	var attack: AttackProfile = _current_attack
	match _attack_phase:
		AttackPhase.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, stats.acceleration * delta)
			if _state_time >= attack.windup:
				_attack_phase = AttackPhase.ACTIVE
				_activate_hitbox(attack)
				velocity.x = facing * attack.lunge_speed
				_visual.play_state(&"strike")
		AttackPhase.ACTIVE:
			velocity.x = move_toward(velocity.x, 0.0, stats.acceleration * 0.5 * delta)
			if _state_time >= attack.windup + attack.active_time:
				_attack_phase = AttackPhase.RECOVERY
		AttackPhase.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, stats.acceleration * delta)
			# A buffered press chains into the next combo hit, cancelling recovery.
			if _attack_buffered and not _is_heavy and _combo_index < _combo.size() - 1:
				_combo_index += 1
				_start_attack(_combo[_combo_index], false, Input.get_axis("move_left", "move_right"))
				return
			if _state_time >= attack.get_total_duration():
				_combo_index = 0
				_change_state(State.IDLE)
				_visual.play_state(&"idle")


func _activate_hitbox(attack: AttackProfile) -> void:
	_hitbox_rect.size = attack.hitbox_size
	_hitbox_shape.position = Vector2(attack.hitbox_offset.x * facing, attack.hitbox_offset.y)
	_hitbox.knockback_direction_x = facing
	_hitbox.activate(stats.base_damage * attack.damage_multiplier, attack.knockback, attack.active_time)


func _start_dash(input_dir: float) -> void:
	_dash_direction = int(signf(input_dir)) if absf(input_dir) > 0.01 else facing
	_set_facing(_dash_direction)
	_dash_distance_left = stats.dash_distance
	_health.set_invulnerable_for(stats.dash_duration + 0.05)
	_dash_cooldown.start()
	_combo_index = 0
	_change_state(State.DASH)
	_visual.play_state(&"dash")


func _process_dash(delta: float) -> void:
	if _dash_distance_left <= 0.001 or delta <= 0.0:
		velocity.x = 0.0
		_change_state(State.IDLE)
		_visual.play_state(&"idle")
		return
	# Distance-based so the dash covers exactly dash_distance at any frame rate.
	var speed: float = stats.dash_distance / maxf(stats.dash_duration, 0.01)
	var step: float = minf(speed * delta, _dash_distance_left)
	_dash_distance_left -= step
	velocity.x = _dash_direction * step / delta


func _start_spirit_slash(input_dir: float) -> void:
	if absf(input_dir) > 0.01:
		_set_facing(int(signf(input_dir)))
	_spirit_slash_cooldown.start()
	_slash_fired = false
	_combo_index = 0
	_change_state(State.SPIRIT_SLASH)
	_visual.play_state(&"cast")


func _process_spirit_slash(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, stats.acceleration * delta)
	if not _slash_fired and _state_time >= stats.spirit_slash_windup:
		_slash_fired = true
		_fire_spirit_slash()
		_visual.play_state(&"strike")
	if _state_time >= stats.spirit_slash_windup + stats.spirit_slash_recovery:
		_change_state(State.IDLE)
		_visual.play_state(&"idle")


func _fire_spirit_slash() -> void:
	var projectile: SpiritSlash = SPIRIT_SLASH_SCENE.instantiate() as SpiritSlash
	if projectile == null:
		push_error("Player: spirit slash scene did not instantiate a SpiritSlash.")
		return
	var start: Vector2 = global_position + Vector2(facing * 40.0, -60.0)
	projectile.setup(facing, stats.spirit_slash_damage, stats.spirit_slash_speed,
			stats.spirit_slash_range, stats.spirit_slash_knockback, self, start)
	if projectile_fired.get_connections().is_empty():
		get_parent().add_child(projectile)
	else:
		projectile_fired.emit(projectile)


func _process_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, HURT_FRICTION * delta)
	if _state_time >= stats.hurt_duration:
		_change_state(State.IDLE)
		_visual.play_state(&"idle")


# --- Signal handlers --------------------------------------------------------

func _on_hit_received(hit: HitData) -> void:
	_visual.flash_hit()
	if _health.is_dead():
		return
	# Any hit interrupts the current action.
	_hitbox.deactivate()
	velocity.x = hit.knockback.x * (1.0 - stats.knockback_resistance)
	_health.set_invulnerable_for(stats.hurt_invulnerability)
	_combo_index = 0
	_change_state(State.HURT)
	_visual.play_state(&"hurt")


func _on_died() -> void:
	_hitbox.deactivate()
	_hurtbox.set_enabled(false)
	_change_state(State.DEAD)
	_visual.play_state(&"dead")
	died.emit()


func _on_health_changed(current: float, maximum: float) -> void:
	health_changed.emit(current, maximum)


func _change_state(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0


func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	_visual.set_facing(direction)
