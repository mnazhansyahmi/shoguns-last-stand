extends "res://tests/test_case.gd"
## Parts 2 and 3 of the playtest feedback: the cooldown upgrades (dash, spirit slash, Ultimate charge) and the
## two new skills, War Cry (key Q) and Bow (key E), with their unlocks, effects, cooldowns and touch buttons.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const BASE_STATS: PlayerStats = preload("res://data/player/samurai_stats.tres")
const SKILL_UPGRADES: Array[String] = ["samurai_dash_cooldown", "samurai_slash_cooldown", "samurai_ultimate_charge"]
const STEP: float = 1.0 / 60.0


func _progress(levels: Dictionary) -> PlayerProgress:
	var progress: PlayerProgress = PlayerProgress.new()
	for id: String in levels:
		progress.set_upgrade_level(id, levels[id])
	return progress


# --- Part 2: cooldown upgrades --------------------------------------------------------

func test_there_are_three_skill_upgrades_worth_forty_percent_at_the_top() -> void:
	for id: String in SKILL_UPGRADES:
		var upgrade: UpgradeData = CATALOG.find(id)
		assert_true(upgrade != null, "%s is in the shop" % id)
		if upgrade == null:
			continue
		assert_eq(upgrade.target, UpgradeData.Target.SAMURAI, "%s upgrades the samurai" % id)
		assert_almost_eq(upgrade.get_total_bonus(upgrade.max_level), 40.0, "%s is -40%% at its maximum level" % id)
		assert_true(upgrade.get_total_bonus(1) < upgrade.get_total_bonus(2), "%s grows with every level" % id)
		assert_true(upgrade.get_cost(0) > 0 and upgrade.get_cost(upgrade.max_level) == -1, "%s costs gold and stops at the maximum" % id)
	assert_true(CATALOG.find("samurai_dash_cooldown").describe_bonus(5).begins_with("-40%"), "the shop shows -40% at level 5")


func test_dash_slash_and_ultimate_get_shorter_with_levels() -> void:
	var base: PlayerStats = UpgradeApplier.build_player_stats(BASE_STATS, PlayerProgress.new(), CATALOG)
	assert_almost_eq(base.dash_cooldown, BASE_STATS.dash_cooldown, "no upgrades: nothing changes")
	assert_almost_eq(base.spirit_slash_cooldown, BASE_STATS.spirit_slash_cooldown, "not the slash either")
	assert_almost_eq(base.ultimate_charge_max, BASE_STATS.ultimate_charge_max, "nor the Ultimate")
	var previous: PlayerStats = base
	for level: int in range(1, 6):
		var levels: Dictionary = {}
		for id: String in SKILL_UPGRADES:
			levels[id] = level
		var upgraded: PlayerStats = UpgradeApplier.build_player_stats(BASE_STATS, _progress(levels), CATALOG)
		assert_true(upgraded.dash_cooldown < previous.dash_cooldown, "level %d: a shorter dash cooldown" % level)
		assert_true(upgraded.spirit_slash_cooldown < previous.spirit_slash_cooldown, "level %d: a shorter spirit slash cooldown" % level)
		assert_true(upgraded.ultimate_charge_max < previous.ultimate_charge_max, "level %d: less charge needed" % level)
		previous = upgraded
	assert_almost_eq(previous.dash_cooldown, BASE_STATS.dash_cooldown * 0.6, "dash -40%% at level 5", 0.001)
	assert_almost_eq(previous.spirit_slash_cooldown, BASE_STATS.spirit_slash_cooldown * 0.6, "slash -40%% at level 5", 0.001)
	assert_almost_eq(previous.ultimate_charge_max, BASE_STATS.ultimate_charge_max * 0.6, "Ultimate charge -40%% at level 5", 0.001)
	var beyond: PlayerStats = UpgradeApplier.build_player_stats(BASE_STATS, _progress({"samurai_dash_cooldown": 50}), CATALOG)
	assert_almost_eq(beyond.dash_cooldown, BASE_STATS.dash_cooldown * 0.6, "never more than 40%%", 0.001)
	assert_eq(BASE_STATS.dash_cooldown, 3.0, "the shared stats resource is never modified")


func test_each_upgrade_changes_only_its_own_skill() -> void:
	var dash: PlayerStats = UpgradeApplier.build_player_stats(BASE_STATS, _progress({"samurai_dash_cooldown": 5}), CATALOG)
	assert_almost_eq(dash.spirit_slash_cooldown, BASE_STATS.spirit_slash_cooldown, "the dash upgrade leaves the slash alone")
	assert_almost_eq(dash.ultimate_charge_max, BASE_STATS.ultimate_charge_max, "and the Ultimate")
	var ultimate: PlayerStats = UpgradeApplier.build_player_stats(BASE_STATS, _progress({"samurai_ultimate_charge": 5}), CATALOG)
	assert_almost_eq(ultimate.dash_cooldown, BASE_STATS.dash_cooldown, "the Ultimate upgrade leaves the dash alone")


func test_the_upgraded_cooldowns_reach_the_player_and_the_ultimate_meter() -> void:
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	var levels: Dictionary = {"samurai_dash_cooldown": 5, "samurai_slash_cooldown": 5, "samurai_ultimate_charge": 5}
	player.apply_stats(UpgradeApplier.build_player_stats(BASE_STATS, _progress(levels), CATALOG))
	var cooldowns: Dictionary = player.get_ability_cooldowns()
	assert_almost_eq((cooldowns["dash"] as Vector2).y, 1.8, "the dash cooldown the HUD shows is shorter")
	assert_almost_eq((cooldowns["slash"] as Vector2).y, 3.6, "and so is the slash's")
	var meter: UltimateMeter = add_to_tree(UltimateMeter.new()) as UltimateMeter
	meter.configure(player.stats)
	meter.add_charge(60.0)
	assert_true(meter.is_ready(), "60 charge is enough for the Ultimate at level 5 (100 without)")
	var plain: UltimateMeter = add_to_tree(UltimateMeter.new()) as UltimateMeter
	plain.configure(BASE_STATS)
	plain.add_charge(60.0)
	assert_true(not plain.is_ready(), "and not enough without the upgrade")
