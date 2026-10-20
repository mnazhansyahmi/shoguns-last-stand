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
## At most this many numbers are on screen; a new one pushes out the oldest.
const MAX_DAMAGE_NUMBERS: int = 6
const MAX_HIT_SPARKS: int = 24
## Blood bursts in the air at once, and stains kept on the ground (the oldest is cleaned away first).
const MAX_BLOOD_BURSTS: int = 20
const MAX_STAINS: int = 60
## Sparks appear this far below the hurtbox's top edge (the report position), at the body.
const SPARK_DROP: float = 40.0
const ENEMY_DAMAGE_COLOR: Color = InkPalette.PARCHMENT
const HEAVY_DAMAGE_COLOR: Color = InkPalette.GOLD_BRIGHT
const DEFENDER_DAMAGE_COLOR: Color = InkPalette.EMBER_TEXT

## Every validated hit, for systems that react to damage (the Ultimate meter).
signal hit_reported(victim: Node, hit: HitData)

static var active: BattleFeedback

@export var camera: Camera2D
## Where damage numbers are added (a world-space Node2D).
@export var numbers_parent: Node
## Where hit sparks are added (a world-space Node2D). No sparks without one.
@export var effects_parent: Node
## Where blood stains are added: a ground layer under the characters. No stains without one.
@export var stains_parent: Node

var screen_shake_enabled: bool = true
var vibration_enabled: bool = true
## The Blood setting: ink blood on hits and kills, and the stains it leaves.
var blood_enabled: bool = true

var _strength: float = 0.0
var _duration: float = 0.0
var _time_left: float = 0.0
var _hit_stop_end_msec: int = 0
var _live_sparks: int = 0
var _live_blood: int = 0


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
	blood_enabled = settings.blood
	if not screen_shake_enabled:
		_stop_shake()


func handle_hit(victim: Node, position: Vector2, hit: HitData) -> void:
	hit_reported.emit(victim, hit)
	spawn_damage_number(position, hit, victim is Enemy, victim)
	spawn_hit_spark(victim, position, hit)
	if not victim is VillageGate:
		spawn_blood(victim, position, hit)
	if victim is VillageGate:
		AudioManager.play(&"gate_hit")
		shake(5.0, 0.15)
	elif victim is Player:
		AudioManager.play(&"heavy_hit" if hit.heavy else &"hit", 0.9)
		_play_flesh(hit, 0.9)
		shake(10.0 if hit.heavy else 7.0, 0.2)
		vibrate(45)
	else:
		AudioManager.play(&"heavy_hit" if hit.heavy else &"hit", 1.15 if victim is Ally else 1.0)
		_play_flesh(hit, 1.15 if victim is Ally else 1.0)
		if hit.heavy:
			shake(6.0, 0.12)
		elif hit.killed:
			shake(3.0, 0.08)
		if hit.heavy and hit.source is Player:
			vibrate(20)
	if should_hit_stop(hit):
		hit_stop(HIT_STOP_SECONDS)


## Floating damage for a hit. Rapid hits on the same victim merge into one growing number; a new
## number is stacked above any it would overlap, and at most MAX_DAMAGE_NUMBERS are shown.
func spawn_damage_number(position: Vector2, hit: HitData, on_enemy: bool, victim: Node = null) -> DamageNumber:
	if not is_instance_valid(numbers_parent):
		return null
	var color: Color = DEFENDER_DAMAGE_COLOR
	if on_enemy:
		color = HEAVY_DAMAGE_COLOR if hit.heavy else ENEMY_DAMAGE_COLOR
	var scale_factor: float = 1.35 if hit.heavy else 1.0
	var victim_id: int = victim.get_instance_id() if is_instance_valid(victim) else 0
	if victim_id != 0:
		for child: Node in numbers_parent.get_children():
			var live: DamageNumber = child as DamageNumber
			if live != null and live.victim_id == victim_id and live.can_merge():
				live.merge(hit.damage, hit.heavy, color, scale_factor)
				return live
	var number: DamageNumber = DamageNumber.new()
	number.setup("", color, scale_factor)
	number.set_damage(hit.damage, hit.heavy)
	number.victim_id = victim_id
	_place_number(number, position)
	return number


## A floating text number that is not damage (e.g. "+28" for a heal).
func spawn_text_number(position: Vector2, text: String, color: Color) -> DamageNumber:
	if not is_instance_valid(numbers_parent):
		return null
	var number: DamageNumber = DamageNumber.new()
	number.setup(text, color, 1.0)
	_place_number(number, position)
	return number


## Adds a number at `position`, moved up until it clears the numbers already there, and drops
## the oldest ones beyond the cap.
func _place_number(number: DamageNumber, position: Vector2) -> void:
	var live: Array[DamageNumber] = []
	for child: Node in numbers_parent.get_children():
		var other: DamageNumber = child as DamageNumber
		if other != null and not other.is_queued_for_deletion():
			live.append(other)
	while live.size() >= MAX_DAMAGE_NUMBERS:
		var oldest: DamageNumber = live.pop_front()
		oldest.queue_free()
	var at: Vector2 = position
	var moved: bool = true
	while moved:
		moved = false
		for other: DamageNumber in live:
			if absf(other.global_position.x - at.x) < DamageNumber.SPACING * 2.8 and absf(other.global_position.y - at.y) < DamageNumber.SPACING:
				at.y = other.global_position.y - DamageNumber.SPACING
				moved = true
	numbers_parent.add_child(number)
	number.global_position = at


func spawn_hit_spark(victim: Node, position: Vector2, hit: HitData) -> HitSpark:
	if not is_instance_valid(effects_parent) or _live_sparks >= MAX_HIT_SPARKS:
		return null
	var target: HitSpark.Target = HitSpark.Target.DEFENDER
	if victim is Enemy:
		target = HitSpark.Target.ENEMY
	elif victim is VillageGate:
		target = HitSpark.Target.STRUCTURE
	var spark: HitSpark = HitSpark.new()
	spark.setup(signf(hit.knockback.x), hit.heavy, hit.killed, target)
	_live_sparks += 1
	spark.tree_exited.connect(_on_spark_exited)
	effects_parent.add_child(spark)
	spark.global_position = position + Vector2(0.0, SPARK_DROP)
	return spark


## The meat of a hit, layered on the metal of the blow: a wet slice and a low thump, heavier for a heavy blow, and the
## Spirit Slash's own deeper cut.
func _play_flesh(hit: HitData, pitch: float) -> void:
	AudioManager.play(flesh_sound(hit), pitch)


## Which flesh layer a hit gets.
static func flesh_sound(hit: HitData) -> StringName:
	if hit.spirit:
		return &"spirit_flesh"
	return &"flesh_heavy" if hit.heavy or hit.killed else &"flesh_hit"


## Ink blood where a hit lands, if the Blood setting is on: a spray and drops thrown along the blow (more for a heavy
## hit, a kill and the Spirit Slash) and a stain left on the ground (a bigger one for a heavy hit or a kill).
func spawn_blood(victim: Node, position: Vector2, hit: HitData) -> InkBlood:
	if not blood_enabled or not is_instance_valid(effects_parent) or _live_blood >= MAX_BLOOD_BURSTS:
		return null
	var feet: Vector2 = position + Vector2(0.0, SPARK_DROP + 60.0)
	var node: Node2D = victim as Node2D
	if node != null:
		feet = node.global_position
	var at: Vector2 = position + Vector2(0.0, SPARK_DROP)
	var direction: float = signf(hit.knockback.x)
	var burst: InkBlood = InkBlood.new()
	burst.setup(direction, feet.y - at.y, hit.heavy, hit.spirit, hit.killed)
	_live_blood += 1
	burst.tree_exited.connect(_on_blood_exited)
	effects_parent.add_child(burst)
	burst.global_position = at
	_spawn_stain(feet, direction, 2.0 if hit.killed or hit.heavy or hit.spirit else 1.0)
	return burst


func _spawn_stain(feet: Vector2, direction: float, size: float) -> BloodStain:
	if not is_instance_valid(stains_parent):
		return null
	var live: Array[Node] = stains_parent.get_children()
	while live.size() >= MAX_STAINS:
		var oldest: Node = live.pop_front()
		stains_parent.remove_child(oldest)
		oldest.queue_free()
	var stain: BloodStain = BloodStain.new()
	stain.setup(size, direction)
	stains_parent.add_child(stain)
	stain.global_position = feet + Vector2(direction * randf_range(10.0, 50.0), randf_range(-2.0, 8.0))
	return stain


func _on_blood_exited() -> void:
	_live_blood = maxi(_live_blood - 1, 0)


func _on_spark_exited() -> void:
	_live_sparks = maxi(_live_sparks - 1, 0)


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
