class_name UltimateMeter
extends Node
## The samurai's Ultimate charge. It fills as the battle is fought: damage the samurai deals,
## damage his allies deal (a smaller share) and damage he takes. When full the Ultimate can be
## used; using it empties the meter. It does not carry over between battles. Gameplay only reads
## the ratio and listens to the signals (HUD, touch button), so the numbers live in PlayerStats.

signal charge_changed(ratio: float)
## Emitted once each time the meter fills.
signal became_ready
## Emitted when the Ultimate is spent.
signal used

## Charge needed to use the Ultimate (in "charge points", see the rates below).
@export var max_charge: float = 100.0
@export var per_damage_dealt: float = 0.1
@export var per_damage_taken: float = 0.25
## Damage dealt by allies counts this fraction of the samurai's own.
@export var ally_share: float = 0.3

var current: float = 0.0
## While true no charge is gained (the Ultimate's own hits must not refill the meter).
var locked: bool = false


## Takes the tuning from the samurai's stats.
func configure(stats: PlayerStats) -> void:
	max_charge = maxf(stats.ultimate_charge_max, 1.0)
	per_damage_dealt = stats.ultimate_charge_per_damage_dealt
	per_damage_taken = stats.ultimate_charge_per_damage_taken
	ally_share = stats.ultimate_ally_share
	current = minf(current, max_charge)
	charge_changed.emit(get_ratio())


func get_ratio() -> float:
	return clampf(current / maxf(max_charge, 0.001), 0.0, 1.0)


func is_ready() -> bool:
	return current >= max_charge


## Damage the samurai (or, with by_ally, one of his allies) dealt to an enemy.
func add_damage_dealt(amount: float, by_ally: bool = false) -> void:
	add_charge(amount * per_damage_dealt * (ally_share if by_ally else 1.0))


## Damage the samurai took.
func add_damage_taken(amount: float) -> void:
	add_charge(amount * per_damage_taken)


func add_charge(amount: float) -> void:
	if locked or amount <= 0.0 or is_ready():
		return
	current = minf(current + amount, max_charge)
	charge_changed.emit(get_ratio())
	if is_ready():
		became_ready.emit()


## Spends a full meter. Returns false (and spends nothing) if it is not full.
func try_consume() -> bool:
	if not is_ready():
		return false
	current = 0.0
	charge_changed.emit(0.0)
	used.emit()
	return true


func reset() -> void:
	current = 0.0
	charge_changed.emit(0.0)
