class_name WaveDirector
extends Node
## Runs a StageData: break -> spawn wave -> wait until cleared -> break -> ... -> stage_cleared.
## Enemies are counted through their `defeated` and `tree_exiting` signals (never by polling),
## so an enemy removed for any reason can never block wave completion. Two safety nets watch a running wave: a wave
## with nothing left to spawn and no living enemy for EMPTY_WAVE_GRACE seconds is completed anyway, and a wave whose
## enemies live on while nobody deals damage for STALL_WARNING_TIME seconds logs a warning (stall_detected) with its state.

signal wave_started(wave_number: int, total_waves: int)
signal wave_cleared(wave_number: int)
signal break_started(next_wave_number: int, duration: float)
signal remaining_changed(remaining: int)
signal stage_cleared
## Enemies are alive but nobody has dealt damage for STALL_WARNING_TIME seconds (also logged as a warning).
signal stall_detected(report: String)

enum Phase { IDLE, BREAK, SPAWNING, CLEARING, COMPLETE }

const SPAWN_RETRY_DELAY: float = 0.5
## Seconds a fully spawned wave may have no living enemy before it is completed anyway.
const EMPTY_WAVE_GRACE: float = 5.0
## Seconds without any damage dealt, while enemies are alive, before a stall is reported.
const STALL_WARNING_TIME: float = 30.0

@export var stage: StageData
@export var spawner: EnemySpawner
## If false, call start() yourself (e.g. after connecting signals).
@export var auto_start: bool = false

var _phase: Phase = Phase.IDLE
var _wave_index: int = 0
var _break_left: float = 0.0
var _spawn_timer: float = 0.0
var _queue: Array[EnemyData] = []
var _queue_delays: Array[float] = []
var _next_spawn: int = 0
var _tracked: Dictionary = {}
var _empty_time: float = 0.0
var _quiet_time: float = 0.0
var _stall_reported: bool = false


func _ready() -> void:
	if auto_start:
		start()


func _process(delta: float) -> void:
	tick(delta)


func start() -> void:
	if stage == null or stage.waves.is_empty():
		push_error("WaveDirector: no stage (or a stage without waves) assigned.")
		return
	if spawner == null:
		push_error("WaveDirector: no EnemySpawner assigned.")
		return
	_wave_index = 0
	_tracked.clear()
	_begin_break(stage.first_wave_delay)


## Halts spawning and breaks. A completed stage stays complete.
func stop() -> void:
	if _phase != Phase.COMPLETE:
		_phase = Phase.IDLE


func tick(delta: float) -> void:
	match _phase:
		Phase.BREAK:
			_break_left -= delta
			if _break_left <= 0.0:
				_start_wave()
		Phase.SPAWNING:
			_spawn_timer -= delta
			_spawn_due()
	if _phase == Phase.SPAWNING or _phase == Phase.CLEARING:
		_watch_wave(delta)


## Any hit by anyone (the battlefield forwards every reported hit): the fight is still going.
func note_damage() -> void:
	_quiet_time = 0.0
	_stall_reported = false


# --- Queries ----------------------------------------------------------------

func get_phase() -> Phase:
	return _phase


func is_complete() -> bool:
	return _phase == Phase.COMPLETE


func is_in_break() -> bool:
	return _phase == Phase.BREAK


func get_break_time_left() -> float:
	return maxf(_break_left, 0.0) if _phase == Phase.BREAK else 0.0


## 1-based wave number of the current (or upcoming, during a break) wave.
func get_current_wave() -> int:
	return _wave_index + 1


func get_total_waves() -> int:
	return stage.waves.size() if stage != null else 0


## Enemies of the current wave not yet spawned plus those spawned and still alive.
func get_remaining_count() -> int:
	return (_queue.size() - _next_spawn) + _tracked.size()


# --- Flow -------------------------------------------------------------------

func _begin_break(duration: float) -> void:
	_phase = Phase.BREAK
	_break_left = duration
	break_started.emit(_wave_index + 1, duration)


func _start_wave() -> void:
	_empty_time = 0.0
	_quiet_time = 0.0
	_stall_reported = false
	_build_queue(stage.waves[_wave_index])
	_phase = Phase.SPAWNING
	_spawn_timer = _queue_delays[0] if not _queue_delays.is_empty() else 0.0
	wave_started.emit(_wave_index + 1, stage.waves.size())
	remaining_changed.emit(get_remaining_count())
	_spawn_due()


func _build_queue(wave: WaveData) -> void:
	_queue.clear()
	_queue_delays.clear()
	_next_spawn = 0
	if wave == null:
		push_error("WaveDirector: wave %d is null; treating it as empty." % (_wave_index + 1))
		return
	for entry: WaveEntry in wave.entries:
		if entry == null or entry.enemy == null:
			push_error("WaveDirector: wave %d has an entry without enemy data; skipped." % (_wave_index + 1))
			continue
		for i: int in maxi(entry.count, 0):
			_queue.append(entry.enemy)
			_queue_delays.append(entry.start_delay if i == 0 else entry.spawn_interval)


## Spawns every enemy whose delay has elapsed (several per call if delta was large).
func _spawn_due() -> void:
	if not is_instance_valid(spawner):
		push_error("WaveDirector: spawner is missing; stopping the stage.")
		_phase = Phase.IDLE
		return
	while _phase == Phase.SPAWNING and _next_spawn < _queue.size() and _spawn_timer <= 0.0:
		var enemy: Enemy = spawner.spawn(_queue[_next_spawn])
		if enemy == null:
			# Spawner refused (e.g. enemy cap). Retry later; the enemy still counts as pending.
			_spawn_timer = SPAWN_RETRY_DELAY
			return
		_track(enemy)
		_next_spawn += 1
		if _next_spawn < _queue.size():
			_spawn_timer += _queue_delays[_next_spawn]
	if _phase == Phase.SPAWNING and _next_spawn >= _queue.size():
		_phase = Phase.CLEARING
		_check_wave_cleared()


func _track(enemy: Enemy) -> void:
	var id: int = enemy.get_instance_id()
	_tracked[id] = true
	enemy.defeated.connect(_on_enemy_defeated.bind(id))
	enemy.tree_exiting.connect(_release_enemy.bind(id))


func _on_enemy_defeated(_enemy: Enemy, id: int) -> void:
	_release_enemy(id)


## Called by whichever of `defeated` / `tree_exiting` fires first; later calls are no-ops.
func _release_enemy(id: int) -> void:
	if not _tracked.erase(id):
		return
	remaining_changed.emit(get_remaining_count())
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if _phase != Phase.CLEARING or not _tracked.is_empty():
		return
	var cleared_number: int = _wave_index + 1
	wave_cleared.emit(cleared_number)
	if _wave_index >= stage.waves.size() - 1:
		_phase = Phase.COMPLETE
		stage_cleared.emit()
	else:
		_wave_index += 1
		_begin_break(stage.break_duration)


# --- Safety nets ------------------------------------------------------------

func _watch_wave(delta: float) -> void:
	var living: Array[Enemy] = _living_enemies()
	if _phase == Phase.CLEARING and living.is_empty():
		_empty_time += delta
		if _empty_time >= EMPTY_WAVE_GRACE:
			push_warning("WaveDirector: wave %d had no living enemy for %.0f s; completing it (%d stale entries)." % [
					_wave_index + 1, EMPTY_WAVE_GRACE, _tracked.size()])
			_tracked.clear()
			remaining_changed.emit(get_remaining_count())
			_check_wave_cleared()
		return
	_empty_time = 0.0
	if living.is_empty():
		_quiet_time = 0.0
		return
	_quiet_time += delta
	if _quiet_time >= STALL_WARNING_TIME and not _stall_reported:
		_stall_reported = true
		var report: String = _stall_report(living)
		push_warning(report)
		stall_detected.emit(report)


## The tracked enemies still in the tree and alive.
func _living_enemies() -> Array[Enemy]:
	var living: Array[Enemy] = []
	for id: int in _tracked:
		var enemy: Enemy = instance_from_id(id) as Enemy
		if enemy != null and enemy.is_inside_tree() and not enemy.is_dead():
			living.append(enemy)
	return living


func _stall_report(living: Array[Enemy]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for enemy: Enemy in living:
		parts.append("%s at x %.0f" % [enemy.data.display_name if enemy.data != null else "?", enemy.global_position.x])
	return "WaveDirector: no damage dealt for %.0f s in wave %d/%d (%s): %d alive, %d still to spawn: %s." % [
			STALL_WARNING_TIME, _wave_index + 1, get_total_waves(), Phase.keys()[_phase], living.size(),
			_queue.size() - _next_spawn, ", ".join(parts)]
