extends "res://tests/test_case.gd"
## The six allies: roster order, costs and unlocks, the Shrine Healer's healing, the Spear Guardian's
## taunt, the Onmyoji's area burst, the Hatamoto's sweep, their upgrades and the upgrade menu locks.

const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const UPGRADE_MENU_SCENE: PackedScene = preload("res://scenes/upgrade_menu/upgrade_menu.tscn")
const RESULT_SCENE: PackedScene = preload("res://scenes/ui/result_screen.tscn")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const STEP: float = 1.0 / 60.0
const SAVE_DIR: String = "user://test_saves/"


func _ally(id: String, x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find(id), x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally


func _enemy(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	return enemy


## Fireballs and explosions are added next to the fighters, not tracked: clear them after each test.
func cleanup() -> void:
	for node: Node in tree_root.get_children():
		if node is Fireball or node is FireBurst:
			node.free()
	super.cleanup()


func _tick(unit: CharacterBody2D, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		unit._physics_process(STEP)


## Ticks every unit together until `done` is true (or `max_seconds` pass). Returns whether it became true.
func _tick_until(units: Array, done: Callable, max_seconds: float = 4.0) -> bool:
	for i: int in ceili(max_seconds / STEP):
		if done.call():
			return true
		for unit: CharacterBody2D in units:
			if is_instance_valid(unit):
				# No floor in the tests: keep units on the ground line so a fireball flies level.
				unit.global_position.y = 880.0
				unit.velocity.y = 0.0
				unit._physics_process(STEP)
		for node: Node in tree_root.get_children():
			if node is Fireball and is_instance_valid(node):
				node._physics_process(STEP)
	return done.call()


func _health(unit: Node) -> HealthComponent:
	return unit.get_node("HealthComponent") as HealthComponent


# --- Roster -------------------------------------------------------------------

func test_roster_has_six_allies_in_order_with_the_specified_costs() -> void:
	var expected: Array = [["ashigaru", 30.0], ["yumi_archer", 45.0], ["shrine_healer", 65.0],
			["spear_guardian", 80.0], ["onmyoji", 110.0], ["hatamoto", 150.0]]
	assert_eq(ROSTER.allies.size(), 6, "six allies")
	for i: int in expected.size():
		var data: AllyData = ROSTER.allies[i]
		assert_eq(data.id, expected[i][0], "slot %d is %s" % [i + 1, expected[i][0]])
		assert_almost_eq(data.cost, expected[i][1], "%s costs %d" % [data.id, roundi(expected[i][1])])
	var ids: Dictionary = {}
	for data: AllyData in ROSTER.allies:
		assert_true(not ids.has(data.id), "ids are unique (%s)" % data.id)
		ids[data.id] = true


func test_allies_unlock_after_stages_one_to_four() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	assert_eq(ROSTER.get_unlocked(progress).size(), 2, "a new game has the Ashigaru and the Archer")
	var steps: Array = [["stage_1", "shrine_healer"], ["stage_2", "spear_guardian"], ["stage_3", "onmyoji"], ["stage_4", "hatamoto"]]
	var count: int = 2
	for step: Array in steps:
		assert_true(not ROSTER.is_unlocked(ROSTER.find(step[1]), progress), "%s is locked before %s" % [step[1], step[0]])
		progress.stages_cleared.append(step[0])
		count += 1
		assert_eq(ROSTER.get_unlocked(progress).size(), count, "%s unlocks after clearing %s" % [step[1], step[0]])
		assert_true(ROSTER.is_unlocked(ROSTER.find(step[1]), progress), "and is available")
	var order: PackedStringArray = PackedStringArray()
	for data: AllyData in ROSTER.get_unlocked(progress):
		order.append(data.id)
	assert_eq(",".join(order), "ashigaru,yumi_archer,shrine_healer,spear_guardian,onmyoji,hatamoto", "unlocked allies keep the roster order")


func test_every_unlock_stage_exists_and_stages_unlock_in_order() -> void:
	var stage_ids: Array[String] = []
	for stage: StageData in StageProgression.default_region().stages:
		stage_ids.append(stage.stage_id)
	var last_index: int = -1
	for data: AllyData in ROSTER.allies:
		if data.unlock_stage_id.is_empty():
			continue
		var index: int = stage_ids.find(data.unlock_stage_id)
		assert_true(index >= 0, "%s unlocks at a real stage (%s)" % [data.id, data.unlock_stage_id])
		assert_true(index > last_index, "later allies unlock later")
		last_index = index


func test_new_allies_have_their_own_figure_and_accent() -> void:
	var kinds: Dictionary = {}
	for id: String in ["shrine_healer", "spear_guardian", "onmyoji", "hatamoto"]:
		var data: AllyData = ROSTER.find(id)
		assert_true(data.figure >= InkFigure.Kind.SHRINE_HEALER, "%s draws one of the new figures" % id)
		assert_true(not kinds.has(data.figure), "%s has its own figure" % id)
		kinds[data.figure] = true
	var accents: Array[Color] = [InkPalette.HEALER_JADE, InkPalette.GUARDIAN_AZURE, InkPalette.ONMYOJI_MAGENTA, InkPalette.HATAMOTO_ORANGE]
	for i: int in accents.size():
		assert_true(InkPalette.ACCENTS.has(accents[i]), "accent %d is in the palette list" % i)
		for j: int in range(i + 1, accents.size()):
			assert_true(InkPalette.contrast(accents[i], accents[j]) > 1.0 and accents[i] != accents[j], "accents are different colours")
	var heights: Dictionary = {}
	for id: String in ["shrine_healer", "spear_guardian", "onmyoji", "hatamoto"]:
		var data: AllyData = ROSTER.find(id)
		var spec: FigureKinds.Spec = FigureKinds.spec(data.figure)
		assert_true(spec.head_top >= data.body_size.y * 0.9, "%s's head top matches its body height" % id)
		heights[id] = spec.head_top
	assert_true(heights["onmyoji"] > heights["shrine_healer"] and heights["hatamoto"] > heights["onmyoji"], "silhouettes differ in height (tall hat, tall helmet)")


# --- Shrine Healer --------------------------------------------------------------

func test_healer_walks_to_the_most_injured_ally_and_heals_it() -> void:
	var healer: Ally = _ally("shrine_healer", 400.0)
	var healthy: Ally = _ally("ashigaru", 520.0)
	var hurt: Ally = _ally("ashigaru", 640.0)
	var worse: Ally = _ally("yumi_archer", 700.0)
	_health(hurt).take_damage(50.0)
	_health(worse).take_damage(50.0)
	var worse_before: float = _health(worse).current_health
	var hurt_before: float = _health(hurt).current_health
	var healed_info: Array = []
	healer.healed.connect(func(target: Ally, amount: float) -> void: healed_info.append([target, amount]))
	var units: Array = [healer, healthy, hurt, worse]
	assert_true(_tick_until(units, func() -> bool: return not healed_info.is_empty(), 4.0), "the healer heals someone")
	assert_true(healed_info[0][0] == worse, "the most injured ally (lowest health ratio) is healed first")
	assert_almost_eq(healed_info[0][1], 28.0, "by her healing amount")
	assert_almost_eq(_health(worse).current_health, worse_before + 28.0, "its health went up")
	assert_eq(_health(hurt).current_health, hurt_before, "the other ally has not been healed yet")
	assert_eq(_health(healthy).current_health, ROSTER.find("ashigaru").max_health, "a healthy ally is never touched")
	assert_eq(_health(healer).current_health, ROSTER.find("shrine_healer").max_health, "and she does not heal herself")


func test_healer_never_overheals_and_ignores_far_or_dead_allies() -> void:
	var healer: Ally = _ally("shrine_healer", 400.0)
	var nearly_full: Ally = _ally("ashigaru", 450.0)
	_health(nearly_full).take_damage(5.0)
	var far: Ally = _ally("ashigaru", 400.0 + ROSTER.find("shrine_healer").aggro_range + 300.0)
	_health(far).take_damage(60.0)
	var far_before: float = _health(far).current_health
	assert_true(not is_instance_valid(healer.call("_find_heal_target")) or healer.call("_find_heal_target") != far, "an ally beyond her aggro range is not a target")
	# 5 damage of 120 is 96% health: above the heal threshold, so nobody needs her.
	assert_true(healer.call("_find_heal_target") == null, "a barely scratched ally does not need healing")
	_health(nearly_full).take_damage(30.0)
	var done: Array[bool] = [false]
	healer.healed.connect(func(_t: Ally, _a: float) -> void: done[0] = true)
	assert_true(_tick_until([healer, nearly_full], func() -> bool: return done[0], 4.0), "once hurt enough she heals")
	assert_true(_health(nearly_full).current_health <= ROSTER.find("ashigaru").max_health, "health never exceeds the maximum")
	assert_eq(_health(far).current_health, far_before, "the far ally was not healed")
	var fallen: Ally = _ally("ashigaru", 430.0)
	_health(fallen).take_damage(10000.0)
	assert_true(healer.call("_find_heal_target") != fallen, "a dead ally is not a target")


func test_healer_does_not_attack_enemies() -> void:
	var healer: Ally = _ally("shrine_healer", 400.0)
	var enemy: Enemy = _enemy(500.0)
	_tick(healer, 3.0)
	assert_eq(_health(enemy).current_health, HOLLOW_SOLDIER.max_health, "she only blesses; the enemy is untouched")
	assert_true(healer.get_target() == null, "she has no enemy target")


# --- Spear Guardian -------------------------------------------------------------

func test_guardian_taunts_enemies_in_range_away_from_other_allies() -> void:
	var guardian: Ally = _ally("spear_guardian", 560.0)
	var ashigaru: Ally = _ally("ashigaru", 800.0)
	var enemy: Enemy = _enemy(900.0)
	assert_true(enemy.select_target() == guardian, "in taunt range the enemy goes for the Guardian, not the nearer Ashigaru")
	guardian.global_position.x = 900.0 - ROSTER.find("spear_guardian").taunt_range - 100.0
	assert_true(enemy.select_target() == ashigaru, "outside her taunt range the enemy picks the nearest ally as usual")
	guardian.global_position.x = 560.0
	_health(guardian).take_damage(10000.0)
	assert_true(enemy.select_target() == ashigaru, "a fallen Guardian taunts nobody")


func test_guardian_is_a_tank() -> void:
	var guardian: AllyData = ROSTER.find("spear_guardian")
	var ashigaru: AllyData = ROSTER.find("ashigaru")
	assert_true(guardian.max_health >= ashigaru.max_health * 2.5, "she has far more health than the Ashigaru")
	assert_true(not guardian.interruptible and guardian.knockback_resistance >= 0.5, "enemy hits do not stagger or shove her")
	assert_true(guardian.attack_damage < ashigaru.attack_damage, "and she hits lightly")
	assert_true(guardian.taunt_range > 0.0, "she taunts")


# --- Onmyoji --------------------------------------------------------------------

func test_onmyoji_fireball_explodes_on_every_enemy_around_the_target_once() -> void:
	var data: AllyData = ROSTER.find("onmyoji")
	var mage: Ally = _ally("onmyoji", 400.0)
	var first: Enemy = _enemy(800.0)
	var second: Enemy = _enemy(870.0)
	var third: Enemy = _enemy(800.0 + data.area_radius * 0.8)
	var outside: Enemy = _enemy(800.0 + data.area_radius + 150.0)
	var friend: Ally = _ally("ashigaru", 790.0)
	var units: Array = [mage]
	assert_true(_tick_until(units, func() -> bool: return _health(first).current_health < HOLLOW_SOLDIER.max_health, 5.0), "the Onmyoji's fireball reaches the nearest enemy")
	var expected: float = HOLLOW_SOLDIER.max_health - data.attack_damage
	assert_almost_eq(_health(first).current_health, expected, "the target takes the blast damage")
	assert_almost_eq(_health(second).current_health, expected, "so does an enemy beside it")
	assert_almost_eq(_health(third).current_health, expected, "and one inside the radius")
	assert_eq(_health(outside).current_health, HOLLOW_SOLDIER.max_health, "an enemy outside the radius is untouched")
	assert_eq(_health(friend).current_health, ROSTER.find("ashigaru").max_health, "allies are never hurt by the blast")


func test_onmyoji_keeps_to_range_and_stands_behind_the_front_line() -> void:
	var data: AllyData = ROSTER.find("onmyoji")
	assert_true(data.attack_range > ROSTER.find("ashigaru").attack_range * 3.0, "she attacks from far away")
	assert_true(data.is_ranged_like(), "ranged-like allies may stand behind others")
	assert_true(data.max_health < ROSTER.find("ashigaru").max_health, "and she is fragile")
	assert_eq(data.role, AllyData.Role.MAGE, "she is a mage")


# --- Hatamoto -------------------------------------------------------------------

func test_hatamoto_is_the_elite_fighter_and_sweeps_wide() -> void:
	var data: AllyData = ROSTER.find("hatamoto")
	var ashigaru: AllyData = ROSTER.find("ashigaru")
	assert_true(data.max_health > ashigaru.max_health * 2.0 and data.attack_damage > ashigaru.attack_damage * 2.0, "much tougher and stronger than an Ashigaru")
	assert_true(data.attack.hitbox_size.x > ashigaru.attack.hitbox_size.x, "its sweep reaches further than a spear thrust")
	assert_true(data.attack.hitbox_size.y > ashigaru.attack.hitbox_size.y, "and is taller")
	var hatamoto: Ally = _ally("hatamoto", 400.0)
	var rect: RectangleShape2D = (hatamoto.get_node("Hitbox/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	assert_true(rect != null and rect.size.x >= 170.0, "its hitbox is wide enough for two enemies in a row")


# --- Upgrades -------------------------------------------------------------------

func test_each_new_ally_has_an_upgrade_that_changes_its_stats() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	var checks: Array = [["healer_blessing", "shrine_healer", "attack_damage"], ["guardian_health", "spear_guardian", "max_health"],
			["onmyoji_damage", "onmyoji", "attack_damage"], ["hatamoto_damage", "hatamoto", "attack_damage"]]
	for check: Array in checks:
		var upgrade: UpgradeData = CATALOG.find(check[0])
		assert_true(upgrade != null and upgrade.ally_id == check[1], "%s upgrades %s" % [check[0], check[1]])
		var base: AllyData = ROSTER.find(check[1])
		progress.set_upgrade_level(check[0], 2)
		var upgraded: AllyData = UpgradeApplier.build_ally_data(base, progress, CATALOG)
		assert_almost_eq(float(upgraded.get(check[2])), float(base.get(check[2])) + upgrade.amount_per_level * 2.0, "level 2 of %s adds its bonus to %s" % [check[0], check[2]])
		assert_true(upgrade.get_cost(0) > 0 and upgrade.max_level >= 3, "%s has a cost and levels" % check[0])
	assert_eq(UpgradeApplier.build_ally_data(ROSTER.find("ashigaru"), progress, CATALOG).attack_damage, ROSTER.find("ashigaru").attack_damage,
			"another ally is not affected by their upgrades")


func test_upgrade_menu_locks_upgrades_for_allies_not_yet_unlocked() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path: String = SAVE_DIR + "allies_menu_save.json"
	var manager: SaveManager = SaveManager.new(path)
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 5000
	manager.save_progress(progress)
	var menu: Control = UPGRADE_MENU_SCENE.instantiate()
	menu.set("save_path", path)
	add_to_tree(menu)
	var upgrade: UpgradeData = CATALOG.find("healer_blessing")
	assert_true(menu.call("is_locked", upgrade), "the healer's upgrade is locked in a new game")
	assert_true(not menu.call("is_locked", CATALOG.find("ashigaru_damage")), "the Ashigaru's is not")
	assert_true(not menu.call("is_locked", CATALOG.find("samurai_damage")), "nor the samurai's")
	var result: UpgradeShop.Result = menu.call("buy", "healer_blessing")
	assert_eq(result, UpgradeShop.Result.INVALID_UPGRADE, "a locked upgrade cannot be bought")
	assert_eq((menu.call("get_progress") as PlayerProgress).gold, 5000, "no gold is spent")
	(menu.call("get_progress") as PlayerProgress).stages_cleared.append("stage_1")
	assert_true(not menu.call("is_locked", upgrade), "it unlocks with the healer")
	assert_eq(menu.call("buy", "healer_blessing"), UpgradeShop.Result.OK, "and can then be bought")


# --- Battle ---------------------------------------------------------------------

func _battlefield_with(cleared: Array[String]) -> Node:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path: String = SAVE_DIR + "allies_battle_%d.json" % cleared.size()
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = cleared.duplicate()
	SaveManager.new(path).save_progress(progress)
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", path)
	field.set("settings_path", SAVE_DIR + "allies_battle_settings.cfg")
	add_to_tree(field)
	return field


func test_battle_offers_only_unlocked_allies_in_roster_order() -> void:
	var fresh: Node = _battlefield_with([] as Array[String])
	var summoner: SummonManager = fresh.get_node("World/SummonManager") as SummonManager
	assert_eq(summoner.get_slot_count(), 2, "a new game offers two allies")
	var later: Node = _battlefield_with(["stage_1", "stage_2", "stage_3"] as Array[String])
	var later_summoner: SummonManager = later.get_node("World/SummonManager") as SummonManager
	assert_eq(later_summoner.get_slot_count(), 5, "after stage 3 five are unlocked")
	assert_eq(later_summoner.get_slot_data(2).id, "shrine_healer", "slot 3 is the healer")
	assert_eq(later_summoner.get_slot_data(4).id, "onmyoji", "slot 5 is the Onmyoji")
	assert_true(later_summoner.get_slot_data(5) == null, "slot 6 is empty until the Hatamoto unlocks")
	var all: Node = _battlefield_with(["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String])
	var all_summoner: SummonManager = all.get_node("World/SummonManager") as SummonManager
	assert_eq(all_summoner.get_slot_count(), 6, "after stage 4 all six")
	assert_eq(all_summoner.get_slot_data(5).id, "hatamoto", "slot 6 is the Hatamoto")
	for key: StringName in [&"summon_3", &"summon_4", &"summon_5", &"summon_6"]:
		assert_true(InputMap.has_action(key), "%s is on the Input Map" % key)


func test_upgrades_reach_the_summoned_allies() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var path: String = SAVE_DIR + "allies_upgrade_battle.json"
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1"] as Array[String]
	progress.set_upgrade_level("healer_blessing", 3)
	SaveManager.new(path).save_progress(progress)
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", path)
	field.set("settings_path", SAVE_DIR + "allies_upgrade_settings.cfg")
	add_to_tree(field)
	var summoner: SummonManager = field.get_node("World/SummonManager") as SummonManager
	assert_almost_eq(summoner.get_slot_data(2).attack_damage, 28.0 + 15.0, "the healer heals 3 levels more in battle")


func test_result_screen_announces_a_newly_unlocked_ally() -> void:
	var screen: ResultScreen = add_to_tree(RESULT_SCENE.instantiate()) as ResultScreen
	var reward: BattleReward = BattleReward.new()
	reward.victory = true
	screen.show_result(reward, PlayerProgress.new(), 0, OK, "Bamboo Path", PackedStringArray(["Shrine Healer"]))
	var subtitle: Label = screen.find_child("SubtitleLabel", true, false) as Label
	assert_true(subtitle.text.contains("Shrine Healer"), "the victory text names the new ally")
	screen.show_result(reward, PlayerProgress.new(), 0, OK, "")
	assert_true(not subtitle.text.contains("New ally"), "and says nothing when there is none")
