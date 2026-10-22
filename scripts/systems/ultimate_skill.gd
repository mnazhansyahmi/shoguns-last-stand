class_name UltimateSkill
extends Node
## The samurai's Ultimate: when the UltimateMeter is full the samurai raises his blade (invulnerable),
## then dashes through a suspended slash sequence; every marked hit lands together.
## Damage goes through the normal
## hitbox/hurtbox validation (faction, invulnerability, death), so enemies react as to any hit.
## UltimateCinematic draws the marks; this skill alone commits their damage.

signal activated
## The sweep landed: how many enemies it hit.
signal released(hits: int)
## The key was pressed before the meter was full.
signal not_ready(ratio: float)

enum Result { OK, NOT_READY, CANNOT_ACT, NO_PLAYER }

## The game stays frozen this long (real seconds) as the slash lands: a short beat, not a stop.
const PAUSE_SECONDS: float = 0.15
## Enemies this far outside the screen edge are still hit (their bodies reach into view).
const RANGE_MARGIN: float = 90.0
## Without a camera, the strike covers this far from the samurai on each side.
const FALLBACK_HALF_WIDTH: float = 950.0
const SWEEP_LAYER: int = 3
const IMPACT_TIME: float = 0.52
const CINEMATIC_TIME: float = 0.95

var player: Player
var camera: BattleCamera
var meter: UltimateMeter

var _hitbox: HitboxComponent
## Real seconds the freeze lasts (a test can shorten it).
var pause_seconds: float = PAUSE_SECONDS
var _cinematic_active: bool = false
var _age: float = 0.0
var _impact_done: bool = false
var _origin: Vector2
var _destination: Vector2
var _span: Vector2
var _layer: CanvasLayer
var _painting: UltimateCinematic
var _feedback: BattleFeedback
var _camera_was_processing: bool = false


func _ready() -> void:
	set_process(false)
	_hitbox = HitboxComponent.new()
	_hitbox.name = "UltimateHitbox"
	_hitbox.faction = Faction.Type.DEFENDERS
	add_child(_hitbox)


func _exit_tree() -> void:
	cancel_cinematic()


func _process(delta: float) -> void:
	advance_cinematic(minf(delta / maxf(Engine.time_scale, 0.001), 0.1))


func setup(p_player: Player, p_camera: BattleCamera, p_meter: UltimateMeter) -> void:
	if is_instance_valid(player) and player.ultimate_released.is_connected(_on_released):
		player.ultimate_released.disconnect(_on_released)
	player = p_player
	camera = p_camera
	meter = p_meter
	if is_instance_valid(player):
		player.ultimate_released.connect(_on_released)


## The ultimate button/key was pressed.
func request() -> Result:
	if not is_instance_valid(player) or not is_instance_valid(meter):
		return Result.NO_PLAYER
	if _cinematic_active or not player.can_use_ultimate():
		return Result.CANNOT_ACT
	if not meter.is_ready():
		not_ready.emit(meter.get_ratio())
		return Result.NOT_READY
	if not player.start_ultimate():
		return Result.CANNOT_ACT
	meter.try_consume()
	AudioManager.play(&"ultimate")
	activated.emit()
	return Result.OK


## World x range the sweep covers: what the screen shows, or around the samurai without a camera.
func get_strike_range(origin: Vector2) -> Vector2:
	if is_instance_valid(camera):
		var view: Rect2 = camera.get_view_rect()
		return Vector2(view.position.x - RANGE_MARGIN, view.end.x + RANGE_MARGIN)
	return Vector2(origin.x - FALLBACK_HALF_WIDTH, origin.x + FALLBACK_HALF_WIDTH)


## Hits every living enemy in range once. Returns how many it hit.
func strike(origin: Vector2, fixed_span: Vector2 = Vector2(NAN, NAN)) -> int:
	if not is_instance_valid(player) or not is_instance_valid(meter): return 0
	var damage: float = player.stats.base_damage * player.stats.ultimate_damage_multiplier
	var span: Vector2 = get_strike_range(origin) if is_nan(fixed_span.x) else fixed_span
	_hitbox.source = player
	_hitbox.global_position = origin
	_hitbox.knockback_direction_x = 0.0
	# The sweep's own hits must not refill the meter.
	meter.locked = true
	_hitbox.activate(damage, player.stats.ultimate_knockback, -1.0, true)
	var hits: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_inside_tree() or enemy.is_dead():
			continue
		var x: float = enemy.global_position.x
		if x < span.x or x > span.y:
			continue
		if _hitbox.try_hit(enemy.get_hurtbox()):
			hits += 1
	_hitbox.deactivate()
	meter.locked = false
	return hits


func _on_released(origin: Vector2, facing: int) -> void:
	_origin = origin
	_span = get_strike_range(origin)
	_destination = origin
	_destination.x = clampf(_span.y - RANGE_MARGIN - 100.0 if facing > 0 else _span.x + RANGE_MARGIN + 100.0, player.min_x, player.max_x)
	_cinematic_active = true
	_age = 0.0
	_impact_done = false
	player.ultimate_cinematic = true
	player.velocity = Vector2.ZERO
	(player.get_node("Visual") as UnitVisual).play_state(&"dash")
	if is_instance_valid(camera):
		_camera_was_processing = camera.is_processing()
		camera.set_process(false)
	_feedback = BattleFeedback.active
	if is_instance_valid(_feedback): _feedback.set_cinematic_scale(0.25)
	_layer = CanvasLayer.new()
	_layer.layer = SWEEP_LAYER
	_painting = UltimateCinematic.new()
	var canvas: Transform2D = player.get_viewport().get_canvas_transform()
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.is_dead() or enemy.global_position.x < _span.x or enemy.global_position.x > _span.y: continue
		_painting.marks.append(canvas * (enemy.global_position - Vector2(0, enemy.data.body_size.y * 0.55)))
		if _painting.marks.size() >= 8: break
	if _painting.marks.is_empty():
		for i: int in 5: _painting.marks.append(canvas * origin + Vector2((i - 2) * 150, -90 - (i % 2) * 50))
	_painting.blood_enabled = not is_instance_valid(_feedback) or _feedback.blood_enabled
	_layer.add_child(_painting)
	add_child(_layer)
	set_process(true)


## Real seconds; public so deterministic probes can inspect the actual timeline.
func advance_cinematic(seconds: float) -> void:
	if not _cinematic_active: return
	if not is_instance_valid(player) or player.get_health().is_dead():
		cancel_cinematic()
		return
	_age += seconds
	player.get_health().set_invulnerable_for(0.12)
	player.global_position = _origin.lerp(_destination, smoothstep(0.08, 0.46, _age))
	if is_instance_valid(_painting): _painting.show_time(_age)
	if not _impact_done and _age >= IMPACT_TIME:
		_impact_done = true
		var hits: int = strike(_origin, _span)
		if not _cinematic_active: return # Victory/scene teardown may cancel inside a damage signal.
		(player.get_node("Visual") as UnitVisual).play_ultimate_strike()
		if is_instance_valid(_feedback):
			_feedback.set_cinematic_scale(1.0)
			_feedback.hit_stop(minf(pause_seconds, 0.1))
			_feedback.shake(15.0, 0.32)
			_feedback.vibrate(90)
		AudioManager.play(&"flesh_heavy")
		released.emit(hits)
	if _age >= CINEMATIC_TIME: cancel_cinematic()


func cancel_cinematic() -> void:
	if not _cinematic_active: return
	_cinematic_active = false
	set_process(false)
	if is_instance_valid(player): player.finish_ultimate_cinematic()
	if is_instance_valid(camera): camera.set_process(_camera_was_processing)
	if is_instance_valid(_feedback):
		_feedback.set_cinematic_scale(1.0)
		_feedback.end_hit_stop()
	if is_instance_valid(_layer): _layer.queue_free()
	_layer = null
	_painting = null
