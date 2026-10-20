class_name UpgradeTabs
extends RefCounted
## Which tab of the upgrade shop an upgrade is on, and which picture it wears.

enum Tab { SAMURAI, SKILLS, ALLIES, ARMY_SPIRIT }

const NAMES: PackedStringArray = ["Samurai", "Skills", "Allies", "Army & Spirit"]


static func tab_for(upgrade: UpgradeData) -> Tab:
	match upgrade.target:
		UpgradeData.Target.ALLY:
			return Tab.ALLIES
		UpgradeData.Target.ARMY, UpgradeData.Target.SPIRIT_ENERGY:
			return Tab.ARMY_SPIRIT
	match upgrade.stat:
		UpgradeData.Stat.DASH_COOLDOWN, UpgradeData.Stat.SLASH_COOLDOWN, UpgradeData.Stat.ULTIMATE_CHARGE:
			return Tab.SKILLS
	return Tab.SAMURAI


## The skill icon of an upgrade, or -1 when it wears a portrait of a character instead (the samurai's own stats and
## every ally's).
static func icon_for(upgrade: UpgradeData) -> int:
	match upgrade.stat:
		UpgradeData.Stat.DASH_COOLDOWN:
			return UpgradeIcon.Kind.DASH
		UpgradeData.Stat.SLASH_COOLDOWN:
			return UpgradeIcon.Kind.SPIRIT_SLASH
		UpgradeData.Stat.ULTIMATE_CHARGE:
			return UpgradeIcon.Kind.ULTIMATE
		UpgradeData.Stat.ALLY_CAP:
			return UpgradeIcon.Kind.COMMAND
		UpgradeData.Stat.REGEN:
			return UpgradeIcon.Kind.REGEN
		UpgradeData.Stat.MAX_ENERGY:
			return UpgradeIcon.Kind.SPIRIT_CAPACITY
	return -1
