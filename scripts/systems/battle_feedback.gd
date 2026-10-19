class_name BattleFeedback
extends Node
## Hit feedback for one battle: hit sounds, floating damage numbers, hit-stop, screen shake and
## phone vibration. HurtboxComponent reports every validated hit through the static report_hit();
## the active BattleFeedback (the current battlefield's) turns it into feedback.
## Runs with PROCESS_MODE_ALWAYS so a hit-stop always ends, even if the game pauses mid-freeze.

## A heavy hit or a kill freezes the game this long (real time).
const HIT_STOP_SECONDS: float = 0.05
## Engine.time_scale during hit-stop: a near-freeze (0 would make physics deltas zero).
const HIT_STOP_TIME_SCALE: float = 0.02
const MAX_DAMAGE_NUMBERS: int = 40
const ENEMY_DAMAGE_COLOR: Color = Color(1.0, 0.95, 0.75)
const HEAVY_DAMAGE_COLOR: Color = Color(1.0, 0.62, 0.2)
const DEFENDER_DAMAGE_COLOR: Color = Color(1.0, 0.38, 0.32)

static var active: BattleFeedback

@export var camera: Camera2D
## Where damage numbers are added (a world-space Node2D).
@export var numbers_parent: Node

var screen_shake_enabled: bool = true
var vibration_enabled: bool = true

var _strength: float = 0.0
var _duration: float = 0.0
var _time_left: float = 0.0
var _hit_stop_end_msec: int = 0


## Called by HurtboxComponent after a hit is applied. No-op outside a battle.
static func report_hit(victim: Node, position: Vector2, hit: HitData) -> void:
	if is_instance_valid(active):
		active.handle_hit(victim, position, hit)


static func should_hit_stop(hit: HitData) -> bool:
	return hit.heavy or hit.killed


## Vibration needs the setting on and a phone/tablet (desktop has no motor).
static func can_vibrate(setting_enabled: bool, on_mobile: bool) -> bool:
	return setting_enabled and on_mobile


func _enter_tree() -> void:
	active = self


func _exit_tree() -> void:
	if active == self:
		active = null
	end_hit_stop()
	_stop_shake()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure(settings: GameSettings) -> void:
	screen_shake_enabled = settings.screen_shake
	vibration_enabled = settings.vibration
	if not screen_shake_enabled:
		_stop_shake()


func handle_hit(victim: Node, position: Vector2, hit: HitData) -> void:
	spawn_damage_number(position, hit, victim is Enemy)
	if victim is VillageGate:
		AudioManager.play(&"gate_hit")
		shake(5.0, 0.15)
	elif victim is Player:
		AudioManager.play(&"heavy_hit" if hit.heavy else &"hit", 0.9)
		shake(10.0 if hit.heavy else 7.0, 0.2)
		vibrate(45)
	else:
		AudioManager.play(&"heavy_hit" if hit.heavy else &"hit", 1.15 if victim is Ally else 1.0)
		if hit.heavy:
			shake(6.0, 0.12)
		elif hit.killed:
			shake(3.0, 0.08)
		if hit.heavy and hit.source is Player:
			vibrate(20)
	if should_hit_stop(hit):
		hit_stop(HIT_STOP_SECONDS)


func spawn_damage_number(position: Vector2, hit: HitData, on_enemy: bool) -> DamageNumber:
	if not is_instance_valid(numbers_parent) or numbers_parent.get_child_count() >= MAX_DAMAGE_NUMBERS:
		return null
	var color: Color = DEFENDER_DAMAGE_COLOR
	if on_enemy:
		color = HEAVY_DAMAGE_COLOR if hit.heavy else ENEMY_DAMAGE_COLOR
	var label: String = str(roundi(hit.damage)) + ("!" if hit.heavy else "")
	var number: DamageNumber = DamageNumber.new()
	number.setup(label, color, 1.35 if hit.heavy else 1.0)
	numbers_parent.add_child(number)
	number.global_position = position
	return number


func hit_stop(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_hit_stop_end_msec = maxi(_hit_stop_end_msec, Time.get_ticks_msec() + int(seconds * 1000.0))
	Engine.time_scale = HIT_STOP_TIME_SCALE


func end_hit_stop() -> void:
	if _hit_stop_end_msec == 0:
		return
	_hit_stop_end_msec = 0
	Engine.time_scale = 1.0


func is_hit_stopped() -> bool:
	return _hit_stop_end_msec != 0


func shake(strength: float, duration: float) -> void:
	if not screen_shake_enabled or duration <= 0.0:
		return
	_strength = maxf(_strength * (_time_left / maxf(_duration, 0.001)), strength)
	_duration = duration
	_time_left = duration


func vibrate(duration_ms: int) -> void:
	if can_vibrate(vibration_enabled, OS.has_feature("mobile")):
		Input.vibrate_handheld(duration_ms)


func is_shaking() -> bool:
	return _time_left > 0.0


func _process(delta: float) -> void:
	if _hit_stop_end_msec != 0 and Time.get_ticks_msec() >= _hit_stop_end_msec:
		end_hit_stop()
	if get_tree().paused:
		if is_shaking():
			_stop_shake()
		return
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_stop_shake()
		return
	if is_instance_valid(camera):
		var falloff: float = _time_left / _duration
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * falloff


func _stop_shake() -> void:
	_time_left = 0.0
	_strength = 0.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
