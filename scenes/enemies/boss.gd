class_name Boss
extends Enemy
## The Fallen Daimyo and any other boss: an Enemy driven by a BossData (phases + attacks) instead of one
## melee swing. It keeps the generic enemy's targeting, health and death, and replaces the attack:
##   - it picks a telegraphed attack that fits the distance to its target (see BossAttackData);
##   - every attack is WINDUP (a ground warning plus a readable pose) -> ACTIVE -> RECOVER;
##   - at 66% and 33% health it roars, untouchable, for a moment and enters the next, faster phase.
## Damage still only flows through HitboxComponent / HurtboxComponent (melee attacks use the Enemy's own
## hitbox, resized per attack; the cursed wave is a projectile with its own hitbox).

## Health changed: the boss bar at the top of the screen listens to this.
signal boss_health_changed(current: float, maximum: float)
## A new phase began (2 or 3). `banner` is the line to show.
signal phase_changed(phase: int, banner: String)
## He wants minions: the battlefield spawns them (through its spawner) and calls register_minion().
signal minions_requested(enemy_data: EnemyData, positions: PackedFloat32Array)

enum Step { WINDUP, ACTIVE, AIR, RECOVER }

## A leap takes this long in the air at phase speed 1.
const LEAP_AIR_TIME: float = 0.8
## Hits that come within this long of a repeat's windup are shorter (combos are quicker).
const COMBO_WINDUP_FACTOR: float = 0.7
const MINION_SPREAD: float = 130.0

var phase: int = 1

var _boss: BossData
var _current: BossAttackData
var _step: Step = Step.WINDUP
var _step_time: float = 0.0
var _step_length: float = 0.0
var _repeats_left: int = 0
var _cooldowns: Dictionary = {}
var _gap_left: float = 1.0
var _last_attack: StringName = &""
var _transition_left: float = 0.0
var _telegraphs: Array[AttackTelegraph] = []
var _minions: Array[Enemy] = []
var _leap_x: float = 0.0
var _summon_xs: PackedFloat32Array = PackedFloat32Array()
## Where the pillars of an ERUPTION will burst (chosen at the wind-up, under the warnings).
var _pillar_xs: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	# Before the parent's _ready: it resets health, which already reports to _on_health_changed.
	_boss = data as BossData
	super()
	if _boss == null:
		push_error("Boss '%s': its data is not a BossData." % name)
		_boss = BossData.new()
	# He has a bar at the top of the screen, not over his head, and shrugs off hits and knockback.
	_health_bar.hide_until_damaged = false
	_health_bar.stagger = false
	_health_bar.visible = false
	_visual.set_rage(1)
	_visual.heavy_step.connect(_on_heavy_step)
	boss_health_changed.emit(_health.current_health, _health.max_health)


func _on_heavy_step(at: Vector2) -> void:
	if is_dead() or not _visual.is_on_screen(): return
	var dust: BossFootDust = BossFootDust.new()
	get_parent().add_child(dust)
	dust.global_position = at
	AudioManager.play(&"boss_footstep", 0.72)
	if is_instance_valid(BattleFeedback.active): BattleFeedback.active.shake(1.8, 0.09)


func get_health() -> HealthComponent:
	return _health


## The current phase's numbers.
func get_phase_data() -> BossPhaseData:
	return _boss.get_phase(phase)


func get_current_attack() -> BossAttackData:
	return _current


func is_transitioning() -> bool:
	return _transition_left > 0.0


## Minions he called, still alive.
func get_minion_count() -> int:
	var alive: int = 0
	for minion: Enemy in _minions:
		if is_instance_valid(minion) and not minion.is_dead():
			alive += 1
	return alive


func register_minion(minion: Enemy) -> void:
	_minions.append(minion)


func _speed_factor() -> float:
	return get_phase_data().speed_multiplier


func _physics_process(delta: float) -> void:
	for id: StringName in _cooldowns.keys():
		_cooldowns[id] = maxf(float(_cooldowns[id]) - delta, 0.0)
	_gap_left = maxf(_gap_left - delta, 0.0)
	if _transition_left > 0.0:
		_run_transition(delta)
		return
	super(delta)


# --- Generic enemy hooks ----------------------------------------------------

## No random variation for a boss: the same size and speed every time.
func _apply_data() -> void:
	_spacing_scale = 1.0
	UnitRig.build_collision(_body_shape, _hurtbox_shape, _hitbox_shape, data.body_size, _attack.hitbox_size)
	var head_top: float = _visual.configure(data.figure, data.body_size.y)
	_health_bar.set_base_position(Vector2(0.0, head_top - 18.0))


## He walks through his own minions and at his own phase speed.
func _walk(direction: int, delta: float) -> void:
	_set_facing(direction)
	var speed: float = data.move_speed * _speed_factor()
	velocity.x = move_toward(velocity.x, direction * speed, speed * 8.0 * delta)
	_visual.play_state(&"run" if absf(velocity.x) > 1.0 else &"idle")


func _on_health_changed(current: float, maximum: float) -> void:
	boss_health_changed.emit(current, maximum)
	if _health.is_dead() or _transition_left > 0.0:
		return
	var next_phase: int = _boss.phase_for_ratio(current / maxf(maximum, 0.001))
	if next_phase > phase:
		_enter_phase(next_phase)


func _on_died() -> void:
	_cancel_attack()
	super()
	# The curse breaks with him: his minions fall too.
	for minion: Enemy in _minions:
		if is_instance_valid(minion) and not minion.is_dead():
			var health: HealthComponent = minion.get_node("HealthComponent") as HealthComponent
			health.take_damage(minion.data.max_health * 10.0, self)


# --- Phases -----------------------------------------------------------------

func _enter_phase(new_phase: int) -> void:
	_cancel_attack()
	phase = new_phase
	var phase_data: BossPhaseData = get_phase_data()
	_transition_left = phase_data.pause_time
	_health.set_invulnerable_for(phase_data.pause_time)
	_gap_left = phase_data.attack_gap + 0.4
	_visual.set_rage(phase)
	_visual.play_state(&"cast")
	_visual.flash_hit()
	_spawn_ring(520.0)
	AudioManager.play(&"ultimate", 0.6)
	AudioManager.play(&"roar", 0.75)
	if is_instance_valid(BattleFeedback.active):
		BattleFeedback.active.hit_stop(0.12)
		BattleFeedback.active.shake(12.0, 0.5)
	phase_changed.emit(phase, phase_data.banner)


func _run_transition(delta: float) -> void:
	_transition_left -= delta
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	if not is_on_floor():
		velocity.y += _gravity * delta
	move_and_slide()
	if _transition_left <= 0.0:
		_resume()


# --- Choosing an attack -----------------------------------------------------

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
	if _gap_left <= 0.0:
		var pick: BossAttackData = _choose_attack(absf(dx))
		if pick != null:
			_set_facing(direction)
			_begin_attack(pick)
			return
	if absf(dx) > data.attack_range:
		_walk(direction, delta)
	else:
		_set_facing(direction)
		_brake(delta)
		_visual.play_state(&"idle")


## An attack that fits the distance, is off cooldown and unlocked in this phase (null if none).
func _choose_attack(distance: float) -> BossAttackData:
	var options: Array[BossAttackData] = []
	var weights: Array[float] = []
	var total: float = 0.0
	for attack: BossAttackData in _boss.attacks:
		if attack == null or attack.min_phase > phase:
			continue
		if float(_cooldowns.get(attack.id, 0.0)) > 0.0:
			continue
		if attack.kind == BossAttackData.Kind.SUMMON:
			if get_minion_count() >= attack.minion_cap or attack.summon_enemy == null:
				continue
		elif distance < attack.min_range or distance > attack.max_range:
			continue
		var weight: float = maxf(attack.weight, 0.01) * (0.35 if attack.id == _last_attack else 1.0)
		options.append(attack)
		weights.append(weight)
		total += weight
	if options.is_empty():
		return null
	var roll: float = randf() * total
	for i: int in options.size():
		roll -= weights[i]
		if roll <= 0.0:
			return options[i]
	return options[options.size() - 1]


# --- Running an attack ------------------------------------------------------

func _begin_attack(attack: BossAttackData) -> void:
	_current = attack
	_last_attack = attack.id
	_cooldowns[attack.id] = attack.cooldown / _speed_factor()
	_repeats_left = _repeat_count(attack)
	_change_state(State.ATTACK)
	_aim()
	_start_windup(1.0)


func _repeat_count(attack: BossAttackData) -> int:
	return [attack.repeats.x, attack.repeats.y, attack.repeats.z][clampi(phase - 1, 0, 2)]


## The readable part: the pose changes, a warning appears on the ground, and nothing hurts yet.
func _start_windup(length_factor: float) -> void:
	_step = Step.WINDUP
	_step_time = 0.0
	_step_length = _current.windup * length_factor / _speed_factor()
	_clear_telegraphs()
	match _current.kind:
		BossAttackData.Kind.SWEEP:
			_visual.play_state(&"windup")
			_telegraph(AttackTelegraph.Shape.ELLIPSE, _zone_centre(_current), Vector2(_current.hitbox_size.x, 56.0))
		BossAttackData.Kind.SLAM:
			_visual.play_state(&"heavy_windup")
			_telegraph(AttackTelegraph.Shape.ELLIPSE, global_position + Vector2(0.0, -2.0), Vector2(_current.hitbox_size.x, 64.0))
		BossAttackData.Kind.LEAP:
			_visual.play_state(&"windup")
			_leap_x = _target_x(_target) if _has_valid_target() else global_position.x + facing * 300.0
			_telegraph(AttackTelegraph.Shape.ELLIPSE, Vector2(_leap_x, global_position.y - 2.0), Vector2(_current.hitbox_size.x, 60.0))
		BossAttackData.Kind.WAVE:
			_visual.play_state(&"cast")
			var length: float = _current.projectile_range
			_telegraph(AttackTelegraph.Shape.STRIP, global_position + Vector2(facing * (length * 0.5 + 40.0), -14.0), Vector2(length, 26.0))
		BossAttackData.Kind.SUMMON:
			_visual.play_state(&"cast")
			_summon_xs = _summon_positions(_current)
			for x: float in _summon_xs:
				_telegraph(AttackTelegraph.Shape.ELLIPSE, Vector2(x, global_position.y - 2.0), Vector2(110.0, 40.0))
		BossAttackData.Kind.ERUPTION:
			_visual.play_state(&"cast")
			_pillar_xs = _pillar_positions(_current)
			for x: float in _pillar_xs:
				_telegraph(AttackTelegraph.Shape.ELLIPSE, Vector2(x, global_position.y - 2.0), Vector2(_current.pillar_size.x * 1.2, 46.0))
	_visual.play_boss_attack_stage(_current.kind, &"windup", _step_length)


func _process_attack(delta: float) -> void:
	_step_time += delta
	if _step != Step.AIR:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	match _step:
		Step.WINDUP:
			if _step_time >= _step_length:
				_fire()
		Step.ACTIVE:
			if _step_time >= _step_length:
				_step = Step.RECOVER
				_step_time = 0.0
				_step_length = _current.recovery / _speed_factor()
				_visual.play_boss_attack_stage(_current.kind, &"recover", _step_length)
		Step.AIR:
			if (_step_time > 0.25 and is_on_floor()) or _step_time > LEAP_AIR_TIME * 3.0:
				_land()
		Step.RECOVER:
			if _step_time >= _step_length:
				_repeats_left -= 1
				if _repeats_left > 0 and _current.kind != BossAttackData.Kind.SUMMON:
					_start_windup(COMBO_WINDUP_FACTOR)
				else:
					_finish_attack()


## The wind-up is over: the attack lands.
func _fire() -> void:
	_clear_telegraphs()
	if data.figure == InkFigure.Kind.BURNING_GENERAL:
		var blaze: PaintedFireBurst = PaintedFireBurst.new()
		blaze.trail = true
		blaze.span = Vector2(380, 125)
		blaze.duration = 0.55
		get_parent().add_child(blaze)
		blaze.global_position = global_position + Vector2(facing * 120.0, -70.0)
		blaze.scale.x = facing
	match _current.kind:
		BossAttackData.Kind.SWEEP:
			_activate_hitbox(_current, true)
			_sword_strike()
			AudioManager.play(&"sword_swing", 0.7)
			_begin_active()
		BossAttackData.Kind.SLAM:
			_activate_hitbox(_current, false)
			_sword_strike()
			_spawn_ring(_current.hitbox_size.x * 0.5)
			_impact_feedback(8.0)
			_begin_active()
		BossAttackData.Kind.LEAP:
			_launch_leap()
		BossAttackData.Kind.WAVE:
			_spawn_wave()
			_sword_strike()
			AudioManager.play(&"magic_burst", 0.7)
			_begin_active()
		BossAttackData.Kind.SUMMON:
			AudioManager.play(&"boss_summon")
			_visual.flash_hit()
			minions_requested.emit(_current.summon_enemy, _summon_xs)
			_spawn_ring(300.0)
			_begin_active()
		BossAttackData.Kind.ERUPTION:
			_spawn_pillars()
			_sword_strike()
			_impact_feedback(7.0)
			AudioManager.play(&"explosion", 0.8)
			_begin_active()


func _begin_active() -> void:
	_step = Step.ACTIVE
	_step_time = 0.0
	_step_length = maxf(_current.active_time / _speed_factor(), 0.12)


func _sword_strike() -> void:
	_visual.play_boss_attack_stage(_current.kind, &"strike", maxf(_current.active_time / _speed_factor(), 0.16))


func _finish_attack() -> void:
	_current = null
	_gap_left = get_phase_data().attack_gap
	_resume()


## Ends everything in progress (a phase change, or death).
func _cancel_attack() -> void:
	_visual.end_boss_attack()
	_hitbox.deactivate()
	_clear_telegraphs()
	_current = null


## Faces the target.
func _aim() -> void:
	if _has_valid_target():
		_set_facing(-1 if _target_x(_target) < global_position.x else 1)


## Opens the Enemy's hitbox with this attack's size and place. `forward`: it sits in front of him and
## knocks the way he faces; otherwise it is centred on him and pushes away from him.
func _activate_hitbox(attack: BossAttackData, forward: bool) -> void:
	var rect: RectangleShape2D = _hitbox_shape.shape as RectangleShape2D
	rect.size = attack.hitbox_size
	_hitbox_shape.position = Vector2(attack.hitbox_offset.x * facing if forward else attack.hitbox_offset.x, attack.hitbox_offset.y)
	_hitbox.knockback_direction_x = float(facing) if forward else 0.0
	var damage: float = data.attack_damage * attack.damage_multiplier * get_phase_data().damage_multiplier
	_hitbox.activate(damage, attack.knockback, maxf(attack.active_time / _speed_factor(), 0.1), true)


# --- The five attacks' details ---------------------------------------------

func _launch_leap() -> void:
	var air_time: float = LEAP_AIR_TIME / _speed_factor()
	velocity.y = -_gravity * air_time * 0.5
	velocity.x = (_leap_x - global_position.x) / air_time
	_step = Step.AIR
	_step_time = 0.0
	_visual.play_boss_attack_stage(_current.kind, &"air", air_time)
	AudioManager.play(&"dash", 0.6)


func _land() -> void:
	velocity.x = 0.0
	_activate_hitbox(_current, false)
	_sword_strike()
	_spawn_ring(_current.hitbox_size.x * 0.5)
	_impact_feedback(10.0)
	_begin_active()


func _spawn_wave() -> void:
	var wave: CursedWave = CursedWave.new()
	var damage: float = data.attack_damage * _current.damage_multiplier * get_phase_data().damage_multiplier
	wave.setup(facing, damage, _current.projectile_speed * _speed_factor(), _current.projectile_range, _current.knockback, self,
			global_position + Vector2(facing * 90.0, 0.0))
	wave.fire = _current.fire
	get_parent().add_child(wave)


## The pillars of fire, centred on the target (or ahead of him without one), spread pillar_spacing apart.
func _pillar_positions(attack: BossAttackData) -> PackedFloat32Array:
	var centre: float = _target_x(_target) if _has_valid_target() else global_position.x + facing * 300.0
	var xs: PackedFloat32Array = PackedFloat32Array()
	for i: int in attack.pillar_count:
		xs.append(centre + (float(i) - float(attack.pillar_count - 1) * 0.5) * attack.pillar_spacing)
	return xs


func _spawn_pillars() -> void:
	var damage: float = data.attack_damage * _current.damage_multiplier * get_phase_data().damage_multiplier
	for x: float in _pillar_xs:
		var pillar: FirePillar = FirePillar.new()
		pillar.setup(damage, _current.knockback, _current.pillar_size, maxf(_current.active_time / _speed_factor(), 0.15), self)
		get_parent().add_child(pillar)
		pillar.global_position = Vector2(x, global_position.y)


## Where summoned soldiers will rise: both sides of him, close to the ground warning rings.
func _summon_positions(attack: BossAttackData) -> PackedFloat32Array:
	var xs: PackedFloat32Array = PackedFloat32Array()
	for i: int in attack.summon_count:
		var side: float = -1.0 if i % 2 == 0 else 1.0
		xs.append(global_position.x + side * (MINION_SPREAD * (1.0 + float(i / 2))))
	return xs


# --- Effects -------------------------------------------------------------------

func _zone_centre(attack: BossAttackData) -> Vector2:
	return global_position + Vector2(attack.hitbox_offset.x * facing, -2.0)


func _telegraph(shape: AttackTelegraph.Shape, centre: Vector2, size: Vector2) -> void:
	var warning: AttackTelegraph = AttackTelegraph.new()
	warning.setup(shape, size, _step_length)
	get_parent().add_child(warning)
	warning.global_position = centre
	_telegraphs.append(warning)


func _clear_telegraphs() -> void:
	for warning: AttackTelegraph in _telegraphs:
		if is_instance_valid(warning):
			warning.dismiss()
	_telegraphs.clear()


func _spawn_ring(radius: float) -> void:
	var ring: ShockRing = ShockRing.new()
	ring.setup(radius)
	get_parent().add_child(ring)
	ring.global_position = global_position


func _impact_feedback(strength: float) -> void:
	AudioManager.play(&"heavy_hit", 0.6)
	AudioManager.play(&"slam", 0.85)
	if is_instance_valid(BattleFeedback.active):
		BattleFeedback.active.shake(strength, 0.25)
