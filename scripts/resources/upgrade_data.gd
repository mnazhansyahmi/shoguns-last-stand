class_name UpgradeData
extends Resource
## One purchasable upgrade with levels. Bonus = amount_per_level × level.
## Cost of the next level = base_cost × cost_growth^current_level (rounded to 5 gold).

enum Target { SAMURAI, ALLY, SPIRIT_ENERGY, ARMY }
## ALLY_CAP: more allies on the field (ARMY). The cooldown and charge stats are in PERCENT per level (SAMURAI):
## the dash and spirit slash cooldowns and the Ultimate's charge needed get that much shorter. MAX_ENERGY: a bigger
## Spirit Energy pool (SPIRIT_ENERGY).
enum Stat { MAX_HEALTH, DAMAGE, REGEN, ALLY_CAP, DASH_COOLDOWN, SLASH_COOLDOWN, ULTIMATE_CHARGE, MAX_ENERGY }

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
## Shown in menus, e.g. "+%s HP". Receives the formatted bonus.
@export var effect_format: String = "+%s"


func is_maxed(level: int) -> bool:
	return level >= max_level


## Gold needed to go from `current_level` to the next level, or -1 when maxed.
func get_cost(current_level: int) -> int:
	if is_maxed(current_level):
		return -1
	var raw: float = base_cost * pow(cost_growth, maxi(current_level, 0))
	return maxi(roundi(raw / 5.0) * 5, 5)


func get_total_bonus(level: int) -> float:
	return amount_per_level * clampi(level, 0, max_level)


func describe_bonus(level: int) -> String:
	var bonus: float = get_total_bonus(level)
	var text: String = str(roundi(bonus)) if is_equal_approx(bonus, roundf(bonus)) else "%.1f" % bonus
	return effect_format % text
