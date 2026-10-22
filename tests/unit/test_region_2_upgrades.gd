extends "res://tests/test_case.gd"
## Save compatibility, purchase gates, real damage paths and the campaign budget.

const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const FIELD: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")


func test_original_upgrade_prices_and_owned_levels_are_preserved() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	var original_cost: int = 0
	for upgrade: UpgradeData in CATALOG.upgrades:
		if not upgrade.unlock_stage_id.is_empty():
			continue
		var old_cap: int = upgrade.region_1_cap if upgrade.region_1_cap > 0 else upgrade.max_level
		progress.set_upgrade_level(upgrade.id, old_cap)
		for level: int in old_cap:
			var expected: int = maxi(roundi(upgrade.base_cost * pow(upgrade.cost_growth, level) / 5.0) * 5, 5)
			assert_eq(upgrade.get_cost(level), expected, "%s keeps shipped price %d" % [upgrade.id, level])
			original_cost += expected
	var path: String = "user://test_saves/region_two_legacy.json"
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	SaveManager.new(path).save_progress(progress)
	var restored: PlayerProgress = SaveManager.new(path).load_progress()
	assert_eq(restored.upgrade_levels, progress.upgrade_levels, "v0.1 purchases survive the save round trip")
	assert_eq(original_cost, 12915, "the original full set costs exactly the shipped amount")


func test_region_two_purchases_require_clearing_region_one() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 100000
	for id: String in ["samurai_max_health", "gate_armour", "army_fire_resistance"]:
		var upgrade: UpgradeData = CATALOG.find(id)
		var start: int = upgrade.region_1_cap
		progress.set_upgrade_level(id, start)
		assert_eq(UpgradeShop.purchase(progress, upgrade), UpgradeShop.Result.LOCKED, "%s locked before stage 5" % id)
		assert_eq(progress.gold, 100000, "locked purchase never spends gold")
		assert_eq(progress.get_upgrade_level(id), start, "locked purchase never adds a level")
	for number: int in range(1, 7): progress.stages_cleared.append("stage_%d" % number)
	for id: String in ["samurai_max_health", "gate_armour", "army_fire_resistance"]:
		var upgrade: UpgradeData = CATALOG.find(id)
		var before: int = progress.gold
		var level: int = progress.get_upgrade_level(id)
		assert_eq(UpgradeShop.purchase(progress, upgrade), UpgradeShop.Result.OK, "%s unlocks after stage 6" % id)
		assert_eq(progress.gold, before - upgrade.get_cost(level), "only the new tier's price is charged")


func test_full_catalog_fits_stage_ten_budget_but_not_stage_nine() -> void:
	var cost: int = 0
	var levels: int = 0
	for upgrade: UpgradeData in CATALOG.upgrades:
		levels += upgrade.max_level
		for level: int in upgrade.max_level:
			cost += upgrade.get_cost(level)
	var budget: int = 0
	var before_final: int = 0
	for stage: StageData in StageProgression.all_stages():
		if stage.stage_id == "stage_10":
			before_final = budget
		var reward: int = stage.get_full_clear_gold()
		budget += reward + floori(reward * stage.replay_gold_multiplier)
	assert_true(levels > 78, "there are meaningful additional levels")
	assert_true(cost > before_final, "a clear and replay of stages 1-9 cannot buy everything")
	assert_true(cost <= budget, "a clear and replay through stage 10 can finish the set")
	for id: String in ["samurai_dash_cooldown", "samurai_slash_cooldown", "samurai_ultimate_charge"]:
		assert_almost_eq(CATALOG.find(id).get_total_bonus(99), 40.0, "%s still respects its useful 40%% cap" % id)


func test_gate_armour_and_fire_resistance_mitigate_real_hits_once() -> void:
	var target: Node2D = Node2D.new()
	var health: HealthComponent = HealthComponent.new()
	health.max_health = 1000.0
	target.add_child(health)
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.health_component = health
	target.add_child(hurtbox)
	add_to_tree(target)
	var hitbox: HitboxComponent = track(HitboxComponent.new()) as HitboxComponent
	hitbox.faction = Faction.Type.ENEMIES
	hitbox.damage = 100.0
	hitbox.knockback_direction_x = 1.0
	var progress: PlayerProgress = PlayerProgress.new()
	progress.set_upgrade_level("gate_armour", 4)
	progress.set_upgrade_level("army_fire_resistance", 4)
	hurtbox.damage_multiplier = UpgradeApplier.build_gate_damage_multiplier(progress, CATALOG)
	hurtbox.fire_damage_multiplier = UpgradeApplier.build_fire_damage_multiplier(progress, CATALOG)
	assert_true(hurtbox.receive_hit(hitbox), "ordinary hit reaches the gate")
	assert_almost_eq(health.current_health, 930.0, "gate armour removes 30% of physical damage")
	hitbox.fire = true
	assert_true(hurtbox.receive_hit(hitbox), "fire also reaches the gate")
	assert_almost_eq(health.current_health, 888.0, "fire stacks multiplicatively: 100 * .7 * .6 = 42")
	hurtbox.damage_multiplier = 1.0
	assert_true(hurtbox.receive_hit(hitbox), "hero or ally receives fire")
	assert_almost_eq(health.current_health, 828.0, "army fire protection removes 40%")
	hitbox.fire = false
	assert_true(hurtbox.receive_hit(hitbox), "ordinary hit reaches the hero")
	assert_almost_eq(health.current_health, 728.0, "fire protection does not reduce ordinary hits")


func test_upgrades_reach_gate_player_and_newly_summoned_allies() -> void:
	var path: String = "user://test_saves/region_two_armour.json"
	DirAccess.make_dir_recursive_absolute("user://test_saves")
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5"]
	progress.set_upgrade_level("gate_armour", 4)
	progress.set_upgrade_level("army_fire_resistance", 4)
	SaveManager.new(path).save_progress(progress)
	var field: Node = FIELD.instantiate()
	field.set("save_path", path)
	field.set("settings_path", "user://test_saves/region_two_armour.cfg")
	add_to_tree(field)
	var gate: HurtboxComponent = field.get_node("World/VillageGate/Hurtbox")
	var player: HurtboxComponent = field.get_node("World/Player/Hurtbox")
	assert_almost_eq(gate.damage_multiplier, 0.7, "gate armour applied on battle entry")
	assert_almost_eq(player.damage_multiplier, 1.0, "gate armour does not buff hero physical defence")
	assert_almost_eq(gate.fire_damage_multiplier, 0.6, "gate fire resistance applied")
	assert_almost_eq(player.fire_damage_multiplier, 0.6, "hero fire resistance applied")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	assert_eq(summoner.request_summon(0), SummonManager.Result.OK, "summon succeeds")
	var ally: Ally = field.get_node("World/Allies").get_child(0) as Ally
	assert_almost_eq((ally.get_node("Hurtbox") as HurtboxComponent).fire_damage_multiplier, 0.6, "new ally inherits protection")
	assert_eq(SaveManager.new(path).load_progress().get_upgrade_level("gate_armour"), 4, "saved purchase persists")


func test_only_burning_general_fire_attacks_are_tagged_as_fire() -> void:
	var pillar: FirePillar = FirePillar.new()
	pillar.setup(40.0, 100.0, Vector2(80, 120), 0.35, null)
	add_to_tree(pillar)
	assert_true((pillar.get_node("Hitbox") as HitboxComponent).fire, "pillars use fire mitigation")
	var flame: CursedWave = CursedWave.new()
	flame.fire = true
	flame.setup(-1.0, 30, 200, 1000, 100, null, Vector2.ZERO)
	add_to_tree(flame)
	assert_true((flame.get_node("Hitbox") as HitboxComponent).fire, "wall of flame uses fire mitigation")
	var curse: CursedWave = CursedWave.new()
	curse.setup(-1.0, 30, 200, 1000, 100, null, Vector2.ZERO)
	add_to_tree(curse)
	assert_true(not (curse.get_node("Hitbox") as HitboxComponent).fire, "Daimyo curse remains ordinary damage")


func test_region_one_purchase_caps_follow_unique_stages_cleared() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	var health: UpgradeData = CATALOG.find("samurai_max_health")
	var expected: Array[int] = [2, 2, 3, 3, 4, 5]
	for count: int in expected.size():
		assert_eq(health.available_max_level(progress), expected[count], "%d clears caps original levels correctly" % count)
		progress.gold = 100000
		progress.set_upgrade_level(health.id, expected[count])
		assert_eq(UpgradeShop.purchase(progress, health), UpgradeShop.Result.LOCKED, "gold cannot bypass the next cap")
		assert_eq(progress.gold, 100000, "blocked level never charges gold")
		progress.stages_cleared.append("stage_%d" % (count + 1))
	progress.stages_cleared = ["stage_1", "stage_1"]
	assert_eq(health.available_max_level(progress), 2, "replays cannot count as additional clears")


func test_region_two_tiers_and_defences_open_in_steps_through_stage_ten() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	var health: UpgradeData = CATALOG.find("samurai_max_health")
	var armour: UpgradeData = CATALOG.find("gate_armour")
	var resistance: UpgradeData = CATALOG.find("army_fire_resistance")
	var health_caps: Array[int] = [5, 6, 6, 6, 7, 7]
	var defence_caps: Array[int] = [0, 1, 2, 3, 3, 4]
	for number: int in range(1, 6): progress.stages_cleared.append("stage_%d" % number)
	for offset: int in 6:
		assert_eq(health.available_max_level(progress), health_caps[offset], "existing extra tiers progress through Region 2")
		assert_eq(armour.available_max_level(progress), defence_caps[offset], "gate armour milestone")
		assert_eq(resistance.available_max_level(progress), defence_caps[offset], "fire resistance milestone")
		progress.stages_cleared.append("stage_%d" % (offset + 6))


func test_legacy_levels_above_purchase_cap_keep_their_bonus_and_save() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.set_upgrade_level("samurai_max_health", 5)
	progress.set_upgrade_level("gate_armour", 4)
	progress.gold = 14000
	var stats: PlayerStats = UpgradeApplier.build_player_stats(PlayerStats.new(), progress, CATALOG)
	assert_almost_eq(stats.max_health, PlayerStats.new().max_health + 100, "five old HP levels remain effective despite early cap")
	assert_almost_eq(UpgradeApplier.build_gate_damage_multiplier(progress, CATALOG), 0.7, "already owned defence remains effective")
	assert_eq(UpgradeShop.purchase(progress, CATALOG.find("samurai_max_health")), UpgradeShop.Result.LOCKED, "only the next purchase is gated")
	assert_eq(progress.get_upgrade_level("samurai_max_health"), 5, "owned levels never decrease")
	assert_eq(progress.gold, 14000, "save gold is untouched")
