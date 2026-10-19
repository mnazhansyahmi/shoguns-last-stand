class_name UpgradeApplier
extends RefCounted
## Builds upgraded copies of base stats for a battle. Shared .tres resources are never modified.


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
	return stats


static func build_ally_data(base: AllyData, progress: PlayerProgress, catalog: UpgradeCatalog) -> AllyData:
	var data: AllyData = base.duplicate() as AllyData
	data.max_health += get_bonus(progress, catalog, UpgradeData.Target.ALLY, UpgradeData.Stat.MAX_HEALTH, base.id)
	data.attack_damage += get_bonus(progress, catalog, UpgradeData.Target.ALLY, UpgradeData.Stat.DAMAGE, base.id)
	return data


static func build_spirit_regen(base_regen: float, progress: PlayerProgress, catalog: UpgradeCatalog) -> float:
	return base_regen + get_bonus(progress, catalog, UpgradeData.Target.SPIRIT_ENERGY, UpgradeData.Stat.REGEN)
