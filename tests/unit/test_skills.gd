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


# --- Part 3: War Cry and Bow ------------------------------------------------------------

const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const SAVE_DIR: String = "user://test_saves/"


func _player(bow: bool = true, war_cry: bool = true) -> Player:
	# Other tests may have left an action pressed; a leftover dash would start a dash instead.
	for action: StringName in [&"attack", &"heavy_attack", &"dash", &"spirit_slash", &"bow", &"war_cry", &"ultimate", &"stance"]:
		Input.action_release(action)
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	player.global_position = Vector2(500.0, 880.0)
	# Earlier tests in the same frame leave "just pressed" set on some actions: this player ignores the keys.
	player.read_input = false
	player.bow_unlocked = bow
	player.war_cry_unlocked = war_cry
	return player


func _tick_player(player: Player, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		player._physics_process(STEP)


func _press(action: StringName, player: Player) -> void:
	player.use_skill(action)
	player._physics_process(STEP)


func _arrows(player: Player) -> Array[Arrow]:
	var found: Array[Arrow] = []
	for child: Node in player.get_parent().get_children():
		if child is Arrow:
			found.append(child as Arrow)
			track(child)
	return found


func _ally(x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find("ashigaru"), x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally


func _enemy(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	enemy.set_physics_process(false)
	return enemy


func test_q_and_e_are_bound_to_the_new_skills() -> void:
	for pair: Array in [[&"war_cry", KEY_Q], [&"bow", KEY_E]]:
		assert_true(InputMap.has_action(pair[0]), "there is a %s action" % pair[0])
		var bound: bool = false
		for event: InputEvent in InputMap.action_get_events(pair[0]):
			var key: InputEventKey = event as InputEventKey
			if key != null and key.physical_keycode == pair[1]:
				bound = true
		assert_true(bound, "%s is on its key" % pair[0])


func test_the_bow_unlocks_after_stage_1_and_the_war_cry_after_stage_2() -> void:
	assert_eq(Player.BOW_UNLOCK_STAGE, "stage_1", "the Bow comes with stage 1")
	assert_eq(Player.WAR_CRY_UNLOCK_STAGE, "stage_2", "the War Cry with stage 2")
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var expected: Array = [[[], false, false], [["stage_1"], true, false], [["stage_1", "stage_2"], true, true]]
	for case: Array in expected:
		var progress: PlayerProgress = PlayerProgress.new()
		for id: String in case[0]:
			progress.stages_cleared.append(id)
		var path: String = SAVE_DIR + "skills_unlock_save.json"
		SaveManager.new(path).save_progress(progress)
		var field: Node = BATTLEFIELD_SCENE.instantiate()
		field.set("save_path", path)
		field.set("settings_path", SAVE_DIR + "skills_unlock_settings.cfg")
		add_to_tree(field)
		var player: Player = field.get_node("World/Player") as Player
		assert_eq(player.bow_unlocked, case[1], "bow with %s cleared" % str(case[0]))
		assert_eq(player.war_cry_unlocked, case[2], "war cry with %s cleared" % str(case[0]))
		var hud: GameHud = field.get_node("Hud") as GameHud
		assert_eq(hud.is_skill_bar_visible("bow"), case[1], "its bar follows the unlock")
		assert_eq(hud.is_skill_bar_visible("war_cry"), case[2], "both of them")
		field.free()


func test_pressing_a_locked_skill_says_so_and_does_nothing() -> void:
	var player: Player = _player(false, false)
	var blocked: Array[StringName] = []
	player.skill_locked.connect(func(skill: StringName) -> void: blocked.append(skill))
	_press(&"bow", player)
	_press(&"war_cry", player)
	assert_eq(blocked, [&"bow", &"war_cry"] as Array[StringName], "the player is told which skill is locked")
	assert_eq(player.get_state_name(), "IDLE", "and nothing happens")
	assert_true(_arrows(player).is_empty(), "no arrow")


func test_the_bow_fires_a_light_quick_arrow_with_a_very_short_cooldown() -> void:
	var player: Player = _player()
	_press(&"bow", player)
	assert_eq(player.get_state_name(), "BOW", "he draws the bow")
	assert_true(_arrows(player).is_empty(), "the arrow leaves after a short draw")
	_tick_player(player, player.stats.bow_windup + 0.05)
	var arrows: Array[Arrow] = _arrows(player)
	assert_eq(arrows.size(), 1, "one arrow flies")
	if arrows.size() == 1:
		var hitbox: HitboxComponent = arrows[0].get_node("Hitbox") as HitboxComponent
		assert_almost_eq(hitbox.damage, player.stats.base_damage * player.stats.bow_damage_multiplier, "it hits for the bow damage")
		assert_true(hitbox.damage < player.stats.base_damage * 0.6, "lighter than a plain cut (%.0f against %.0f)" % [hitbox.damage, player.stats.base_damage])
		assert_true(float(arrows[0].get("_range")) >= 1400.0, "and flies far (%.0f px)" % float(arrows[0].get("_range")))
		assert_true(float(arrows[0].get("_speed")) >= 1200.0, "fast")
	var cooldowns: Dictionary = player.get_ability_cooldowns()
	assert_almost_eq((cooldowns["bow"] as Vector2).y, 0.4, "a very short cooldown (0.4 s)")
	assert_true(player.stats.bow_windup + player.stats.bow_recovery <= player.stats.bow_cooldown, "and the shot is over before it ends")
	assert_true(player.stats.bow_windup <= 0.2, "fast to fire (%.2f s)" % player.stats.bow_windup)
	_tick_player(player, player.stats.bow_windup + player.stats.bow_recovery)
	_press(&"bow", player)
	assert_eq(_arrows(player).size(), 1, "no second arrow while it cools down")


func test_the_arrow_reaches_a_far_enemy() -> void:
	var player: Player = _player()
	var far: Enemy = _enemy(1750.0)
	_press(&"bow", player)
	_tick_player(player, player.stats.bow_windup + 0.05)
	var arrows: Array[Arrow] = _arrows(player)
	assert_eq(arrows.size(), 1, "an arrow flew")
	var health: HealthComponent = far.get_node("HealthComponent") as HealthComponent
	var before: float = health.current_health
	var hitbox: HitboxComponent = arrows[0].get_node("Hitbox") as HitboxComponent
	assert_true(hitbox.try_hit(far.get_hurtbox()), "it hurts an enemy 1250 px away (the range is %.0f)" % float(arrows[0].get("_range")))
	assert_true(health.current_health < before, "for real damage")
	assert_true(float(arrows[0].get("_range")) >= 1250.0, "which is within its range")
	assert_true(FigureKinds.pose(InkFigure.Kind.SAMURAI, &"shoot").grip.x > 20.0, "and the samurai has a shooting pose")


func test_the_war_cry_goes_out_once_and_cools_down_for_25_seconds() -> void:
	var player: Player = _player()
	var cries: Array[Vector2] = []
	player.war_cry_released.connect(func(origin: Vector2) -> void: cries.append(origin))
	assert_almost_eq(player.stats.war_cry_cooldown, 25.0, "25 s cooldown")
	assert_almost_eq(player.stats.war_cry_duration, 8.0, "8 s of rally")
	assert_almost_eq(player.stats.war_cry_damage_bonus, 0.3, "+30% damage")
	assert_almost_eq(player.stats.war_cry_speed_bonus, 0.3, "+30% attack speed")
	_press(&"war_cry", player)
	assert_eq(player.get_state_name(), "WAR_CRY", "he shouts")
	_tick_player(player, player.stats.war_cry_windup + player.stats.war_cry_recovery + 0.1)
	assert_eq(cries.size(), 1, "the cry went out once")
	assert_eq(player.get_state_name(), "IDLE", "and he is free again")
	assert_almost_eq(((player.get_ability_cooldowns()["war_cry"]) as Vector2).y, 25.0, "the bar counts 25 s")
	_press(&"war_cry", player)
	_tick_player(player, 1.0)
	assert_eq(cries.size(), 1, "no second cry while it cools down")


func test_the_war_cry_rallies_only_the_allies_near_him() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path: String = SAVE_DIR + "war_cry_save.json"
	SaveManager.new(path).save_progress(PlayerProgress.new())
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", path)
	field.set("settings_path", SAVE_DIR + "war_cry_settings.cfg")
	add_to_tree(field)
	var near: Ally = _ally(800.0)
	var far: Ally = _ally(1900.0)
	field.call(&"_on_war_cry_released", Vector2(500.0, 880.0))
	assert_true(near.is_rallied(), "the ally 300 px away is rallied")
	assert_true(not far.is_rallied(), "the ally 1400 px away is not")
	assert_almost_eq(near.get_war_cry_damage_multiplier(), 1.3, "+30% damage")
	assert_almost_eq(near.get_war_cry_speed_multiplier(), 1.3, "+30% attack speed")
	field.call(&"_on_war_cry_released", Vector2(500.0, 880.0))
	assert_almost_eq(near.get_war_cry_damage_multiplier(), 1.3, "a second cry does not stack")
	for i: int in 60 * 9:
		near._tick_war_cry(STEP)
	assert_true(not near.is_rallied(), "it wears off after 8 seconds")
	assert_almost_eq(near.get_war_cry_damage_multiplier(), 1.0, "damage back to normal")
	assert_almost_eq(near.get_war_cry_speed_multiplier(), 1.0, "and speed")


func test_a_rallied_ally_attacks_faster() -> void:
	var frames: Array[int] = []
	for rallied: bool in [false, true]:
		var ally: Ally = _ally(500.0)
		var enemy: Enemy = _enemy(540.0)
		if rallied:
			ally.apply_war_cry(8.0, 0.3, 0.3)
		var count: int = 0
		var hitbox: HitboxComponent = ally.get_node("Hitbox") as HitboxComponent
		while count < 600 and not hitbox.is_active():
			ally._physics_process(STEP)
			count += 1
		frames.append(count)
		ally.free()
		enemy.free()
	assert_true(frames[1] < frames[0], "the rallied ally's blow lands sooner (%d against %d frames)" % [frames[1], frames[0]])


func test_the_new_skills_have_hud_bars_and_touch_buttons_that_press_their_keys() -> void:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	hud.set_skills_unlocked(true, false)
	assert_true(hud.is_skill_bar_visible("bow") and not hud.is_skill_bar_visible("war_cry"), "only the unlocked skill has a bar")
	hud.set_skills_unlocked(true, true)
	assert_true(hud.is_skill_bar_visible("war_cry"), "both once unlocked")
	var controls: TouchControls = add_to_tree(TOUCH_SCENE.instantiate()) as TouchControls
	var viewport_size: Vector2 = controls.get_viewport().get_visible_rect().size
	controls.apply_layout(viewport_size, Rect2(Vector2.ZERO, viewport_size), 1.0, false)
	controls.set_active(true)
	controls.set_skills_unlocked(false, false)
	for key: String in ["bow", "war_cry"]:
		var locked: TouchActionButton = controls.find_child("%sButton" % ("Bow" if key == "bow" else "WarCry"), true, false) as TouchActionButton
		assert_true(locked.visible and locked.is_locked(), "the %s button stays, locked with a padlock" % key)
	controls.set_skills_unlocked(true, true)
	for pair: Array in [["bow", &"bow"], ["war_cry", &"war_cry"]]:
		var rect: Rect2 = controls.get_widget_rect(pair[0])
		assert_true(rect.size.x >= TouchLayout.MIN_TOUCH_TARGET, "the %s button is finger-sized" % pair[0])
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.index = 7
		touch.position = rect.get_center()
		touch.pressed = true
		assert_true(controls.handle_input(touch), "a touch on %s is taken" % pair[0])
		assert_true(Input.is_action_pressed(pair[1]), "and presses %s" % pair[1])
		touch = InputEventScreenTouch.new()
		touch.index = 7
		touch.position = rect.get_center()
		touch.pressed = false
		controls.handle_input(touch)
		controls.release_all()


func test_all_touch_buttons_fit_the_phone_without_overlapping() -> void:
	var names: Array = TouchLayout.ACTION_BUTTONS.keys()
	var cluster: Rect2 = Rect2(Vector2.ZERO, TouchLayout.ACTION_CLUSTER_SIZE)
	for i: int in names.size():
		var rect: Rect2 = TouchLayout.ACTION_BUTTONS[names[i]]
		assert_true(cluster.encloses(rect), "%s is inside the cluster" % names[i])
		assert_true(rect.size.x >= 130.0 and rect.size.y >= 130.0, "%s is big enough to hit" % names[i])
		for j: int in range(i + 1, names.size()):
			# The buttons are circles, so they may sit diagonally with their corners' boxes overlapping.
			var other: Rect2 = TouchLayout.ACTION_BUTTONS[names[j]]
			var gap: float = rect.get_center().distance_to(other.get_center()) - rect.size.x * 0.5 - other.size.x * 0.5
			assert_true(gap >= 4.0, "%s and %s do not touch (gap %.0f)" % [names[i], names[j], gap])
	for size: Vector2 in [Vector2(1920.0, 1080.0), Vector2(2341.0, 1080.0), Vector2(2560.0, 1080.0), Vector2(1664.0, 1080.0)]:
		for ui_scale: float in [GameSettings.MIN_UI_SCALE, 1.0, 1.2]:
			for left_handed: bool in [false, true]:
				var rects: Dictionary = TouchLayout.compute(size, Rect2(Vector2.ZERO, size), ui_scale, left_handed, 6)
				var label: String = "%s scale %.2f left %s" % [str(size), ui_scale, str(left_handed)]
				for key: String in rects:
					assert_true(Rect2(Vector2.ZERO, size).encloses(rects[key]), "%s: %s is on screen" % [label, key])
				var keys: Array = rects.keys()
				for i: int in keys.size():
					for j: int in range(i + 1, keys.size()):
						assert_true(not (rects[keys[i]] as Rect2).intersects(rects[keys[j]]), "%s: %s and %s do not overlap" % [label, keys[i], keys[j]])
