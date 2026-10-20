class_name UpgradeApplier
extends RefCounted
## Builds upgraded copies of base stats for a battle. Shared .tres resources are never modified.


## Allies on the field at the start: six, plus one for every stage cleared, up to eleven.
const BASE_ALLY_CAP: int = 6
const MAX_STAGE_ALLY_CAP: int = 11
## No skill upgrade takes more than this off a cooldown (or the Ultimate's charge needed).
const MAX_SKILL_REDUCTION: float = 0.4


## How many allies may stand at once: the stage-clear cap plus the Command upgrade's levels.
static func build_ally_cap(progress: PlayerProgress, catalog: UpgradeCatalog) -> int:
	var cleared: int = progress.stages_cleared.size() if progress != null else 0
	var cap: int = clampi(BASE_ALLY_CAP + cleared, BASE_ALLY_CAP, MAX_STAGE_ALLY_CAP)
	return cap + roundi(get_bonus(progress, catalog, UpgradeData.Target.ARMY, UpgradeData.Stat.ALLY_CAP))


static func get_bonus(progress: PlayerProgress, catalog: UpgradeCatalog, target: UpgradeData.Target,
		stat: UpgradeData.Stat, ally_id: String = "") -> float:
	if progress == null or catalog == null:
		return 0.0
	var total: float = 0.0
	for upgrade: UpgradeData in catalog.upgrades:
		if upgrade == null or upgrade.target != target or upgrade.stat != stat:
			continue
		if target == UpgradeData.Target.ALLY and upgrade.ally_id != ally_id:
			continue
		total += upgrade.get_total_bonus(progress.get_upgrade_level(upgrade.id))
	return total


static func build_player_stats(base: PlayerStats, progress: PlayerProgress, catalog: UpgradeCatalog) -> PlayerStats:
	var stats: PlayerStats = base.duplicate() as PlayerStats
	stats.max_health += get_bonus(progress, catalog, UpgradeData.Target.SAMURAI, UpgradeData.Stat.MAX_HEALTH)
	stats.base_damage += get_bonus(progress, catalog, UpgradeData.Target.SAMURAI, UpgradeData.Stat.DAMAGE)
	# Skill upgrades: percent shorter cooldowns (and less charge needed for the Ultimate), never more than 40%.
	stats.dash_cooldown *= 1.0 - _percent_off(progress, catalog, UpgradeData.Stat.DASH_COOLDOWN)
	stats.spirit_slash_cooldown *= 1.0 - _percent_off(progress, catalog, UpgradeData.Stat.SLASH_COOLDOWN)
	stats.ultimate_charge_max *= 1.0 - _percent_off(progress, catalog, UpgradeData.Stat.ULTIMATE_CHARGE)
	return stats


## The fraction (0..MAX_SKILL_REDUCTION) a skill upgrade takes off its cooldown or charge.
static func _percent_off(progress: PlayerProgress, catalog: UpgradeCatalog, stat: UpgradeData.Stat) -> float:
	return clampf(get_bonus(progress, catalog, UpgradeData.Target.SAMURAI, stat) / 100.0, 0.0, MAX_SKILL_REDUCTION)


static func build_ally_data(base: AllyData, progress: PlayerProgress, catalog: UpgradeCatalog) -> AllyData:
	var data: AllyData = base.duplicate() as AllyData
	data.max_health += get_bonus(progress, catalog, UpgradeData.Target.ALLY, UpgradeData.Stat.MAX_HEALTH, base.id)
	data.attack_damage += get_bonus(progress, catalog, UpgradeData.Target.ALLY, UpgradeData.Stat.DAMAGE, base.id)
	return data


## The Spirit Energy pool: the base maximum plus the Spirit Capacity upgrade's levels.
static func build_spirit_max(base_max: float, progress: PlayerProgress, catalog: UpgradeCatalog) -> float:
	return base_max + get_bonus(progress, catalog, UpgradeData.Target.SPIRIT_ENERGY, UpgradeData.Stat.MAX_ENERGY)


static func build_spirit_regen(base_regen: float, progress: PlayerProgress, catalog: UpgradeCatalog) -> float:
	return base_regen + get_bonus(progress, catalog, UpgradeData.Target.SPIRIT_ENERGY, UpgradeData.Stat.REGEN)
