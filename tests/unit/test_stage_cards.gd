extends "res://tests/test_case.gd"
## The stage select's cards: a picture of each stage's own atmosphere, a gold check when cleared, a padlock with "Clear
## <previous stage>" when locked, a boss crest on the boss stage, and the details only in the side panel for the selected card.

const STAGE_SELECT_SCENE: PackedScene = preload("res://scenes/stage_select/stage_select.tscn")
const SAVE_DIR: String = "user://test_stage_cards/"


func _select(cleared: Array[String]) -> Control:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = cleared.duplicate()
	SaveManager.new(SAVE_DIR + "stages_save.json").save_progress(progress)
	var select: Control = STAGE_SELECT_SCENE.instantiate()
	select.set("save_path", SAVE_DIR + "stages_save.json")
	add_to_tree(select)
	return select


func _stage(index: int) -> StageData:
	return StageProgression.default_region().stages[index]


func test_every_stage_has_its_own_atmosphere_a_tagline_and_only_stage_five_has_a_boss() -> void:
	var themes: Dictionary = {}
	for i: int in 5:
		var stage: StageData = _stage(i)
		assert_true(stage.atmosphere != null, "%s has an atmosphere to draw its picture from" % stage.display_name)
		themes[stage.atmosphere.theme_id] = true
		assert_true(not stage.tagline.is_empty() and stage.tagline.length() <= 32, "%s has a short tagline (%s)" % [stage.display_name, stage.tagline])
		assert_eq(stage.short_description(), stage.tagline, "the card shows the tagline")
		assert_eq(stage.has_boss(), i == 4, "only stage 5 has a boss (%d)" % (i + 1))
	assert_eq(themes.size(), 5, "five different skies")
	assert_eq(_stage(4).boss_name(), "The Fallen Daimyo", "the boss is named")
	var plain: StageData = StageData.new()
	plain.description = "The first attack. Learn to fight."
	assert_eq(plain.short_description(), "The first attack.", "with no tagline the first sentence is used")


func test_a_card_per_stage_with_its_state() -> void:
	var select: Control = _select(["stage_1", "stage_2"] as Array[String])
	for i: int in 5:
		var card: StageCard = select.get_stage_card(i)
		assert_true(card != null, "card %d" % (i + 1))
		assert_true(card.custom_minimum_size.y >= TouchLayout.MIN_TOUCH_TARGET and card.custom_minimum_size.x >= TouchLayout.MIN_TOUCH_TARGET, "card %d is a big touch target" % (i + 1))
		assert_eq(card.focus_mode, Control.FOCUS_ALL, "card %d takes keyboard and gamepad focus" % (i + 1))
		assert_eq(card.cleared, i < 2, "cleared: stages 1 and 2")
		assert_eq(card.unlocked, i < 3, "unlocked: up to stage 3")
	assert_eq(select.get_stage_card(2).get_locked_text(), "", "an open card has no lock text")
	assert_eq(select.get_stage_card(3).get_locked_text(), "Clear Misty Grove", "a locked card says which stage to clear")
	assert_eq(select.get_stage_card(4).get_locked_text(), "Clear Broken Shrine", "each names the one before it")
	assert_eq(select.get_stage_card(0).get_locked_text(), "", "stage 1 is never locked")


func test_no_cleared_or_locked_text_is_left_on_the_screen() -> void:
	var select: Control = _select(["stage_1"] as Array[String])
	for label: Node in select.find_children("*", "Label", true, false):
		var text: String = (label as Label).text.to_upper()
		assert_true(not text.contains("[CLEARED]") and not text.contains("[LOCKED]") and not text.contains("[NEW]"), "%s has no status text" % label.name)
	for button: Node in select.find_children("*", "Button", true, false):
		assert_true(not (button as Button).text.to_upper().contains("[CLEARED]"), "%s has no [CLEARED]" % button.name)


func test_the_selected_card_is_the_next_stage_and_the_side_panel_shows_only_its_details() -> void:
	var select: Control = _select(["stage_1"] as Array[String])
	assert_eq(select.get_selected_index(), 1, "the first stage not cleared is selected")
	assert_true(select.get_stage_card(1).is_selected and not select.get_stage_card(0).is_selected, "and only it")
	assert_eq((select.get_node("%DetailName") as Label).text, "2. Bamboo Path", "the panel names it")
	assert_eq((select.get_node("%DetailDescription") as Label).text, _stage(1).description, "with the full description")
	var stats: String = (select.get_node("%DetailStats") as Label).text
	assert_true(stats.contains("waves") and stats.contains("soldiers") and stats.contains("Oni Brute"), "its waves and enemies: %s" % stats)
	var rewards: String = (select.get_node("%DetailRewards") as Label).text
	assert_true(rewards.contains("First clear: %d gold" % _stage(1).get_full_clear_gold()) and rewards.contains("Replay: %d gold" % floori(_stage(1).get_full_clear_gold() * 0.5)), "the first-clear and replay gold: %s" % rewards)
	assert_true(not rewards.contains("replays pay"), "an uncleared stage does not talk about replays yet")
	select.get_stage_card(0)._on_focus_entered()
	assert_eq(select.get_selected_index(), 0, "focusing another card selects it")
	assert_true((select.get_node("%DetailRewards") as Label).text.contains("replays pay 50%"), "a cleared stage says what its replays pay")
	for i: int in 5:
		var face: Control = select.get_stage_card(i).get_node("Face")
		assert_eq(face.get_child_count(), 0, "card %d carries no detail labels of its own" % (i + 1))


func test_a_locked_stage_shows_what_unlocks_it_and_cannot_be_played() -> void:
	var select: Control = _select([] as Array[String])
	select.get_stage_card(4)._on_focus_entered()
	var lock: Label = select.get_node("%DetailLock")
	assert_true(lock.visible and lock.text == "Clear Broken Shrine first.", "the panel says what to clear: %s" % lock.text)
	assert_true(not (select.get_node("%DetailStats") as Label).visible and not (select.get_node("%DetailRewards") as Label).visible, "and hides the stats")
	var play: Button = select.get_play_button()
	assert_true(play.disabled and play.text == "Locked", "Play is disabled")
	assert_true(play.custom_minimum_size.y >= TouchLayout.MIN_TOUCH_TARGET, "and still a full-size button")
	select.get_stage_card(0)._on_focus_entered()
	assert_true(not play.disabled and play.text == "Play", "an open stage can be played")


func test_confirm_or_a_double_click_starts_a_stage_but_a_tap_only_selects_it() -> void:
	var select: Control = _select(["stage_1"] as Array[String])
	var open: StageCard = select.get_stage_card(1)
	var locked: StageCard = select.get_stage_card(3)
	var started: Array[int] = []
	var picked: Array[int] = []
	open.activated.connect(func(card: StageCard) -> void: started.append(card.index))
	locked.activated.connect(func(card: StageCard) -> void: started.append(card.index))
	open.selected.connect(func(card: StageCard) -> void: picked.append(card.index))
	var accept: InputEventAction = InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	open._gui_input(accept)
	assert_eq(started, [1] as Array[int], "Enter / the confirm button starts the focused stage")
	started.clear()
	locked._gui_input(accept)
	assert_true(started.is_empty(), "but never a locked one")
	var tap: InputEventMouseButton = InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	open._gui_input(tap)
	assert_true(started.is_empty() and picked.has(1), "one click or tap only selects it, so its details can be read")
	tap.double_click = true
	open._gui_input(tap)
	assert_eq(started, [1] as Array[int], "a double click starts it")
	started.clear()
	locked._gui_input(tap)
	assert_true(started.is_empty(), "a double click on a locked card does nothing")


func test_cards_balance_across_rows_and_share_the_width() -> void:
	var gap: float = 22.0
	for width: float in [900.0, 1262.0, 1681.0, 2400.0]:
		var layout: Vector2 = StageSelect.card_layout(5, width)
		var columns: int = int(layout.x)
		assert_true(columns >= 1 and columns <= 5, "%d columns in %.0f px" % [columns, width])
		assert_true(layout.y >= StageCard.CARD_SIZE.x and layout.y <= StageSelect.MAX_CARD_WIDTH, "each card is a sane width (%.0f)" % layout.y)
		assert_true(layout.y * columns + gap * (columns - 1) <= width + 1.0 or layout.y == StageCard.CARD_SIZE.x, "a row fits the space")
	assert_eq(int(StageSelect.card_layout(5, 1681.0).x), 3, "five cards in room for four make three and two")
	assert_eq(int(StageSelect.card_layout(5, 1262.0).x), 3, "and three at desktop width")
	assert_eq(int(StageSelect.card_layout(5, 400.0).x), 1, "one column when there is only room for one")


func test_the_preview_covers_the_card_and_paints_with_the_stage_theme_only() -> void:
	var fit: Transform2D = StagePreview.cover_transform(Vector2(384.0, 216.0))
	assert_almost_eq(fit.x.x, 384.0 / 1920.0, "a 16:9 picture is scaled to fit exactly", 0.0001)
	var wide: Transform2D = StagePreview.cover_transform(Vector2(540.0, 214.0))
	assert_almost_eq(wide.x.x, 540.0 / 1920.0, "a wider card scales to its width")
	assert_true(wide.origin.y < 0.0, "and crops the picture's top and bottom rather than stretching it")
	var theme_before: AtmosphereTheme = Atmosphere.current()
	var preview: StagePreview = StagePreview.new()
	preview.size = Vector2(380.0, 214.0)
	add_to_tree(preview)
	preview.setup(_stage(4).atmosphere)
	assert_eq(preview.theme_to_paint.theme_id, _stage(4).atmosphere.theme_id, "it paints with the stage's own theme")
	assert_true(Atmosphere.current() == theme_before, "and never changes the game's current atmosphere")


func test_the_boss_stage_is_the_one_that_gets_the_crest() -> void:
	var select: Control = _select([] as Array[String])
	for i: int in 5:
		var card: StageCard = select.get_stage_card(i)
		card.queue_redraw()
		card.get_node("Face").queue_redraw()
		assert_eq(card.stage.has_boss(), i == 4, "card %d %s a crest" % [i + 1, "has" if i == 4 else "has no"])
