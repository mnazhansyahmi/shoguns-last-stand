class_name StageData
extends Resource
## A battle: an ordered list of waves with breaks between them.

## Stable key stored in the save file (stages_cleared).
@export var stage_id: String = "stage"
@export var display_name: String = "Stage"
@export var waves: Array[WaveData] = []
## Delay before wave 1 starts.
@export var first_wave_delay: float = 3.0
## Break between a cleared wave and the next one.
@export var break_duration: float = 5.0

@export_group("Rewards")
@export var clear_gold_bonus: int = 100
@export var clear_xp_bonus: int = 50
## Share of kill rewards kept on defeat (no clear bonus).
@export_range(0.0, 1.0) var defeat_reward_ratio: float = 0.5
## Gold multiplier once this stage has been cleared before (replays pay less; XP is unchanged).
@export_range(0.0, 1.0) var replay_gold_multiplier: float = 0.5

## Short line shown on the stage select screen.
@export_multiline var description: String = ""


func get_enemy_total() -> int:
	var total: int = 0
	for wave: WaveData in waves:
		if wave != null:
			total += wave.get_enemy_count()
	return total


## How many of `enemy` the whole stage spawns.
func count_enemy(enemy: EnemyData) -> int:
	var total: int = 0
	for wave: WaveData in waves:
		if wave == null:
			continue
		for entry: WaveEntry in wave.entries:
			if entry != null and entry.enemy == enemy:
				total += maxi(entry.count, 0)
	return total


## Gold for killing everything and winning, before any replay reduction.
func get_full_clear_gold() -> int:
	var total: int = maxi(clear_gold_bonus, 0)
	for wave: WaveData in waves:
		if wave == null:
			continue
		for entry: WaveEntry in wave.entries:
			if entry != null and entry.enemy != null:
				total += maxi(entry.count, 0) * maxi(entry.enemy.gold_reward, 0)
	return total
