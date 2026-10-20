class_name SpiritEnergy
extends Node
## Spirit Energy pool used to summon allies. Regenerates over time; pauses with the tree.

signal energy_changed(current: float, maximum: float)

## The pool: 200 (the Spirit Capacity upgrade adds 25 per level, up to four levels).
@export var max_energy: float = 200.0
@export var regen_per_second: float = 5.0
@export var starting_energy: float = 50.0

var current: float = 0.0


func _ready() -> void:
	set_energy(starting_energy)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if current < max_energy and regen_per_second > 0.0:
		set_energy(current + regen_per_second * delta)


func set_energy(value: float) -> void:
	var clamped: float = clampf(value, 0.0, max_energy)
	if clamped == current:
		return
	current = clamped
	energy_changed.emit(current, max_energy)


func can_afford(cost: float) -> bool:
	return cost >= 0.0 and current >= cost


## Spends `cost` if affordable. Returns false (and spends nothing) otherwise.
func try_spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	set_energy(current - cost)
	return true
