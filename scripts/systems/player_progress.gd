class_name PlayerProgress
extends RefCounted
## Persistent player progression (what the save file stores).

## Level L needs XP_PER_LEVEL_STEP × L × (L - 1) / 2 total XP: 100, 300, 600, 1000, ...
const XP_PER_LEVEL_STEP: int = 100
const MAX_LEVEL: int = 99

var gold: int = 0
var xp: int = 0
var upgrade_levels: Dictionary = {}
var stages_cleared: Array[String] = []
var battles_played: int = 0
var victories: int = 0
var defeats: int = 0
var enemies_defeated: int = 0
## The stage of the last battle played (win or lose): what Continue offers once every stage is cleared.
var last_stage_id: String = ""


static func xp_for_level(level: int) -> int:
	return XP_PER_LEVEL_STEP * level * (level - 1) / 2


func get_level() -> int:
	var level: int = 1
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
	return level


## Adds XP and returns how many levels were gained.
func add_xp(amount: int) -> int:
	var before: int = get_level()
	xp += maxi(amount, 0)
	return get_level() - before


func get_upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))


func set_upgrade_level(id: String, level: int) -> void:
	upgrade_levels[id] = maxi(level, 0)


func is_stage_cleared(stage_id: String) -> bool:
	return stages_cleared.has(stage_id)


## Applies a finished battle. Returns the number of levels gained.
func record_battle(reward: BattleReward, stage_id: String) -> int:
	gold += reward.gold
	battles_played += 1
	enemies_defeated += reward.enemies_defeated
	if not stage_id.is_empty():
		last_stage_id = stage_id
	if reward.victory:
		victories += 1
		if not stage_id.is_empty() and not is_stage_cleared(stage_id):
			stages_cleared.append(stage_id)
	else:
		defeats += 1
	return add_xp(reward.xp)


func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"xp": xp,
		"level": get_level(),
		"upgrades": upgrade_levels.duplicate(),
		"stages_cleared": Array(stages_cleared),
		"last_stage": last_stage_id,
		"stats": {
			"battles": battles_played,
			"victories": victories,
			"defeats": defeats,
			"enemies_defeated": enemies_defeated,
		},
	}


func duplicate_progress() -> PlayerProgress:
	var copy: PlayerProgress = PlayerProgress.new()
	copy.gold = gold
	copy.xp = xp
	copy.upgrade_levels = upgrade_levels.duplicate()
	copy.stages_cleared = stages_cleared.duplicate()
	copy.battles_played = battles_played
	copy.victories = victories
	copy.defeats = defeats
	copy.enemies_defeated = enemies_defeated
	copy.last_stage_id = last_stage_id
	return copy
