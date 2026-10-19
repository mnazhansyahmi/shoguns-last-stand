class_name SummonManager
extends Node2D
## Validates and performs ally summons near this node (placed in front of the gate).
## Checks, in order: slot, unit cap, cooldown, energy, spawn position. Energy is only spent on success.

signal ally_summoned(ally: Ally, slot: int)
signal summon_failed(slot: int, result: Result)
signal ally_count_changed(count: int, maximum: int)

enum Result { OK, INVALID_SLOT, MAX_UNITS, ON_COOLDOWN, NOT_ENOUGH_ENERGY, NO_VALID_POSITION }

const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const POSITION_STEP: float = 40.0
const POSITION_ATTEMPTS: int = 5

## Slot index = summon key - 1.
@export var ally_slots: Array[AllyData] = []
@export var energy: SpiritEnergy
## Where summoned allies are parented. Defaults to this node's parent.
@export var container: Node
@export var max_allies: int = 6
## Valid world x range for spawning.
@export var min_x: float = 200.0
@export var max_x: float = 1750.0
## A spawn point closer than this to a living enemy is rejected.
@export var enemy_clearance: float = 50.0
@export var spawn_jitter_x: float = 30.0

var _cooldowns: Array[float] = []
var _tracked_allies: Dictionary = {}


func _ready() -> void:
	_sync_cooldown_slots()
	if energy == null:
		push_error("SummonManager: no SpiritEnergy assigned; summons will be rejected.")


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	for i: int in _cooldowns.size():
		_cooldowns[i] = maxf(_cooldowns[i] - delta, 0.0)


func request_summon(slot: int) -> Result:
	var result: Result = _validate(slot)
	var spawn_x: float = NAN
	if result == Result.OK:
		spawn_x = _find_spawn_x()
		if is_nan(spawn_x):
			result = Result.NO_VALID_POSITION
	if result == Result.OK and not energy.try_spend(ally_slots[slot].cost):
		result = Result.NOT_ENOUGH_ENERGY
	if result != Result.OK:
		summon_failed.emit(slot, result)
		return result
	_spawn(slot, spawn_x)
	return Result.OK


func get_slot_count() -> int:
	return ally_slots.size()


func get_slot_data(slot: int) -> AllyData:
	return ally_slots[slot] if slot >= 0 and slot < ally_slots.size() else null


func get_cooldown_left(slot: int) -> float:
	return _cooldowns[slot] if slot >= 0 and slot < _cooldowns.size() else 0.0


func get_ally_count() -> int:
	return _tracked_allies.size()


static func describe(result: Result) -> String:
	match result:
		Result.OK:
			return "Summoned"
		Result.INVALID_SLOT:
			return "No ally in that slot"
		Result.MAX_UNITS:
			return "Too many allies on the field"
		Result.ON_COOLDOWN:
			return "Summon on cooldown"
		Result.NOT_ENOUGH_ENERGY:
			return "Not enough Spirit Energy"
		Result.NO_VALID_POSITION:
			return "No room to summon - enemies at the gate"
	return "Summon failed"


func _validate(slot: int) -> Result:
	if get_slot_data(slot) == null:
		return Result.INVALID_SLOT
	if _tracked_allies.size() >= max_allies:
		return Result.MAX_UNITS
	if get_cooldown_left(slot) > 0.0:
		return Result.ON_COOLDOWN
	if not is_instance_valid(energy) or not energy.can_afford(ally_slots[slot].cost):
		return Result.NOT_ENOUGH_ENERGY
	return Result.OK


## Tries the base point, then alternates outward. Returns NAN if every candidate is blocked.
func _find_spawn_x() -> float:
	var base_x: float = global_position.x + randf_range(-spawn_jitter_x, spawn_jitter_x)
	for attempt: int in POSITION_ATTEMPTS:
		var step_index: int = (attempt + 1) / 2
		var sign_value: float = 1.0 if attempt % 2 == 1 else -1.0
		var x: float = base_x + sign_value * step_index * POSITION_STEP
		if x < min_x or x > max_x:
			continue
		if _is_clear_of_enemies(x):
			return x
	return NAN


func _is_clear_of_enemies(x: float) -> bool:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy != null and not enemy.is_dead() and absf(enemy.global_position.x - x) < enemy_clearance:
			return false
	return true


func _spawn(slot: int, spawn_x: float) -> void:
	var data: AllyData = ally_slots[slot]
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(data, spawn_x)
	var parent: Node = container if is_instance_valid(container) else get_parent()
	parent.add_child(ally)
	ally.global_position = Vector2(spawn_x, global_position.y)
	var id: int = ally.get_instance_id()
	_tracked_allies[id] = true
	# Either signal frees the slot; whichever comes first wins, the other is a no-op.
	ally.defeated.connect(_on_ally_defeated.bind(id))
	ally.tree_exiting.connect(_release_ally.bind(id))
	_sync_cooldown_slots()
	_cooldowns[slot] = data.summon_cooldown
	ally_summoned.emit(ally, slot)
	ally_count_changed.emit(_tracked_allies.size(), max_allies)


## Keeps one cooldown entry per slot, even if ally_slots changed after _ready.
func _sync_cooldown_slots() -> void:
	var old_size: int = _cooldowns.size()
	if old_size == ally_slots.size():
		return
	_cooldowns.resize(ally_slots.size())
	for i: int in range(old_size, _cooldowns.size()):
		_cooldowns[i] = 0.0


func _on_ally_defeated(_ally: Ally, id: int) -> void:
	_release_ally(id)


func _release_ally(id: int) -> void:
	if _tracked_allies.erase(id):
		ally_count_changed.emit(_tracked_allies.size(), max_allies)
