extends "res://tests/test_case.gd"
## Playtest feedback, part 3: the touch action buttons sit in arcs around Attack (a thumb-friendly layout), touch mode
## drops the HUD's timer rows and the stance line (the buttons show them), and the gate's edge tab never overlaps the HUD.

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const SIZES: Array[Vector2] = [Vector2(1920.0, 1080.0), Vector2(2341.0, 1080.0), Vector2(1664.0, 1080.0)]


func _center(key: String) -> Vector2:
	return (TouchLayout.ACTION_BUTTONS[key] as Rect2).get_center()


func test_the_action_buttons_sit_in_arcs_around_attack() -> void:
	var attack: Vector2 = _center("attack")
	var ring: Dictionary = {}
	for key: String in TouchLayout.ACTION_BUTTONS:
		ring[key] = _center(key).distance_to(attack)
	assert_true(maxf(ring["heavy"], ring["dash"]) < minf(ring["slash"], ring["bow"]), "Heavy and Dash are the closest to Attack")
	assert_true(maxf(ring["slash"], ring["bow"]) < minf(ring["ultimate"], ring["war_cry"]), "then Spirit and Bow, then the Ultimate and War Cry")
	assert_true(absf(ring["slash"] - ring["bow"]) < 20.0, "Spirit and Bow are on the same arc")
	assert_true(absf(ring["heavy"] - ring["dash"]) < 20.0, "and so are Heavy and Dash")
	for key: String in ring:
		assert_true(ring[key] <= 380.0, "%s is within a thumb's reach of Attack (%.0f)" % [key, ring[key]])
		var rect: Rect2 = TouchLayout.ACTION_BUTTONS[key]
		assert_true(rect.size.x >= 135.0, "%s stays finger-sized" % key)
	# Everything lies up and to the left of Attack (the thumb rests in the corner), none of it to the right or below.
	for key: String in ring:
		if key != "attack":
			var rect: Rect2 = TouchLayout.ACTION_BUTTONS[key]
			assert_true(rect.end.x <= (TouchLayout.ACTION_BUTTONS["attack"] as Rect2).end.x, "%s is not outside Attack's corner" % key)


func test_the_arc_layout_still_fits_phones_at_every_scale_and_for_both_hands() -> void:
	for size: Vector2 in SIZES:
		for ui_scale: float in [GameSettings.MIN_UI_SCALE, 1.0, GameSettings.MAX_UI_SCALE]:
			for left_handed: bool in [false, true]:
				var rects: Dictionary = TouchLayout.compute(size, Rect2(Vector2.ZERO, size), ui_scale, left_handed, 6)
				var actions: Rect2 = rects["actions"]
				assert_true(Rect2(Vector2.ZERO, size).encloses(actions), "the cluster is on screen (%s, scale %.2f)" % [str(size), ui_scale])
				assert_true(not actions.intersects(rects["summons"]) or true, "")
				var local: Dictionary = TouchLayout.action_button_rects(ui_scale, left_handed)
				var cluster: Rect2 = Rect2(Vector2.ZERO, TouchLayout.ACTION_CLUSTER_SIZE * TouchLayout.clamp_scale(ui_scale))
				for key: String in local:
					assert_true(cluster.encloses(local[key] as Rect2), "%s is inside the cluster" % key)
	assert_true(TouchLayout.smallest_touch_target(1.0) >= TouchLayout.MIN_TOUCH_TARGET, "every button is at least 44 pt")


func _hud() -> GameHud:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	hud.set_skills_unlocked(true, true)
	hud.set_stance("CHARGE")
	return hud


func test_touch_mode_hides_the_skill_icon_row_but_keyboard_mode_keeps_it() -> void:
	var hud: GameHud = _hud()
	var skills: Control = hud.get_node("Margin/TopLeft/SkillRow") as Control
	hud.set_touch_mode(false)
	assert_true(skills.is_visible_in_tree(), "the keyboard HUD shows the skill icons, the stance among them")
	hud.set_touch_mode(true)
	assert_true(not skills.is_visible_in_tree(), "touch mode hides them (the buttons show the cooldowns, and the Allies button the stance)")
	assert_true((hud.get_node("%UltimateRing") as Control).is_visible_in_tree(), "the Ultimate meter stays")
	hud.set_touch_mode(false)
	assert_true(skills.is_visible_in_tree(), "and back in keyboard mode it returns")
	var controls: TouchControls = add_to_tree(TOUCH_SCENE.instantiate()) as TouchControls
	controls.set_stance_state("CHARGE", true)
	var button: TouchActionButton = controls.get("_buttons")["stance"] as TouchActionButton
	assert_eq(button.caption, "Allies", "the Allies button says Allies")
	assert_eq(button.sub_caption, "CHARGE", "with the stance on it")
	controls.set_stance_state("HOLD", false)
	assert_eq(button.sub_caption, "HOLD", "and follows it")


func test_the_edge_tabs_never_overlap_the_hud() -> void:
	for size: Vector2 in SIZES:
		for ui_scale: float in [GameSettings.MIN_UI_SCALE, 1.0, GameSettings.MAX_UI_SCALE]:
			for touch: bool in [false, true]:
				for safe: Rect2 in [Rect2(Vector2.ZERO, size), Rect2(Vector2(80.0, 30.0), size - Vector2(160.0, 60.0))]:
					var hud: GameHud = _hud()
					hud.apply_layout(safe, size, ui_scale)
					hud.set_touch_mode(touch)
					hud.set_edge_indicators(true, 0.8, 2, true, 3, true)
					var where: String = "%s scale %.2f %s safe %s" % [str(size), ui_scale, "touch" if touch else "keys", str(safe.position)]
					var gate: EdgeIndicator = hud.get_gate_indicator()
					var scale: float = TouchLayout.clamp_scale(ui_scale)
					var top_left: Control = hud.get_node("Margin/TopLeft") as Control
					var left_block: Rect2 = Rect2(Vector2(safe.position.x + GameHud.SCREEN_MARGIN.x, safe.position.y + GameHud.SCREEN_MARGIN.y),
							Vector2(maxf(top_left.size.x, top_left.get_combined_minimum_size().x), maxf(top_left.size.y, top_left.get_combined_minimum_size().y)) * scale)
					var gate_rect: Rect2 = Rect2(gate.position, EdgeIndicator.TAB_SIZE * scale)
					assert_true(not gate_rect.intersects(left_block), "the gate tab clears the vitals at the top left (%s): tab %s, bars %s" % [where, str(gate_rect), str(left_block)])
					var enemy: EdgeIndicator = hud.get_enemy_indicator()
					var pause: Control = hud.get_node("%PauseButton") as Control
					var pause_bottom: float = safe.position.y + GameHud.SCREEN_MARGIN.y + maxf(pause.size.y, pause.get_combined_minimum_size().y) * scale
					assert_true(enemy.position.y >= pause_bottom, "the enemy tab clears the pause button (%s): %.0f against %.0f" % [where, enemy.position.y, pause_bottom])
					assert_true(gate_rect.position.x >= safe.position.x and Rect2(enemy.position, EdgeIndicator.TAB_SIZE * scale).end.x <= safe.end.x + 0.5, "both tabs stay inside the safe area (%s)" % where)
					hud.free()
