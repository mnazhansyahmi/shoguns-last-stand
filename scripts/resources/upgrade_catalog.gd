class_name UpgradeCatalog
extends Resource
## All upgrades offered in the upgrade menu, in display order.

@export var upgrades: Array[UpgradeData] = []


func find(id: String) -> UpgradeData:
	for upgrade: UpgradeData in upgrades:
		if upgrade != null and upgrade.id == id:
			return upgrade
	return null
