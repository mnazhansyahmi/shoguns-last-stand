extends "res://tests/test_case.gd"
## The cleaned-up keyboard HUD: two blocks (the vitals: Ultimate ring medallion, health blade, spirit and gate bars; one
## row of round skill icons), the icon's cooldown
## sweep, glow, key badge and padlock, the stance as an icon, and the gate tab that shows only while the gate is attacked.

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const BATTLEFIELD_SCRIPT: GDScript = preload("res://scenes/battlefield/battlefield.gd")
const ICON_IDS: Array[String] = ["dash", "heavy", "slash", "bow", "war_cry", "stance"]


func _hud() -> GameHud:
	return add_to_tree(HUD_SCENE.instantiate()) as GameHud


func test_the_top_left_is_two_blocks_the_bars_and_one_row_of_icons() -> void:
	var hud: GameHud = _hud()
	var top_left: Control = hud.get_node("Margin/TopLeft")
	var names: Array[String] = []
	for child: Node in top_left.get_children():
		names.append(String(child.name))
	assert_eq(names, ["Vitals", "SkillRow"] as Array[String], "two blocks and nothing else")
	var vitals: Control = hud.get_node("%Vitals")
	assert_eq(vitals.get_child_count(), 4, "the vitals hold the health blade, spirit bar, gate bar and Ultimate ring")
	for path: String in ["%HealthBlade", "%SpiritBar", "%GateBar", "%UltimateRing"]:
		var gauge: Control = hud.get_node(path) as Control
		assert_true(gauge is HudGauge, "%s is a drawn HUD gauge" % path)
		assert_true(Rect2(Vector2.ZERO, vitals.custom_minimum_size).encloses(Rect2(gauge.position, gauge.size)), "%s sits inside the vitals block" % path)
	var row: Control = hud.get_node("%SkillRow")
	assert_eq(row.get_child_count(), 6, "one row of six icons")
	var width: float = 0.0
	for child: Node in row.get_children():
		width += (child as Control).custom_minimum_size.x
	assert_true(width + 5.0 * 12.0 <= vitals.custom_minimum_size.x, "the row is no wider than the vitals (%.0f)" % width)


func test_the_icons_are_round_skill_icons_in_order_with_their_keys() -> void:
	var hud: GameHud = _hud()
	var row: Control = hud.get_node("%SkillRow")
	var keys: Dictionary = {"dash": "L", "heavy": "K", "slash": "U", "bow": "E", "war_cry": "Q", "stance": "F"}
	for i: int in ICON_IDS.size():
		var icon: SkillIcon = hud.get_skill_icon(ICON_IDS[i])
		assert_eq(row.get_child(i), icon, "%s is icon %d" % [ICON_IDS[i], i + 1])
		assert_almost_eq(icon.custom_minimum_size.x, icon.custom_minimum_size.y, "%s is square (drawn as a disc)" % ICON_IDS[i])
		assert_eq(icon.key_hint, keys[ICON_IDS[i]], "%s shows its key" % ICON_IDS[i])
		assert_true(not icon.tooltip_text.is_empty(), "%s has a tooltip" % ICON_IDS[i])
	assert_eq(hud.get_node_or_null("Margin/TopLeft/StanceLabel"), null, "there is no separate 'Allies: CHARGE' line")
	assert_eq(hud.get_node_or_null("%AbilityRow"), null, "and no row of timer bars")


func test_a_cooling_skill_shows_a_dark_sweep_and_its_seconds_and_a_ready_one_glows_without_text() -> void:
	var hud: GameHud = _hud()
	var dash: SkillIcon = hud.get_skill_icon("dash")
	assert_true(dash.is_ready() and dash.cooldown_text().is_empty(), "ready: a glow and no text")
	assert_almost_eq(dash.cooldown_fraction(), 0.0, "nothing to sweep")
	hud.set_ability_cooldowns({"dash": Vector2(2.5, 5.0), "heavy": Vector2(0.0, 1.0), "slash": Vector2(12.0, 12.0)})
	assert_true(not dash.is_ready(), "cooling down: no glow")
	assert_almost_eq(dash.cooldown_fraction(), 0.5, "half the time is left")
	assert_eq(dash.cooldown_text(), "2.5", "with the seconds on it")
	assert_eq(hud.get_skill_icon("slash").cooldown_text(), "12", "ten seconds or more are whole seconds")
	assert_true(hud.get_skill_icon("heavy").is_ready(), "a skill with no time left is ready")
	hud.set_ability_cooldowns({"dash": Vector2(0.0, 5.0)})
	assert_true(dash.is_ready() and dash.cooldown_text().is_empty(), "and the sweep goes when it is ready again")


func test_a_locked_skill_is_dimmed_with_a_padlock_and_says_how_to_unlock_it_only_as_a_tooltip() -> void:
	var hud: GameHud = _hud()
	hud.set_skills_unlocked(false, false)
	var bow: SkillIcon = hud.get_skill_icon("bow")
	assert_true(bow.is_locked() and not bow.is_ready(), "locked, so not ready (no glow)")
	assert_eq(bow.tooltip_text, "Clear stage 1", "the tooltip says Clear stage 1")
	assert_eq(hud.get_skill_icon("war_cry").tooltip_text, "Clear stage 2", "and Clear stage 2 for the War Cry")
	assert_eq(bow.cooldown_text(), "", "no text on the icon itself")
	var heard: Array[String] = []
	bow.locked_pressed.connect(func(text: String) -> void: heard.append(text))
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	bow._gui_input(click)
	assert_eq(heard, ["Clear stage 1"] as Array[String], "tapping it says what unlocks it")
	hud.set_skills_unlocked(true, true)
	assert_true(not bow.is_locked() and bow.tooltip_text == "Bow", "unlocked, its tooltip is its name again")
	heard.clear()
	bow._gui_input(click)
	assert_true(heard.is_empty(), "and tapping does nothing")


func test_the_stance_is_an_icon_a_sword_for_charge_and_a_shield_for_hold() -> void:
	var hud: GameHud = _hud()
	var icon: SkillIcon = hud.get_skill_icon("stance")
	hud.set_stance("CHARGE")
	assert_eq(icon.kind, UpgradeIcon.Kind.STANCE_CHARGE, "CHARGE is a sword")
	assert_eq(icon.tooltip_text, "Allies: CHARGE", "and says so")
	hud.set_stance("HOLD")
	assert_eq(icon.kind, UpgradeIcon.Kind.STANCE_HOLD, "HOLD is a shield")
	assert_eq(hud.get_stance_name(), "HOLD", "the HUD remembers it")
	assert_true(not icon.is_locked() and icon.is_ready(), "the stance has no cooldown")


func test_every_symbol_draws_at_any_size_without_an_error() -> void:
	var sheet: Control = Control.new()
	add_to_tree(sheet)
	for kind: int in UpgradeIcon.Kind.size():
		for size_px: float in [24.0, 66.0, 144.0]:
			var icon: UpgradeIcon = UpgradeIcon.new()
			icon.setup(kind as UpgradeIcon.Kind, size_px)
			sheet.add_child(icon)
			icon.queue_redraw()
	var hud: GameHud = _hud()
	for id: String in ICON_IDS:
		hud.get_skill_icon(id).queue_redraw()
	assert_eq(UpgradeIcon.Kind.size(), 12, "eleven symbols: the eight upgrade ones plus the heavy strike and two stances")


func test_the_icon_row_is_for_the_keyboard_and_touch_mode_keeps_its_rules() -> void:
	var hud: GameHud = _hud()
	var row: Control = hud.get_node("%SkillRow")
	hud.set_touch_mode(true)
	assert_true(not row.is_visible_in_tree(), "touch mode hides the icon row (the touch buttons show the cooldowns and the stance)")
	assert_true((hud.get_node("%UltimateRing") as Control).is_visible_in_tree(), "the vitals stay")
	hud.set_touch_mode(false)
	assert_true(row.is_visible_in_tree(), "keyboard mode shows it again")
	assert_true(TouchLayout.smallest_touch_target(1.0) >= TouchLayout.MIN_TOUCH_TARGET, "every touch button is still at least 44 pt")


func test_the_gate_tab_shows_only_while_the_gate_is_attacked_or_was_just_damaged() -> void:
	var hud: GameHud = _hud()
	hud.set_edge_indicators(true, 1.0, 0, false, 0, false)
	assert_true(not hud.get_gate_indicator().visible, "an untouched gate off screen has no tab (the Gate bar shows its health)")
	hud.set_edge_indicators(true, 0.8, 0, true, 0, false)
	assert_true(hud.get_gate_indicator().visible, "a gate damaged in the last seconds has one")
	hud.set_edge_indicators(true, 0.8, 2, true, 0, false)
	assert_true(hud.get_gate_indicator().visible and hud.get_gate_indicator().detail.contains("2 at the gate"), "so does a gate with enemies at it")
	hud.set_edge_indicators(true, 0.8, 0, false, 0, false)
	assert_true(not hud.get_gate_indicator().visible, "and it goes again once the alert is over")
	hud.set_edge_indicators(false, 0.5, 0, true, 0, false)
	assert_true(not hud.get_gate_indicator().visible, "a gate on screen never has a tab")
	assert_eq(BATTLEFIELD_SCRIPT.GATE_ALERT_MSEC, 3000, "the alert lasts three seconds after the last hit")


func test_figure_art_is_shared_and_poses_are_frozen_game_figures() -> void:
	var hud: GameHud = _hud()
	var first: Texture2D = FigureSkillArt.texture(hud, UpgradeIcon.Kind.DASH)
	assert_eq(first, FigureSkillArt.texture(hud, UpgradeIcon.Kind.DASH), "reusing an icon never creates another render target")
	assert_true(first != FigureSkillArt.texture(hud, UpgradeIcon.Kind.BOW), "each skill has its own picture")
	for entry: Array in [[UpgradeIcon.Kind.DASH, 3], [UpgradeIcon.Kind.STANCE_CHARGE, 2], [UpgradeIcon.Kind.BOW, 1]]:
		var stage: FigureSkillArt.Stage = FigureSkillArt.Stage.new()
		stage.icon_kind = entry[0]
		add_to_tree(stage)
		assert_eq(stage.get_child_count(), entry[1], "dash has two afterimages; charge has two allies")
		for child: Node in stage.get_children():
			var figure: InkFigure = child as InkFigure
			assert_true(figure != null and not figure.is_processing(), "actual InkFigure, frozen without an animation loop")
			if entry[0] == UpgradeIcon.Kind.DASH and figure == stage.get_child(0):
				assert_almost_eq(figure.modulate.a, 0.18, "refresh preserves the faded afterimage")
			if entry[0] == UpgradeIcon.Kind.BOW:
				assert_true(figure.pose.bow_out > 0.5 and figure.pose.bow_draw > 0.8, "the samurai draws his actual yumi")


func test_keyboard_summons_use_clickable_cached_portraits_and_keep_costs() -> void:
	var hud: GameHud = _hud()
	var roster: AllyRoster = load("res://data/allies/roster.tres")
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	hud.configure_summons(roster.get_unlocked(progress))
	for slot: int in 6:
		var button: TouchActionButton = hud.get_summon_button(slot)
		assert_eq(button.key_hint, str(slot + 1), "keyboard badges stay 1-6")
		assert_true(button.mouse_enabled and button.portrait_kind >= 0, "a real portrait, clickable with the mouse")
		assert_almost_eq(button.portrait_rect().position.y, -button.size.x * 0.25, "portrait breaks the circle by a quarter")
	hud.set_summon_state(0, 30, 2.0, 4.0, false)
	var button: TouchActionButton = hud.get_summon_button(0)
	assert_eq(button.sub_caption, "30 SE", "cost remains while cooling down")
	assert_true(not button.available and button.unavailable_text == "need 30", "unaffordable portrait dims and explains the cost")
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = button.size * 0.5
	button._gui_input(down)
	assert_true(button.is_held() and Input.is_action_pressed("summon_1"), "mouse uses the same action as keyboard and touch")
	button.release()
	assert_true(not Input.is_action_pressed("summon_1"), "release never leaves the action held")


func test_tutorial_controls_only_show_on_uncleared_stage_one_and_debug_text_is_gone() -> void:
	var hud: GameHud = _hud()
	for stage_id: String in ["stage_1", "stage_2", "stage_5"]:
		for cleared: bool in [false, true]:
			hud.set_tutorial_hint(stage_id, cleared)
			hud.set_touch_mode(false)
			assert_eq((hud.get_node("%HintLabel") as Control).visible, stage_id == "stage_1" and not cleared, "only the first tutorial battle shows the controls line")
			hud.set_touch_mode(true)
			assert_true(not (hud.get_node("%HintLabel") as Control).visible, "touch never shows keyboard help")
	assert_true(not (hud.get_node("%DebugHintLabel") as Control).visible, "no debug text in battle")


func test_button_plate_and_badge_text_shaping_is_cached_and_bounded() -> void:
	var button: TouchActionButton = add_to_tree(TouchActionButton.new()) as TouchActionButton
	var font: Font = button.get_theme_default_font()
	var line: TextLine = button._text_line(font, "30 SE", 18)
	assert_eq(button._text_line(font, "30 SE", 18), line, "cooldown redraws reuse shaped plate text")
	for i: int in 100:
		button._text_line(font, str(i), 18)
	assert_true(button.get("_text_lines").size() <= 64, "changing cooldown values cannot grow the cache forever")
