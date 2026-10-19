extends "res://tests/test_case.gd"
## Rewards, levels, upgrade purchases and upgrades applied to battle stats.

const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const STAGE_1: StageData = preload("res://data/stages/stage_1.tres")
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const SAMURAI_STATS: PlayerStats = preload("res://data/player/samurai_stats.tres")
const ASHIGARU: AllyData = preload("res://data/allies/ashigaru.tres")
const ARCHER: AllyData = preload("res://data/allies/yumi_archer.tres")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")


func _kills(hollow: int, oni: int) -> Array[EnemyData]:
	var killed: Array[EnemyData] = []
	for i: int in hollow:
		killed.append(HOLLOW_SOLDIER)
	for i: int in oni:
		killed.append(ONI_BRUTE)
	return killed


# --- Rewards ----------------------------------------------------------------

func test_reward_data_values() -> void:
	assert_eq(HOLLOW_SOLDIER.gold_reward, 8, "Hollow Soldier gold")
	assert_eq(HOLLOW_SOLDIER.xp_reward, 10, "Hollow Soldier XP")
	assert_eq(ONI_BRUTE.gold_reward, 40, "Oni Brute gold")
	assert_eq(ONI_BRUTE.xp_reward, 50, "Oni Brute XP")
	assert_eq(STAGE_1.clear_gold_bonus, 150, "stage clear gold bonus")
	assert_eq(STAGE_1.clear_xp_bonus, 50, "stage clear XP bonus")


func test_victory_reward_is_kills_plus_bonus() -> void:
	var reward: BattleReward = RewardCalculator.calculate(_kills(16, 1), STAGE_1, true)
	assert_eq(reward.enemies_defeated, 17, "17 kills counted")
	assert_eq(reward.kill_gold, 16 * 8 + 40, "kill gold")
	assert_eq(reward.kill_xp, 16 * 10 + 50, "kill XP")
	assert_eq(reward.bonus_gold, 150, "clear bonus gold")
	assert_eq(reward.bonus_xp, 50, "clear bonus XP")
	assert_eq(reward.gold, 318, "total gold for a full stage 1 clear")
	assert_eq(reward.xp, 260, "total XP for a full stage 1 clear")


func test_defeat_reward_is_partial_without_bonus() -> void:
	var reward: BattleReward = RewardCalculator.calculate(_kills(5, 1), STAGE_1, false)
	assert_eq(reward.bonus_gold, 0, "no clear bonus on defeat")
	assert_eq(reward.gold, floori((5 * 8 + 40) * 0.5), "half of kill gold, rounded down")
	assert_eq(reward.xp, floori((5 * 10 + 50) * 0.5), "half of kill XP, rounded down")
	assert_almost_eq(reward.kill_ratio, 0.5, "ratio reported")


func test_no_kills_defeat_gives_nothing() -> void:
	var reward: BattleReward = RewardCalculator.calculate(_kills(0, 0), STAGE_1, false)
	assert_eq(reward.gold, 0, "no gold")
	assert_eq(reward.xp, 0, "no XP")


func test_record_battle_updates_progress() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	var levels: int = progress.record_battle(RewardCalculator.calculate(_kills(16, 1), STAGE_1, true), STAGE_1.stage_id)
	assert_eq(progress.gold, 318, "gold added")
	assert_eq(progress.xp, 260, "XP added")
	assert_eq(levels, 1, "260 XP reaches level 2")
	assert_eq(progress.get_level(), 2, "level 2")
	assert_true(progress.is_stage_cleared("stage_1"), "stage marked cleared")
	assert_eq(progress.victories, 1, "victory counted")
	assert_eq(progress.enemies_defeated, 17, "kills counted")
	progress.record_battle(RewardCalculator.calculate(_kills(2, 0), STAGE_1, false), STAGE_1.stage_id)
	assert_eq(progress.defeats, 1, "defeat counted")
	assert_eq(progress.stages_cleared.size(), 1, "stage not duplicated")


func test_level_thresholds() -> void:
	assert_eq(PlayerProgress.xp_for_level(2), 100, "level 2 at 100 XP")
	assert_eq(PlayerProgress.xp_for_level(3), 300, "level 3 at 300 XP")
	var progress: PlayerProgress = PlayerProgress.new()
	progress.xp = 299
	assert_eq(progress.get_level(), 2, "299 XP is level 2")
	progress.xp = 300
	assert_eq(progress.get_level(), 3, "300 XP is level 3")


# --- Upgrade purchases ------------------------------------------------------

func test_catalog_has_the_six_spec_upgrades() -> void:
	for id: String in ["samurai_max_health", "samurai_damage", "ashigaru_health",
			"ashigaru_damage", "archer_damage", "spirit_regen"]:
		assert_true(CATALOG.find(id) != null, "catalog has %s" % id)


func test_costs_rise_with_level() -> void:
	var upgrade: UpgradeData = CATALOG.find("samurai_max_health")
	assert_eq(upgrade.get_cost(0), 100, "level 1 costs 100")
	assert_eq(upgrade.get_cost(1), 120, "level 2 costs 120")
	assert_true(upgrade.get_cost(2) > upgrade.get_cost(1), "costs keep rising")
	assert_eq(upgrade.get_cost(upgrade.max_level), -1, "no cost when maxed")


func test_purchase_succeeds_with_enough_gold() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 500
	var upgrade: UpgradeData = CATALOG.find("samurai_max_health")
	assert_eq(UpgradeShop.purchase(progress, upgrade), UpgradeShop.Result.OK, "purchase OK")
	assert_eq(progress.gold, 400, "100 gold spent")
	assert_eq(progress.get_upgrade_level("samurai_max_health"), 1, "level 1")
	assert_eq(UpgradeShop.purchase(progress, upgrade), UpgradeShop.Result.OK, "second purchase OK")
	assert_eq(progress.gold, 280, "120 gold spent for level 2")
	assert_eq(progress.get_upgrade_level("samurai_max_health"), 2, "level 2")


func test_purchase_rejected_without_enough_gold() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 99
	var upgrade: UpgradeData = CATALOG.find("samurai_max_health")
	assert_eq(UpgradeShop.purchase(progress, upgrade), UpgradeShop.Result.NOT_ENOUGH_GOLD, "rejected")
	assert_eq(progress.gold, 99, "gold unchanged")
	assert_eq(progress.get_upgrade_level("samurai_max_health"), 0, "level unchanged")


func test_purchase_rejected_at_max_level() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 100000
	var upgrade: UpgradeData = CATALOG.find("spirit_regen")
	progress.set_upgrade_level(upgrade.id, upgrade.max_level)
	assert_eq(UpgradeShop.purchase(progress, upgrade), UpgradeShop.Result.MAX_LEVEL, "rejected at max")
	assert_eq(progress.gold, 100000, "gold unchanged")


# --- Upgrades applied to stats ----------------------------------------------

func _upgraded_progress() -> PlayerProgress:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.set_upgrade_level("samurai_max_health", 2)
	progress.set_upgrade_level("samurai_damage", 3)
	progress.set_upgrade_level("ashigaru_health", 2)
	progress.set_upgrade_level("ashigaru_damage", 1)
	progress.set_upgrade_level("archer_damage", 2)
	progress.set_upgrade_level("spirit_regen", 2)
	return progress


func test_upgrades_apply_to_stat_copies() -> void:
	var progress: PlayerProgress = _upgraded_progress()
	var stats: PlayerStats = UpgradeApplier.build_player_stats(SAMURAI_STATS, progress, CATALOG)
	assert_almost_eq(stats.max_health, 240.0, "samurai max HP 200 + 2x20")
	assert_almost_eq(stats.base_damage, 29.0, "samurai damage 20 + 3x3")
	var ashigaru: AllyData = UpgradeApplier.build_ally_data(ASHIGARU, progress, CATALOG)
	assert_almost_eq(ashigaru.max_health, 160.0, "Ashigaru HP 120 + 2x20")
	assert_almost_eq(ashigaru.attack_damage, 17.0, "Ashigaru damage 14 + 3")
	var archer: AllyData = UpgradeApplier.build_ally_data(ARCHER, progress, CATALOG)
	assert_almost_eq(archer.attack_damage, 18.0, "Archer damage 12 + 2x3")
	assert_almost_eq(archer.max_health, 70.0, "Archer HP not affected by Ashigaru upgrade")
	assert_almost_eq(UpgradeApplier.build_spirit_regen(5.0, progress, CATALOG), 7.0, "regen 5 + 2x1")
	# Shared resources must stay untouched.
	assert_almost_eq(SAMURAI_STATS.max_health, 200.0, "base samurai stats unchanged")
	assert_almost_eq(ASHIGARU.max_health, 120.0, "base Ashigaru data unchanged")


func test_upgraded_stats_reach_battle_units() -> void:
	var progress: PlayerProgress = _upgraded_progress()
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	player.apply_stats(UpgradeApplier.build_player_stats(player.stats, progress, CATALOG))
	assert_almost_eq(player.get_health().max_health, 240.0, "player spawns with upgraded max HP")
	assert_almost_eq(player.get_health().current_health, 240.0, "player starts at full upgraded HP")
	assert_almost_eq(player.stats.base_damage, 29.0, "player attacks use upgraded damage")

	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(UpgradeApplier.build_ally_data(ASHIGARU, progress, CATALOG), 400.0)
	add_to_tree(ally)
	assert_almost_eq(ally.get_health().max_health, 160.0, "summoned Ashigaru has upgraded HP")
