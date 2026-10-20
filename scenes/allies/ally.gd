class_name Ally
extends CharacterBody2D
## Generic summoned ally driven by an AllyData resource.
## FSM: SPAWN -> IDLE (hold home position) -> ADVANCE -> ATTACK -> RECOVER, with HURT and DEAD.
## Engages the nearest living enemy in aggro range, stops at attack range and attacks automatically.
## Roles (AllyData.role): a FIGHTER hits (melee hitbox or arrow); a HEALER walks to the most injured
## ally in range and heals it instead of attacking; a MAGE casts a burst that hits every enemy
## around its target.

signal defeated(ally: Ally)
## A healer's blessing landed: who was healed and by how much.
signal healed(target: Ally, amount: float)

enum State { SPAWN, IDLE, ADVANCE, ATTACK, RECOVER, HURT, DEAD }
enum AttackPhase { WINDUP, ACTIVE }

const ARROW_SCENE: PackedScene = preload("res://scenes/allies/arrow.tscn")
const SCAN_INTERVAL: float = 0.2
const FRICTION: float = 1800.0
const CORPSE_TIME: float = 0.8
const HOME_TOLERANCE: float = 10.0
const LOSE_TARGET_FACTOR: float = 1.5
const INTERRUPT_ATTACK_DELAY: float = 0.3
## Allies are DRAWN in their own sideways lane (px), so a group standing on one spot reads as separate
## people, not one dark blob. Only the picture moves: bodies, hitboxes, reach and summoning are
## untouched (physically spreading allies made them measurably weaker in tools/balance_sim.gd).
const LANES: Array[float] = [0.0, -42.0, 42.0, -21.0, 21.0, -63.0, 63.0, -10.0, 10.0, -32.0, 32.0, -52.0, 52.0]

@export var data: AllyData
## Where the ally waits when no enemy is in range. NAN = position when it enters the tree.
@export var home_x: float = NAN
## The sideways offset this ally is drawn at (see LANES).
var lane_x: float = 0.0

@onready var _visual: UnitVisual = $Visual
@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var _health_bar: WorldHealthBar = $HealthBar

var facing: int = 1

var _state: State = State.SPAWN
var _state_time: float = 0.0
var _attack: AttackProfile
var _attack_phase: AttackPhase = AttackPhase.WINDUP
var _attack_cooldown_left: float = 0.0
var _target: Enemy
var _scan_timer: float = 0.0
var _heal_target: Ally
var _area_hitbox: HitboxComponent
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)


## Call before adding to the tree.
func setup(ally_data: AllyData, p_home_x: float) -> void:
	data = ally_data
	home_x = p_home_x


func _ready() -> void:
	add_to_group("allies")
	if data == null:
		push_error("Ally '%s': no AllyData assigned, using defaults." % name)
		data = AllyData.new()
	_attack = data.attack
	if _attack == null:
		push_error("Ally '%s': AllyData '%s' has no attack, using defaults." % [name, data.display_name])
		_attack = AttackProfile.new()
	UnitRig.build_collision(_body_shape, _hurtbox_shape, _hitbox_shape, data.body_size, _attack.hitbox_size)
	_visual.enable_variation()
	lane_x = _pick_lane()
	_visual.position.x = lane_x
	var head_top: float = _visual.configure(data.figure, data.body_size.y)
	_health_bar.position = Vector2(lane_x, head_top - 22.0)
	_health_bar.bar_size = Vector2(clampf(data.body_size.x * 1.4, 56.0, 120.0), 8.0)

	_health.health_changed.connect(_health_bar.set_values)
	_health.died.connect(_on_died)
	_hurtbox.hit_received.connect(_on_hit_received)
	_health.max_health = data.max_health
	_health.reset()
	_set_facing(1)
	_change_state(State.SPAWN)
	_visual.play_state(&"spawn")


func _physics_process(delta: float) -> void:
	if is_nan(home_x):
		home_x = global_position.x
	_state_time += delta
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	if not is_on_floor():
		velocity.y += _gravity * delta
	match _state:
		State.SPAWN:
			velocity.x = 0.0
			if _state_time >= data.spawn_duration:
				_change_state(State.IDLE)
		State.IDLE:
			_process_idle(delta)
		State.ADVANCE:
			_process_advance(delta)
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

func is_targetable() -> bool:
	return _state != State.DEAD


func is_dead() -> bool:
	return _state == State.DEAD


func get_state_name() -> String:
	return State.keys()[_state]


func get_health() -> HealthComponent:
	return _health


## Current target, or null if there is none or it has been freed.
func get_target() -> Enemy:
	return _target if _has_valid_target() else null


## Nearest living enemy within aggro range, or null.
func select_target() -> Enemy:
	var best: Enemy = null
	var best_distance: float = data.aggro_range
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if not _is_valid_enemy(enemy):
			continue
		var distance: float = absf(enemy.global_position.x - global_position.x)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


# --- States -----------------------------------------------------------------

func _process_idle(delta: float) -> void:
	if data.role == AllyData.Role.HEALER:
		_process_support(delta)
		return
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		var found: Enemy = select_target()
		if found != null:
			_target = found
			_change_state(State.ADVANCE)
			return
	_idle_at_home(delta)


func _idle_at_home(delta: float) -> void:
	var dx: float = home_x - global_position.x
	if absf(dx) > HOME_TOLERANCE:
		_walk(-1 if dx < 0.0 else 1, delta)
	else:
		_brake(delta)
		_set_facing(1)
		_visual.play_state(&"idle")


## Healer: find the most injured ally in range, walk to it and bless it; otherwise wait at home.
func _process_support(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		_heal_target = _find_heal_target()
	if not _has_valid_heal_target():
		if _state == State.ADVANCE:
			_change_state(State.IDLE)
		_idle_at_home(delta)
		return
	if _state == State.IDLE:
		_change_state(State.ADVANCE)
	var dx: float = _heal_target.global_position.x - global_position.x
	var direction: int = -1 if dx < 0.0 else 1
	if absf(dx) <= data.attack_range:
		_set_facing(direction)
		_brake(delta)
		_visual.play_state(&"idle")
		if _attack_cooldown_left <= 0.0:
			_attack_phase = AttackPhase.WINDUP
			_change_state(State.ATTACK)
			_visual.play_state(&"windup")
	else:
		_walk(direction, delta)


## The injured ally (not herself) with the lowest health ratio within aggro range, or null.
func _find_heal_target() -> Ally:
	var best: Ally = null
	var best_ratio: float = data.heal_below_ratio
	for node: Node in get_tree().get_nodes_in_group("allies"):
		var ally: Ally = node as Ally
		if ally == null or ally == self or not ally.is_inside_tree() or ally.is_dead():
			continue
		if absf(ally.global_position.x - global_position.x) > data.aggro_range:
			continue
		var ratio: float = ally.get_health().get_ratio()
		if ratio < best_ratio:
			best = ally
			best_ratio = ratio
	return best


## True while the stored heal target is a living ally still below the heal threshold.
func _has_valid_heal_target() -> bool:
	if not is_instance_valid(_heal_target) or not _heal_target.is_inside_tree() or _heal_target.is_dead() \
			or _heal_target.get_health().get_ratio() >= data.heal_below_ratio:
		_heal_target = null
		return false
	return true


func _process_advance(delta: float) -> void:
	if data.role == AllyData.Role.HEALER:
		_process_support(delta)
		return
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		var nearest: Enemy = select_target()
		if nearest != null:
			_target = nearest
	if not _has_valid_target():
		_change_state(State.IDLE)
		return
	var dx: float = _target.global_position.x - global_position.x
	if absf(dx) > data.aggro_range * LOSE_TARGET_FACTOR:
		_target = null
		_change_state(State.IDLE)
		return
	var direction: int = -1 if dx < 0.0 else 1
	if absf(dx) <= data.attack_range:
		_set_facing(direction)
		_brake(delta)
		_visual.play_state(&"idle")
		if _attack_cooldown_left <= 0.0:
			_attack_phase = AttackPhase.WINDUP
			_change_state(State.ATTACK)
			_visual.play_state(&"windup")
	else:
		_walk(direction, delta)


func _process_attack(delta: float) -> void:
	_brake(delta)
	match _attack_phase:
		AttackPhase.WINDUP:
			if _state_time >= _attack.windup:
				_attack_phase = AttackPhase.ACTIVE
				if data.role == AllyData.Role.HEALER:
					_cast_heal()
				elif data.role == AllyData.Role.MAGE:
					_cast_burst()
				elif data.is_ranged:
					_fire_arrow()
				else:
					_hitbox_shape.position = Vector2(_attack.hitbox_offset.x * facing, _attack.hitbox_offset.y)
					_hitbox.knockback_direction_x = facing
					_hitbox.activate(data.attack_damage * _attack.damage_multiplier, _attack.knockback, _attack.active_time, _attack.heavy)
					AudioManager.play(&"sword_swing", 1.1)
				_visual.play_state(&"strike")
		AttackPhase.ACTIVE:
			if _state_time >= _attack.windup + _attack.active_time:
				_change_state(State.RECOVER)


## Heals the heal target now (the blessing lands as the wand comes down).
func _cast_heal() -> void:
	if not _has_valid_heal_target():
		return
	var target: Ally = _heal_target
	var restored: float = target.get_health().heal(data.attack_damage * _attack.damage_multiplier)
	AudioManager.play(&"heal")
	var glint: HealGlint = HealGlint.new()
	glint.setup(target.data.body_size.y)
	get_parent().add_child(glint)
	glint.global_position = target.global_position
	if restored > 0.0:
		healed.emit(target, restored)
		if is_instance_valid(BattleFeedback.active):
			BattleFeedback.active.spawn_text_number(target.global_position + Vector2(0.0, -target.data.body_size.y),
					"+%d" % roundi(restored), InkPalette.JADE)


## Bursts every enemy within area_radius of the current target (or of a point ahead if the
## target is gone). The damage goes through the normal hitbox validation, once per enemy.
func _cast_burst() -> void:
	var target: Enemy = get_target()
	var center_x: float = target.global_position.x if target != null else global_position.x + float(facing) * data.attack_range * 0.6
	if _area_hitbox == null:
		_area_hitbox = HitboxComponent.new()
		_area_hitbox.name = "AreaHitbox"
		_area_hitbox.faction = Faction.Type.DEFENDERS
		_area_hitbox.source = self
		add_child(_area_hitbox)
	_area_hitbox.global_position = Vector2(center_x, global_position.y)
	_area_hitbox.activate(data.attack_damage * _attack.damage_multiplier, _attack.knockback, -1.0, _attack.heavy)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_inside_tree() or enemy.is_dead():
			continue
		if absf(enemy.global_position.x - center_x) <= data.area_radius + enemy.get_half_width():
			_area_hitbox.try_hit(enemy.get_hurtbox())
	_area_hitbox.deactivate()
	AudioManager.play(&"magic_burst")
	var burst: SpellBurst = SpellBurst.new()
	burst.setup(data.area_radius)
	get_parent().add_child(burst)
	burst.global_position = Vector2(center_x, global_position.y)


func _fire_arrow() -> void:
	var arrow: Arrow = ARROW_SCENE.instantiate() as Arrow
	if arrow == null:
		push_error("Ally: arrow scene did not instantiate an Arrow.")
		return
	var start: Vector2 = global_position + Vector2(facing * 24.0, -data.body_size.y * 0.6)
	arrow.setup(facing, data.attack_damage * _attack.damage_multiplier, data.projectile_speed,
			data.projectile_range, _attack.knockback, self, start)
	get_parent().add_child(arrow)


func _resume() -> void:
	if _has_valid_target():
		_change_state(State.ADVANCE)
	else:
		_change_state(State.IDLE)
	_visual.play_state(&"idle")


# --- Movement ---------------------------------------------------------------

func _walk(direction: int, delta: float) -> void:
	_set_facing(direction)
	var speed: float = data.move_speed * _visual.speed_variation
	var desired: float = 0.0 if _is_blocked_by_other_ally(direction) else direction * speed
	velocity.x = move_toward(velocity.x, desired, speed * 8.0 * delta)
	_visual.play_state(&"run" if absf(velocity.x) > 1.0 else &"idle")


func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)


## The lane that puts this ally's drawn figure furthest from every other living ally's drawn figure,
## so two allies standing on one spot are never drawn on top of each other (one lane order on a tie).
func _pick_lane() -> float:
	var here: float = home_x if not is_nan(home_x) else global_position.x
	var best: float = LANES[0]
	var best_gap: float = -1.0
	for lane: float in LANES:
		var gap: float = INF
		for node: Node in get_tree().get_nodes_in_group("allies"):
			var other: Ally = node as Ally
			if other == null or other == self or other.is_dead():
				continue
			gap = minf(gap, absf((here + lane) - (other.global_position.x + other.lane_x)))
		if gap > best_gap + 0.01:
			best_gap = gap
			best = lane
	return best


## Melee allies queue behind each other; ranged allies may stand behind anyone.
func _is_blocked_by_other_ally(direction: int) -> bool:
	if data.is_ranged_like():
		return false
	var my_half: float = data.body_size.x * 0.5
	for node: Node in get_tree().get_nodes_in_group("allies"):
		var other: Ally = node as Ally
		if other == null or other == self or other.is_dead() or other.data.is_ranged_like():
			continue
		var dx: float = other.global_position.x - global_position.x
		var spacing: float = (my_half + other.data.body_size.x * 0.5) * 0.85
		if absf(dx) >= spacing:
			continue
		if absf(dx) < 1.0:
			if get_instance_id() > other.get_instance_id():
				return true
			continue
		if (dx < 0.0) == (direction < 0):
			return true
	return false


## True if the stored target is still a living enemy; clears it otherwise.
## Checks the member directly: passing a freed object to a typed parameter is a script error.
func _has_valid_target() -> bool:
	if not is_instance_valid(_target) or not _target.is_inside_tree() or _target.is_dead():
		_target = null
		return false
	return true


## For live candidates from the scene tree (never a stored reference).
func _is_valid_enemy(enemy: Enemy) -> bool:
	return enemy != null and enemy.is_inside_tree() and not enemy.is_dead()


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
	remove_from_group("allies")
	set_deferred("collision_layer", 0)
	_health_bar.visible = false
	_change_state(State.DEAD)
	_visual.play_state(&"dead")
	defeated.emit(self)
	var tween: Tween = create_tween()
	tween.tween_interval(CORPSE_TIME)
	tween.tween_callback(queue_free)


func _change_state(new_state: State) -> void:
	_state = new_state
	_state_time = 0.0


func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	_visual.set_facing(direction)
