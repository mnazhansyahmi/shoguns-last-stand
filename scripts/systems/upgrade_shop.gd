class_name UpgradeShop
extends RefCounted
## Buying upgrade levels with gold.

enum Result { OK, NOT_ENOUGH_GOLD, MAX_LEVEL, INVALID_UPGRADE, LOCKED }


## Buys the next level of `upgrade`. Gold and level change only on success.
static func purchase(progress: PlayerProgress, upgrade: UpgradeData) -> Result:
	if progress == null or upgrade == null or upgrade.id.is_empty():
		return Result.INVALID_UPGRADE
	var level: int = progress.get_upgrade_level(upgrade.id)
	if upgrade.is_maxed(level):
		return Result.MAX_LEVEL
	if not upgrade.is_available(progress):
		return Result.LOCKED
	var cost: int = upgrade.get_cost(level)
	if progress.gold < cost:
		return Result.NOT_ENOUGH_GOLD
	progress.gold -= cost
	progress.set_upgrade_level(upgrade.id, level + 1)
	return Result.OK
