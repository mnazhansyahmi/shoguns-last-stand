extends "res://tests/test_case.gd"
## Playtest feedback, part 2: every touch button and every keyboard-mode HUD skill shows its key, the text is short
## enough to fit, and a locked skill shows a padlock and "Clear stage N".

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
## Touch widget -> its key.
const TOUCH_KEYS: Dictionary = {"attack": "J", "heavy": "K", "dash": "L", "slash": "U", "ultimate": "I", "war_cry": "Q",
		"bow": "E", "stance": "F", "summon_1": "1", "summon_2": "2", "summon_3": "3", "summon_4": "4", "summon_5": "5",
		"summon_6": "6"}


func _controls() -> TouchControls:
	var controls: TouchControls = add_to_tree(TOUCH_SCENE.instantiate()) as TouchControls
	var viewport_size: Vector2 = controls.get_viewport().get_visible_rect().size
	controls.set_summon_count(6)
	controls.apply_layout(viewport_size, Rect2(Vector2.ZERO, viewport_size), 1.0, false)
	return controls


func _button(controls: TouchControls, widget: String) -> TouchActionButton:
	return controls.get("_buttons")[widget] as TouchActionButton


func test_keys_are_read_from_the_input_map() -> void:
	for action: StringName in [&"attack", &"heavy_attack", &"dash", &"spirit_slash", &"ultimate", &"war_cry", &"bow", &"stance"]:
		assert_true(not SkillHints.key_label(action).is_empty(), "%s has a key to show" % action)
	assert_eq(SkillHints.key_label(&"war_cry"), "Q", "Q is the War Cry")
	assert_eq(SkillHints.key_label(&"bow"), "E", "E is the Bow")
	assert_eq(SkillHints.key_label(&"stance"), "F", "F is the stance")
	assert_eq(SkillHints.key_label(&"no_such_action"), "", "an unknown action has no key")


func test_every_touch_button_shows_its_key() -> void:
	var controls: TouchControls = _controls()
	for widget: String in TOUCH_KEYS:
		assert_eq(_button(controls, widget).key_hint, TOUCH_KEYS[widget], "the %s button shows %s" % [widget, TOUCH_KEYS[widget]])


func test_the_hud_skill_bars_show_their_keys_and_the_hint_line_lists_them() -> void:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	for pair: Array in [["dash", "L"], ["heavy", "K"], ["slash", "U"], ["bow", "E"], ["war_cry", "Q"]]:
		assert_eq(hud.get_skill_bar(pair[0]).key_hint, pair[1], "the %s bar shows %s" % pair)
	assert_eq((hud.get_node("%UltimateBar") as FillBar).key_hint, "I", "the Ultimate bar shows I")
	var hint: String = (hud.get_node("%HintLabel") as Label).text
	for part: String in ["J attack", "K heavy", "L dash", "U spirit slash", "I ultimate", "Q war cry", "E bow", "F allies", "1-6 summon"]:
		assert_true(hint.contains(part), "the key line says '%s'" % part)
	hud.set_stance("CHARGE")
	assert_true(hud.get_stance_text().contains("[F]"), "the stance label shows its key")


func test_a_locked_skill_shows_a_padlock_and_the_stage_that_unlocks_it() -> void:
	assert_eq(SkillHints.locked_text("stage_1"), "Clear stage 1", "stage 1")
	assert_eq(SkillHints.locked_text("stage_12"), "Clear stage 12", "two digits")
	assert_eq(SkillHints.locked_text_for(&"bow"), "Clear stage 1", "the Bow comes with stage 1")
	assert_eq(SkillHints.locked_text_for(&"war_cry"), "Clear stage 2", "the War Cry with stage 2")
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	hud.set_skills_unlocked(false, false)
	assert_eq(hud.get_skill_bar("bow").locked_text, "Clear stage 1", "the HUD's Bow bar says how to unlock it")
	assert_eq(hud.get_skill_bar("war_cry").locked_text, "Clear stage 2", "and the War Cry's")
	assert_true(hud.get_skill_bar("bow").visible and hud.is_skill_locked("bow"), "locked skills still have their bar")
	hud.set_skills_unlocked(true, false)
	assert_true(not hud.is_skill_locked("bow") and hud.is_skill_locked("war_cry"), "unlocking the Bow frees only the Bow")
	var controls: TouchControls = _controls()
	controls.set_skills_unlocked(false, true)
	assert_eq(_button(controls, "bow").locked_text, "Clear stage 1", "the touch Bow button is locked")
	assert_true(_button(controls, "bow").visible, "and still shown")
	assert_true(not _button(controls, "war_cry").is_locked(), "the unlocked War Cry button is free")


func test_the_hint_text_fits_inside_its_bar_or_button() -> void:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	hud.set_skills_unlocked(false, false)
	for key: String in ["dash", "heavy", "slash", "bow", "war_cry"]:
		var bar: FillBar = hud.get_skill_bar(key)
		var font: Font = bar.get_theme_default_font()
		var badge: float = bar.custom_minimum_size.y - 8.0 + 12.0
		var value: String = bar.locked_text if bar.is_locked() else "ready"
		var lock: float = bar.custom_minimum_size.y * 0.5 if bar.is_locked() else 0.0
		var text: float = font.get_string_size(bar.caption, HORIZONTAL_ALIGNMENT_LEFT, -1, bar.font_size).x \
				+ font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, bar.font_size).x
		var needed: float = badge + lock + text + 7.0 + 10.0
		assert_true(needed <= bar.custom_minimum_size.x, "the %s bar's text fits (%.0f of %.0f)" % [key, needed, bar.custom_minimum_size.x])
	var controls: TouchControls = _controls()
	controls.set_skills_unlocked(false, false)
	for widget: String in ["bow", "war_cry"]:
		var button: TouchActionButton = _button(controls, widget)
		var font: Font = button.get_theme_default_font()
		var small: int = maxi(int(button.font_size * 0.62), 14)
		for word: String in button.locked_text.split(" ", true, 1):
			assert_true(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x <= button.size.x * 0.8, "'%s' fits in the %s button" % [word, widget])
