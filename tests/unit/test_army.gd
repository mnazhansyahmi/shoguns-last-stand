extends "res://tests/test_case.gd"
## Part 1 of the playtest feedback: the army grows with the stages (and the Command upgrade), and the
## allies have a stance (CHARGE = meet the enemies, HOLD = defend by the gate) with a key, a touch button
## and a HUD label.

const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const SAVE_DIR: String = "user://test_saves/"
const STEP: float = 1.0 / 60.0


func _progress(cleared: int, command_level: int = 0) -> PlayerProgress:
	var progress: PlayerProgress = PlayerProgress.new()
	for i: int in cleared:
		progress.stages_cleared.append("stage_%d" % (i + 1))
	progress.set_upgrade_level("army_command", command_level)
	return progress


func _ally(x: float, charge: bool) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find("ashigaru"), x)
	ally.stance = Ally.Stance.CHARGE if charge else Ally.Stance.HOLD
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally


func _enemy(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	# Keep him where he is: the test is about the ally.
	enemy.set_physics_process(false)
	return enemy


func _summoner() -> SummonManager:
	var energy: SpiritEnergy = add_to_tree(SpiritEnergy.new()) as SpiritEnergy
	energy.max_energy = 500.0
	energy.set_energy(500.0)
	var summoner: SummonManager = SummonManager.new()
	summoner.energy = energy
	add_to_tree(summoner)
	return summoner


func _tick(ally: Ally, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		ally._physics_process(STEP)


# --- Ally cap -----------------------------------------------------------------------

func test_the_ally_cap_starts_at_six_and_grows_one_per_stage_to_eleven() -> void:
	var expected: Array[int] = [6, 7, 8, 9, 10, 11]
	for cleared: int in 6:
		assert_eq(UpgradeApplier.build_ally_cap(_progress(cleared), CATALOG), expected[cleared], "%d stages cleared" % cleared)
	assert_eq(UpgradeApplier.build_ally_cap(_progress(9), CATALOG), 11, "the stage part never passes eleven")
	assert_eq(UpgradeApplier.build_ally_cap(PlayerProgress.new(), CATALOG), 6, "a new player has six")


func test_the_command_upgrade_adds_one_ally_per_level_up_to_three() -> void:
	var command: UpgradeData = CATALOG.find("army_command")
	assert_true(command != null, "the catalog has the Command upgrade")
	assert_eq(command.max_level, 3, "three levels")
	assert_eq(command.target, UpgradeData.Target.ARMY, "it is an army upgrade")
	for level: int in 4:
		assert_eq(UpgradeApplier.build_ally_cap(_progress(0, level), CATALOG), 6 + level, "level %d" % level)
	assert_eq(UpgradeApplier.build_ally_cap(_progress(5, 3), CATALOG), 14, "eleven from the stages and three from Command")
	assert_eq(UpgradeApplier.build_ally_cap(_progress(5, 9), CATALOG), 14, "levels past the maximum add nothing")
	assert_eq(command.describe_bonus(2), "+2 allies on the field", "the shop says what it does")


func test_the_battlefield_uses_the_cap_from_the_save() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path: String = SAVE_DIR + "army_cap_save.json"
	SaveManager.new(path).save_progress(_progress(3, 2))
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", path)
	field.set("settings_path", SAVE_DIR + "army_cap_settings.cfg")
	add_to_tree(field)
	var summoner: SummonManager = field.get_node("World/SummonManager") as SummonManager
	assert_eq(summoner.max_allies, 11, "three stages (+3) and two Command levels (+2) on top of six")


# --- Stance ---------------------------------------------------------------------------

func test_the_default_stance_is_charge_and_it_toggles() -> void:
	var summoner: SummonManager = _summoner()
	assert_eq(summoner.get_stance(), Ally.Stance.CHARGE, "allies charge by default")
	var seen: Array[int] = []
	summoner.stance_changed.connect(func(value: Ally.Stance) -> void: seen.append(value))
	summoner.toggle_stance()
	assert_eq(summoner.get_stance(), Ally.Stance.HOLD, "one press holds")
	summoner.toggle_stance()
	assert_eq(summoner.get_stance(), Ally.Stance.CHARGE, "another charges")
	assert_eq(seen, [Ally.Stance.HOLD, Ally.Stance.CHARGE] as Array[int], "each change is announced")
	assert_eq(SummonManager.stance_name(Ally.Stance.CHARGE), "CHARGE", "named for the HUD")
	assert_eq(SummonManager.stance_name(Ally.Stance.HOLD), "HOLD", "both of them")


func test_the_stance_reaches_every_ally_on_the_field_and_new_ones() -> void:
	var summoner: SummonManager = _summoner()
	var first: Ally = _ally(500.0, true)
	var second: Ally = _ally(560.0, true)
	summoner.set_stance(Ally.Stance.HOLD)
	assert_eq(first.stance, Ally.Stance.HOLD, "the first ally holds")
	assert_eq(second.stance, Ally.Stance.HOLD, "so does the second")
	summoner.set_stance(Ally.Stance.CHARGE)
	assert_eq(first.stance, Ally.Stance.CHARGE, "and they charge again together")
	summoner.ally_slots = [ROSTER.find("ashigaru")] as Array[AllyData]
	summoner.global_position = Vector2(340.0, 880.0)
	summoner.set_stance(Ally.Stance.HOLD)
	var summoned: Array[Ally] = []
	summoner.ally_summoned.connect(func(ally: Ally, _slot: int) -> void: summoned.append(ally))
	assert_eq(summoner.request_summon(0), SummonManager.Result.OK, "a summon works")
	for ally: Ally in summoned:
		track(ally)
	assert_true(summoned.size() == 1 and summoned[0].stance == Ally.Stance.HOLD, "a new ally starts in the current stance")


func test_charging_allies_go_to_enemies_far_away_and_holding_allies_do_not() -> void:
	var charger: Ally = _ally(340.0, true)
	_enemy(1500.0)
	assert_true(charger.select_target() != null, "a charging ally sees an enemy 1100 px away")
	_tick(charger, 3.0)
	var charged_to: float = charger.global_position.x
	assert_true(charged_to > 340.0 + 150.0, "the charging ally advanced (%.0f)" % charged_to)
	charger.free()
	var holder: Ally = _ally(340.0, false)
	assert_true(holder.select_target() == null, "a holding ally does not see him")
	_tick(holder, 3.0)
	assert_true(holder.global_position.x < charged_to - 100.0, "and stays by the gate (%.0f against %.0f)" % [holder.global_position.x, charged_to])


func test_charging_allies_stop_at_the_front_line() -> void:
	var charger: Ally = _ally(1200.0, true)
	_enemy(1750.0)
	_tick(charger, 6.0)
	assert_true(charger.global_position.x <= Ally.CHARGE_FRONT_X + 80.0, "they never walk into the spawn (%.0f)" % charger.global_position.x)
	assert_true(charger.global_position.x > 1200.0, "but they did advance")


func test_charging_allies_wait_where_they_are_when_no_enemy_is_left() -> void:
	var charger: Ally = _ally(900.0, true)
	charger.home_x = 340.0
	_tick(charger, 3.0)
	var waited_at: float = charger.global_position.x
	assert_true(absf(waited_at - 900.0) < 15.0, "no walking back to the gate between waves (%.0f)" % waited_at)
	charger.free()
	var holder: Ally = _ally(900.0, false)
	holder.home_x = 340.0
	_tick(holder, 3.0)
	assert_true(holder.global_position.x < waited_at - 100.0, "a holding ally goes back to its place by the gate (%.0f)" % holder.global_position.x)


func test_the_f_key_is_bound_to_the_stance_action() -> void:
	assert_true(InputMap.has_action(&"stance"), "there is a stance action")
	var bound: bool = false
	for event: InputEvent in InputMap.action_get_events(&"stance"):
		var key: InputEventKey = event as InputEventKey
		if key != null and key.physical_keycode == KEY_F:
			bound = true
	assert_true(bound, "on the F key")


# --- HUD and touch ------------------------------------------------------------------------

func test_the_hud_shows_the_current_stance() -> void:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	var icon: SkillIcon = hud.get_skill_icon("stance")
	hud.set_stance("CHARGE")
	assert_eq(hud.get_stance_name(), "CHARGE", "it is CHARGE")
	assert_eq(icon.kind, UpgradeIcon.Kind.STANCE_CHARGE, "drawn as a sword")
	assert_true(icon.tooltip_text.contains("CHARGE"), "and its tooltip says CHARGE")
	assert_eq(icon.key_hint, "F", "with its key on the badge")
	hud.set_stance("HOLD")
	assert_eq(icon.kind, UpgradeIcon.Kind.STANCE_HOLD, "HOLD is a shield")
	assert_true(icon.tooltip_text.contains("HOLD"), "and says HOLD")
	hud.set_touch_mode(true)
	assert_true(not icon.is_visible_in_tree(), "the phone has the Allies button instead")


func test_the_stance_button_fits_on_phone_screens_without_covering_other_controls() -> void:
	for size: Vector2 in [Vector2(1920.0, 1080.0), Vector2(2340.0, 1080.0), Vector2(2560.0, 1080.0), Vector2(1600.0, 1080.0)]:
		for ui_scale: float in [0.8, 1.0, 1.2]:
			for left_handed: bool in [false, true]:
				var rects: Dictionary = TouchLayout.compute(size, Rect2(Vector2.ZERO, size), ui_scale, left_handed, 6)
				var stance: Rect2 = rects["stance"]
				var label: String = "%s scale %.1f left %s" % [str(size), ui_scale, str(left_handed)]
				assert_true(stance.size.x >= TouchLayout.MIN_TOUCH_TARGET and stance.size.y >= TouchLayout.MIN_TOUCH_TARGET, "%s: a finger-sized button" % label)
				assert_true(Rect2(Vector2.ZERO, size).encloses(stance), "%s: on screen" % label)
				for other: String in ["joystick", "actions", "summons"]:
					assert_true(not stance.intersects(rects[other]), "%s: clear of the %s" % [label, other])


func test_the_stance_touch_button_presses_the_stance_action_and_shows_the_state() -> void:
	var controls: TouchControls = add_to_tree(TOUCH_SCENE.instantiate()) as TouchControls
	var viewport_size: Vector2 = controls.get_viewport().get_visible_rect().size
	controls.apply_layout(viewport_size, Rect2(Vector2.ZERO, viewport_size), 1.0, false)
	controls.set_active(true)
	var rect: Rect2 = controls.get_widget_rect("stance")
	assert_true(rect.size.x >= TouchLayout.MIN_TOUCH_TARGET, "the button is on screen")
	var button: TouchActionButton = controls.find_child("StanceButton", true, false) as TouchActionButton
	assert_eq(button.action, &"stance", "it presses the stance action")
	controls.set_stance_state("HOLD", false)
	assert_eq(button.sub_caption, "HOLD", "it shows the stance")
	controls.set_stance_state("CHARGE", true)
	assert_eq(button.sub_caption, "CHARGE", "and the other one")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 5
	touch.position = rect.get_center()
	touch.pressed = true
	assert_true(controls.handle_input(touch), "a touch on it is taken")
	assert_true(Input.is_action_pressed(&"stance"), "and presses the action")
	touch = InputEventScreenTouch.new()
	touch.index = 5
	touch.position = rect.get_center()
	touch.pressed = false
	controls.handle_input(touch)
	controls.release_all()
	assert_true(controls.get_keep_out_rects().size() >= 4, "leaves keep out of it too")
