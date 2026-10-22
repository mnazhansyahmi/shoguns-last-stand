class_name UpgradeData
extends Resource
## One purchasable upgrade with levels. Bonus = amount_per_level × level.
## Cost of the next level = base_cost × cost_growth^current_level (rounded to 5 gold).
## Extended tiers use their own base and growth after region_1_cap, keeping shipped prices intact.

enum Target { SAMURAI, ALLY, SPIRIT_ENERGY, ARMY, GATE }
## ALLY_CAP: more allies on the field (ARMY). The cooldown and charge stats are in PERCENT per level (SAMURAI):
## the dash and spirit slash cooldowns and the Ultimate's charge needed get that much shorter. MAX_ENERGY: a bigger
## Spirit Energy pool (SPIRIT_ENERGY).
enum Stat { MAX_HEALTH, DAMAGE, REGEN, ALLY_CAP, DASH_COOLDOWN, SLASH_COOLDOWN, ULTIMATE_CHARGE, MAX_ENERGY, BOW_DAMAGE, WAR_CRY_DURATION, ARMOUR, FIRE_RESISTANCE }

## Stable key stored in the save file. Never rename once shipped.
@export var id: String = ""
@export var display_name: String = "Upgrade"
@export var target: Target = Target.SAMURAI
## For Target.ALLY: which AllyData.id this upgrade affects.
@export var ally_id: String = ""
@export var stat: Stat = Stat.MAX_HEALTH
@export var amount_per_level: float = 10.0
@export var max_level: int = 5
@export var base_cost: int = 100
@export var cost_growth: float = 1.5
## Preserve shipped prices up to this cap. Additional tiers unlock after Region 1.
@export var region_1_cap: int = 0
@export var region_2_base_cost: int = 500
@export var region_2_cost_growth: float = 1.35
## For wholly new upgrades. Existing tiers do not acquire this requirement.
@export var unlock_stage_id: String = ""
## Clear milestones for successive Region 2 tiers. Empty extended tiers default
## to stages 6 and 9; wholly new upgrades may specify all four milestones.
@export var region_2_unlock_stages: PackedInt32Array = PackedInt32Array()
## Shown in menus, e.g. "+%s HP". Receives the formatted bonus.
@export var effect_format: String = "+%s"


func is_maxed(level: int) -> bool:
	return level >= max_level


## Gold needed to go from `current_level` to the next level, or -1 when maxed.
func get_cost(current_level: int) -> int:
	if is_maxed(current_level):
		return -1
	var raw: float = base_cost * pow(cost_growth, maxi(current_level, 0))
	if region_1_cap > 0 and current_level >= region_1_cap:
		raw = region_2_base_cost * pow(region_2_cost_growth, current_level - region_1_cap)
	return maxi(roundi(raw / 5.0) * 5, 5)


func required_stage(current_level: int) -> String:
	var old_cap: int = original_cap()
	if current_level < old_cap:
		var next: int = current_level + 1
		if next <= 2: return ""
		return "stage_%d" % (2 if next == 3 else (4 if next == 4 else 5))
	var milestones: PackedInt32Array = region_2_unlock_stages
	if milestones.is_empty():
		if region_1_cap == 0: return unlock_stage_id
		milestones = PackedInt32Array([6, 9])
	return "stage_%d" % milestones[mini(current_level - old_cap, milestones.size() - 1)]


func original_cap() -> int:
	if not unlock_stage_id.is_empty(): return 0
	return region_1_cap if region_1_cap > 0 else max_level


## Purchase cap only: never used to clamp owned bonuses or rewrite a save.
func available_max_level(progress: PlayerProgress) -> int:
	if progress == null: return 0
	var cleared: Dictionary = {}
	for stage: String in progress.stages_cleared: cleared[stage] = true
	var allowed: int = 0
	for level: int in max_level:
		var requirement: String = required_stage(level)
		var count: int = int(requirement.trim_prefix("stage_")) if not requirement.is_empty() else 0
		if cleared.size() < count: break
		allowed = level + 1
	return allowed


func is_available(progress: PlayerProgress) -> bool:
	if progress == null:
		return false
	var owned: int = progress.get_upgrade_level(id)
	return is_maxed(owned) or owned < available_max_level(progress)


func get_total_bonus(level: int) -> float:
	return amount_per_level * clampi(level, 0, max_level)


func describe_bonus(level: int) -> String:
	var bonus: float = get_total_bonus(level)
	var text: String = str(roundi(bonus)) if is_equal_approx(bonus, roundf(bonus)) else "%.1f" % bonus
	return effect_format % text
