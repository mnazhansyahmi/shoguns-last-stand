extends "res://tests/test_case.gd"
## Phase 9: code-drawn art. Palette contrast rules from docs/ART_BIBLE.md, the procedural
## figures and their animation interface.

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const ASHIGARU: AllyData = preload("res://data/allies/ashigaru.tres")
const YUMI_ARCHER: AllyData = preload("res://data/allies/yumi_archer.tres")
const FRAME: float = 1.0 / 60.0


func _tick(visual: UnitVisual, seconds: float) -> void:
	var frames: int = ceili(seconds / FRAME)
	for i: int in frames:
		visual.call(&"_process", FRAME)


func _make_visual(kind: InkFigure.Kind, height: float = 110.0) -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = kind
	visual.figure_height = height
	add_to_tree(visual)
	visual.set_process(false)
	return visual


## The figure's displayed opacity (fading figures are drawn inside a CanvasGroup).
func _opacity(visual: UnitVisual) -> float:
	var figure: InkFigure = visual.get_figure()
	var group: CanvasGroup = figure.get_parent() as CanvasGroup
	return group.self_modulate.a if group != null else 1.0


func test_backdrop_behind_fighters_contrasts_with_ink() -> void:
	for color: Color in InkPalette.ACTION_BAND_BACKDROP:
		assert_true(InkPalette.contrast(InkPalette.INK, color) >= 3.0,
				"backdrop %s vs ink is at least 3:1 (got %.2f)" % [color.to_html(false), InkPalette.contrast(InkPalette.INK, color)])
	assert_true(InkPalette.contrast(InkPalette.INK, InkPalette.MIST) >= 4.5, "mist vs ink is at least 4.5:1")
	assert_true(InkPalette.contrast(InkPalette.INK, InkPalette.GROUND_TOP) >= 4.5, "ground edge vs ink is at least 4.5:1")


func test_accents_and_ui_text_are_readable() -> void:
	for color: Color in InkPalette.ACCENTS:
		assert_true(InkPalette.contrast(InkPalette.INK, color) >= 3.0,
				"accent %s vs ink is at least 3:1" % color.to_html(false))
	assert_true(InkPalette.contrast(InkPalette.PARCHMENT, InkPalette.UI_CHARCOAL) >= 7.0, "parchment text on charcoal is at least 7:1")
	assert_true(InkPalette.contrast(InkPalette.PARCHMENT_DIM, InkPalette.UI_BUTTON) >= 4.5, "secondary text on a button is at least 4.5:1")
	assert_true(InkPalette.contrast(InkPalette.PARCHMENT, InkPalette.UI_BUTTON_HOVER) >= 7.0, "text on a hovered button is at least 7:1")


func test_contrast_formula_matches_wcag() -> void:
	assert_almost_eq(InkPalette.contrast(Color.BLACK, Color.WHITE), 21.0, "black on white is 21:1", 0.01)
	assert_almost_eq(InkPalette.contrast(Color.WHITE, Color.WHITE), 1.0, "same colour is 1:1")


func test_unit_data_picks_the_right_figure() -> void:
	assert_eq(HOLLOW_SOLDIER.figure, InkFigure.Kind.HOLLOW_SOLDIER, "hollow soldier figure")
	assert_eq(ONI_BRUTE.figure, InkFigure.Kind.ONI_BRUTE, "oni brute figure")
	assert_eq(ASHIGARU.figure, InkFigure.Kind.ASHIGARU, "ashigaru figure")
	assert_eq(YUMI_ARCHER.figure, InkFigure.Kind.YUMI_ARCHER, "archer figure")


func test_units_build_their_figure_from_data() -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(ONI_BRUTE)
	add_to_tree(enemy)
	var figure: InkFigure = (enemy.get_node("Visual") as UnitVisual).get_figure()
	assert_eq(figure.kind, InkFigure.Kind.ONI_BRUTE, "enemy draws its data's figure")
	assert_true(figure.height >= ONI_BRUTE.body_size.y * 0.939 and figure.height <= ONI_BRUTE.body_size.y * 1.061,
			"figure is drawn at the body height, give or take the +-6%% size variation (%.1f)" % figure.height)
	var bar: Node2D = enemy.get_node("HealthBar")
	assert_true(bar.position.y < -ONI_BRUTE.body_size.y, "health bar sits above the horns")

	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(YUMI_ARCHER, 300.0)
	add_to_tree(ally)
	assert_eq((ally.get_node("Visual") as UnitVisual).get_figure().kind, InkFigure.Kind.YUMI_ARCHER, "ally draws its data's figure")

	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	assert_eq((player.get_node("Visual") as UnitVisual).get_figure().kind, InkFigure.Kind.SAMURAI, "player is the samurai")


func test_every_figure_plays_every_state() -> void:
	for kind: int in InkFigure.Kind.size():
		var visual: UnitVisual = _make_visual(kind as InkFigure.Kind)
		for state: StringName in UnitVisual.STATES:
			visual.play_state(state)
			assert_eq(visual.get_state(), state, "%s accepts %s" % [InkFigure.Kind.keys()[kind], state])
			_tick(visual, 0.2)
		var figure: InkFigure = visual.get_figure()
		assert_true(figure.get_head_top_y() < -figure.height * 0.8, "%s head top is near the top of the body" % InkFigure.Kind.keys()[kind])


func test_strike_snaps_toward_its_pose() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.SAMURAI)
	visual.play_state(&"windup")
	_tick(visual, 0.4)
	var windup_blade: float = visual.get_figure().pose.blade
	visual.play_state(&"strike")
	_tick(visual, 0.06)
	var target: float = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"strike").blade
	var covered: float = (visual.get_figure().pose.blade - windup_blade) / (target - windup_blade)
	assert_true(covered > 0.9, "strike reaches 90%% of its pose within 60 ms (got %.2f)" % covered)


func test_combo_alternates_cuts() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.SAMURAI)
	var strike_blades: Array[float] = []
	for i: int in 3:
		visual.play_state(&"windup")
		_tick(visual, 0.15)
		visual.play_state(&"strike")
		_tick(visual, 0.15)
		strike_blades.append(visual.get_figure().pose.blade)
	assert_true(strike_blades[0] > 0.4, "first cut ends low (downward cut)")
	assert_true(strike_blades[1] < -0.6, "second cut ends high (rising cut)")
	assert_true(absf(strike_blades[2]) < 0.3, "third hit is a level thrust")
	visual.play_state(&"idle")
	_tick(visual, 1.0)
	visual.play_state(&"windup")
	_tick(visual, 0.15)
	visual.play_state(&"strike")
	_tick(visual, 0.15)
	assert_true(visual.get_figure().pose.blade > 0.4, "after a pause the combo starts over")


func test_death_falls_then_dissolves_within_corpse_time() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.HOLLOW_SOLDIER)
	_tick(visual, 0.5)
	assert_almost_eq(_opacity(visual), 1.0, "standing figure is opaque")
	visual.play_state(&"dead")
	_tick(visual, UnitVisual.FALL_TIME)
	assert_true(visual.get_figure().fall > 0.95, "body has fallen after the fall time")
	_tick(visual, Enemy.CORPSE_TIME - UnitVisual.FALL_TIME - FRAME)
	assert_almost_eq(_opacity(visual), 0.0, "fully dissolved before the corpse is freed")


func test_fading_figure_fades_as_one_shape_and_returns() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.ASHIGARU, 100.0)
	visual.play_state(&"spawn")
	_tick(visual, FRAME)
	assert_true(visual.get_figure().get_parent() is CanvasGroup, "a see-through figure is drawn in a canvas group")
	_tick(visual, UnitVisual.SPAWN_FADE_TIME + 0.1)
	assert_eq(visual.get_figure().get_parent(), visual, "an opaque figure leaves the canvas group")


func test_respawn_stands_back_up() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.SAMURAI)
	visual.play_state(&"dead")
	_tick(visual, 1.0)
	visual.play_state(&"idle")
	_tick(visual, 0.6)
	assert_almost_eq(visual.get_figure().fall, 0.0, "respawned figure is upright")
	assert_almost_eq(_opacity(visual), 1.0, "respawned figure is visible again")


func test_hit_flash_fades() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.ONI_BRUTE, 190.0)
	visual.flash_hit()
	assert_almost_eq(visual.get_figure().flash, 1.0, "hit flash starts at full")
	_tick(visual, UnitVisual.FLASH_TIME + FRAME)
	assert_almost_eq(visual.get_figure().flash, 0.0, "hit flash is gone after its time")


func test_facing_mirrors_the_figure() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.YUMI_ARCHER, 96.0)
	visual.set_facing(-1)
	assert_almost_eq(visual.scale.x, -1.0, "facing left mirrors the figure")
	visual.set_facing(0)
	assert_almost_eq(visual.scale.x, -1.0, "zero keeps the current facing")


# --- Backdrop and environment -----------------------------------------------

const BACKDROP_SCENE: PackedScene = preload("res://scenes/backdrops/bamboo_outskirts.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/gate/village_gate.tscn")


func test_parallax_follows_camera_by_depth() -> void:
	var reference: Vector2 = Vector2(960.0, 540.0)
	var lifted: Vector2 = reference + Vector2(0.0, 210.0)
	assert_eq(BackdropLayer.parallax_offset(lifted, reference, 0.0), Vector2(0.0, 210.0), "sky stays fixed on screen")
	assert_eq(BackdropLayer.parallax_offset(lifted, reference, 1.0), Vector2.ZERO, "ground stays on the battlefield")
	assert_eq(BackdropLayer.parallax_offset(lifted, reference, 0.5), Vector2(0.0, 105.0), "mid layer moves half as much")


func test_backdrop_layers_go_back_to_front() -> void:
	var backdrop: Node = add_to_tree(BACKDROP_SCENE.instantiate())
	var layers: Array[BackdropLayer] = []
	for child: Node in backdrop.get_children():
		if child is BackdropLayer:
			layers.append(child)
	assert_eq(layers.size(), BambooOutskirtsPainter.Layer.size(), "one node per backdrop layer")
	var drifting: int = 0
	for i: int in layers.size():
		# The light rays stay at the sun's depth (so they start at the sun) but draw over the land.
		if i > 0 and layers[i].layer != BambooOutskirtsPainter.Layer.RAYS and layers[i - 1].layer != BambooOutskirtsPainter.Layer.RAYS:
			assert_true(layers[i].depth >= layers[i - 1].depth, "%s is not behind the layer before it" % layers[i].name)
		if layers[i].drift_speed != 0.0:
			drifting += 1
			assert_almost_eq(layers[i].tile_width, BambooOutskirtsPainter.FOG_TILE, "%s repeats where its art repeats" % layers[i].name)
	assert_true(drifting >= 2, "at least two fog layers drift")
	var front: BackdropLayer = backdrop.get_node("FrontFog")
	assert_true(front.z_index > 0, "front fog is drawn over the fighters")


func test_fog_drift_wraps() -> void:
	var fog: BackdropLayer = BackdropLayer.new()
	fog.layer = BambooOutskirtsPainter.Layer.MIST_LOW
	fog.drift_speed = 300.0
	add_to_tree(fog)
	fog.set_process(false)
	for i: int in 900:
		fog.call(&"_process", FRAME)
	var shift: float = fog.position.x - BackdropLayer.parallax_offset(fog.view_center(), fog.reference_center, fog.depth).x
	assert_true(shift <= 0.0 and shift > -fog.tile_width, "drift stays within one tile (got %.1f)" % shift)


func test_gate_shows_damage_and_goes_dark() -> void:
	var gate: VillageGate = add_to_tree(GATE_SCENE.instantiate()) as VillageGate
	var visual: GateVisual = gate.get_node("Visual") as GateVisual
	assert_almost_eq(visual.get_damage(), 0.0, "new gate is undamaged")
	gate.get_health().take_damage(gate.get_health().max_health * 0.5)
	assert_almost_eq(visual.get_damage(), 0.5, "gate visual tracks damage taken")
	assert_true(visual.is_lit(), "lanterns burn while the gate stands")
	gate.get_health().take_damage(gate.get_health().max_health)
	assert_true(not visual.is_lit(), "lanterns go out when the gate falls")


# --- Effects ----------------------------------------------------------------

const SPIRIT_SLASH_SCENE: PackedScene = preload("res://scenes/player/spirit_slash.tscn")


## Advances a visual and every effect under it (tests run without frames).
func _tick_all(node: Node, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME - 0.001):
		var nodes: Array[Node] = [node]
		nodes.append_array(node.find_children("*", "", true, false))
		for child: Node in nodes:
			if is_instance_valid(child) and not child.is_queued_for_deletion() \
					and (child is UnitVisual or child is InkEffect or child is Afterimage):
				child.call(&"_process", FRAME)


func _live_children(node: Node, type_name: String) -> int:
	var count: int = 0
	for child: Node in node.find_children("*", type_name, true, false):
		if not child.is_queued_for_deletion():
			count += 1
	return count


func test_strikes_leave_a_slash_trail_that_fades() -> void:
	var samurai: UnitVisual = _make_visual(InkFigure.Kind.SAMURAI)
	samurai.play_state(&"windup")
	_tick_all(samurai, 0.2)
	samurai.play_state(&"strike")
	assert_eq(_live_children(samurai, "SlashTrail"), 1, "a katana strike leaves a slash trail")
	_tick_all(samurai, SlashTrail.LIFETIME + FRAME)
	assert_eq(_live_children(samurai, "SlashTrail"), 0, "the trail frees itself after its lifetime")
	var archer: UnitVisual = _make_visual(InkFigure.Kind.YUMI_ARCHER, 96.0)
	archer.play_state(&"windup")
	archer.play_state(&"strike")
	assert_eq(_live_children(archer, "SlashTrail"), 0, "loosing an arrow leaves no slash trail")


func test_oni_slam_sends_a_shockwave() -> void:
	var oni: UnitVisual = _make_visual(InkFigure.Kind.ONI_BRUTE, 190.0)
	oni.play_state(&"windup")
	oni.play_state(&"strike")
	assert_eq(_live_children(oni, "ShockRing"), 1, "the Oni's slam sends a ground shockwave")


func test_entrances_splash_ink_or_portal_smoke() -> void:
	var ally: UnitVisual = _make_visual(InkFigure.Kind.ASHIGARU, 100.0)
	ally.play_state(&"spawn")
	var splashes: Array[Node] = ally.find_children("*", "InkSplash", true, false)
	assert_eq(splashes.size(), 1, "a summoned ally appears in an ink splash")
	if splashes.size() == 1:
		assert_eq(splashes[0].get_index(), 0, "the splash is drawn behind the figure")
	var enemy: UnitVisual = _make_visual(InkFigure.Kind.HOLLOW_SOLDIER)
	enemy.play_state(&"spawn")
	assert_eq(_live_children(enemy, "InkSplash"), 1, "an enemy appears in portal smoke")
	_tick_all(enemy, InkSplash.SMOKE_LIFETIME + FRAME)
	assert_eq(_live_children(enemy, "InkSplash"), 0, "the smoke clears")


func test_death_dissolves_into_ink_within_corpse_time() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.HOLLOW_SOLDIER)
	visual.play_state(&"dead")
	_tick_all(visual, UnitVisual.FALL_TIME)
	assert_eq(_live_children(visual, "InkDissolve"), 1, "the fallen body breaks into ink")
	_tick_all(visual, Enemy.CORPSE_TIME - UnitVisual.FALL_TIME - FRAME)
	assert_eq(_live_children(visual, "InkDissolve"), 0, "the ink is gone before the corpse is freed")


func test_dash_leaves_afterimages_in_place() -> void:
	var visual: UnitVisual = _make_visual(InkFigure.Kind.SAMURAI)
	visual.play_state(&"dash")
	for i: int in 12:
		visual.position.x += 20.0
		_tick_all(visual, FRAME)
	var ghosts: Array[Node] = visual.find_children("*", "Afterimage", true, false)
	assert_eq(ghosts.size(), UnitVisual.AFTERIMAGE_COUNT, "a dash leaves afterimages")
	if ghosts.size() == UnitVisual.AFTERIMAGE_COUNT:
		var first: Afterimage = ghosts[ghosts.size() - 1] as Afterimage
		assert_true(first.global_position.x < visual.global_position.x - 100.0, "afterimages stay where they were left")
	_tick_all(visual, Afterimage.LIFETIME + FRAME)
	assert_eq(_live_children(visual, "Afterimage"), 0, "afterimages fade out and free themselves")


func test_hits_throw_sparks_up_to_a_cap() -> void:
	var feedback: BattleFeedback = BattleFeedback.new()
	feedback.numbers_parent = add_to_tree(Node2D.new())
	add_to_tree(feedback)
	var victim: Node = add_to_tree(Node2D.new())
	var hit: HitData = HitData.new(10.0, Vector2(100.0, 0.0), null)
	assert_true(feedback.spawn_hit_spark(victim, Vector2.ZERO, hit) == null, "no sparks without an effects parent")
	var sparks: Node2D = add_to_tree(Node2D.new()) as Node2D
	feedback.effects_parent = sparks
	for i: int in BattleFeedback.MAX_HIT_SPARKS + 5:
		feedback.spawn_hit_spark(victim, Vector2.ZERO, hit)
	assert_eq(sparks.get_child_count(), BattleFeedback.MAX_HIT_SPARKS, "sparks are capped")
	for spark: Node in sparks.get_children():
		spark.free()
	assert_true(feedback.spawn_hit_spark(victim, Vector2.ZERO, hit) != null, "freed sparks make room for new ones")


func test_spirit_slash_glow_keeps_the_hitbox() -> void:
	var slash: Node = track(SPIRIT_SLASH_SCENE.instantiate())
	assert_true(slash.get_node("Visual") is SpiritSlashVisual, "spirit slash is drawn by its glow visual")
	var shape: RectangleShape2D = (slash.get_node("Hitbox/CollisionShape2D") as CollisionShape2D).shape
	assert_eq(shape.size, Vector2(56.0, 150.0), "the hitbox size is unchanged")
	var points: PackedVector2Array = SpiritSlashVisual.crescent_points(SpiritSlashVisual.RADIUS, 26.0, 40.0)
	var bounds: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	assert_true(absf(bounds.size.y - shape.size.y) < 20.0, "the crescent is about as tall as the hitbox")


# --- UI theme ---------------------------------------------------------------

const MENU_SCENES: Array[String] = ["res://scenes/main_menu/main_menu.tscn", "res://scenes/stage_select/stage_select.tscn",
		"res://scenes/upgrade_menu/upgrade_menu.tscn", "res://scenes/ui/pause_menu.tscn", "res://scenes/ui/settings_panel.tscn",
		"res://scenes/ui/result_screen.tscn", "res://scenes/ui/game_hud.tscn"]


func test_project_uses_the_one_ink_theme() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom", ""), InkThemeBuilder.THEME_PATH, "project custom theme is the ink theme")
	var saved: Theme = load(InkThemeBuilder.THEME_PATH) as Theme
	assert_true(saved != null, "the saved theme loads")
	if saved == null:
		return
	var built: Theme = InkThemeBuilder.build()
	for variation: StringName in InkThemeBuilder.LABEL_VARIATIONS + InkThemeBuilder.BUTTON_VARIATIONS + InkThemeBuilder.PANEL_VARIATIONS:
		assert_true(saved.get_type_variation_base(variation) != &"", "saved theme has %s (re-run tools/make_ui_theme.gd)" % variation)
		if saved.has_color(&"font_color", variation):
			assert_eq(saved.get_color(&"font_color", variation), built.get_color(&"font_color", variation), "%s colour is up to date" % variation)
	var button: StyleBoxFlat = saved.get_stylebox(&"normal", &"Button") as StyleBoxFlat
	assert_true(button != null and button.bg_color.is_equal_approx(InkPalette.UI_BUTTON), "buttons are charcoal")
	assert_eq(saved.get_color(&"font_color", &"Label"), InkPalette.PARCHMENT, "text is parchment")


func test_menus_use_theme_variations_not_colour_overrides() -> void:
	var known: Array[StringName] = InkThemeBuilder.LABEL_VARIATIONS + InkThemeBuilder.BUTTON_VARIATIONS
	for path: String in MENU_SCENES:
		var text: String = FileAccess.get_file_as_string(path)
		assert_true(not text.contains("theme_override_colors"), "%s has no colour overrides" % path.get_file())
		assert_true(not text.contains("theme_override_styles"), "%s has no style overrides" % path.get_file())
		var node: Node = (load(path) as PackedScene).instantiate()
		track(node)
		for child: Node in node.find_children("*", "Control", true, false):
			var variation: StringName = (child as Control).theme_type_variation
			if variation != &"":
				assert_true(known.has(variation), "%s: %s uses a known variation (%s)" % [path.get_file(), child.name, variation])


func test_title_samurai_stands_against_the_moon() -> void:
	var menu: Node = (load("res://scenes/main_menu/main_menu.tscn") as PackedScene).instantiate()
	menu.set("save_path", "user://test_saves/title_save.json")
	menu.set("settings_path", "user://test_saves/title_settings.cfg")
	add_to_tree(menu)
	var art: Control = menu.get_node("TitleArt")
	var painting: LivingMenuPainting = art.get_node("ScenePainting") as LivingMenuPainting
	var moon: Vector2 = art.call(&"get_moon_position")
	var portrait: Rect2 = art.call(&"get_portrait_rect")
	assert_true(portrait.has_point(moon), "moon and samurai share the composed focal region")
	assert_true(portrait.position.y < moon.y and portrait.position.y + portrait.size.y * 0.22 > moon.y,
			"the moon stays behind the portrait's head")
	assert_true(LivingMenuPainting.ART != null and painting.get_child_count() == 1 and painting.material == null,
			"the inpainted scene is static, with one separate alpha character and no limb nodes")
	assert_true(painting.scale.x > 0.0 and is_equal_approx(painting.scale.x, painting.scale.y),
			"the painting keeps its anatomical right-hand sword without reflection or distortion")
	var scene: Image = LivingMenuPainting.ART.get_image()
	for sole: Vector2 in art.call(&"get_foot_contacts"):
		var pixel: Vector2 = (sole - painting.position) / painting.scale
		assert_true(scene.get_pixelv(Vector2i(pixel)).a > 0.99, "sole and stone belong to the same opaque scene")
	assert_true(painting.has_node("Character"), "character cutout alone owns the motion shader")
	var fog: CanvasItem = menu.get_node("Backdrop/FrontFog")
	assert_true(not fog.visible, "front fog is off behind the menu so it never covers buttons")


# --- Performance shape -------------------------------------------------------

func test_figures_share_cached_parts_and_only_move_them() -> void:
	var first: UnitVisual = _make_visual(InkFigure.Kind.HOLLOW_SOLDIER)
	var second: UnitVisual = _make_visual(InkFigure.Kind.HOLLOW_SOLDIER)
	var torso: InkBatch = FigurePainter.part(InkFigure.Kind.HOLLOW_SOLDIER, &"torso")
	assert_true(torso != null and not torso.is_empty(), "torso shapes are built")
	assert_true(FigurePainter.part(InkFigure.Kind.HOLLOW_SOLDIER, &"torso") == torso, "shapes are cached per kind, not rebuilt")
	var figure: InkFigure = first.get_figure()
	assert_eq(figure.get_part_count(), FigurePainter.layout(InkFigure.Kind.HOLLOW_SOLDIER).size(), "one node per body part")
	var torso_node: FigurePart = figure.get_node("torso") as FigurePart
	assert_true(torso_node.batch == torso and second.get_figure().get_node("torso").get("batch") == torso,
			"every figure of a kind draws the same cached torso")
	var before: Transform2D = torso_node.transform
	first.play_state(&"strike")
	_tick(first, 0.1)
	assert_true(not torso_node.transform.is_equal_approx(before), "animating moves the part node")


func test_marker_marks_only_the_player() -> void:
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	var samurai: InkFigure = (player.get_node("Visual") as UnitVisual).get_figure()
	assert_true(samurai.has_node("marker"), "the player has a ground marker")
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ASHIGARU, 300.0)
	add_to_tree(ally)
	assert_true(not (ally.get_node("Visual") as UnitVisual).get_figure().has_node("marker"), "allies have no marker")


# --- Zoomed battle view -------------------------------------------------------

const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")


func _make_battlefield() -> Node:
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", "user://test_saves/art_view_save.json")
	field.set("settings_path", "user://test_saves/art_view_settings.cfg")
	add_to_tree(field)
	return field


func test_zoomed_parallax_keeps_sky_unmagnified_and_ground_in_the_world() -> void:
	var reference: Vector2 = Vector2(960.0, 540.0)
	var center: Vector2 = Vector2(1400.0, 660.0)
	var unzoomed: Transform2D = BackdropLayer.layer_transform(center, reference, 0.4, 1.0)
	assert_true(unzoomed.origin.is_equal_approx(BackdropLayer.parallax_offset(center, reference, 0.4)), "zoom 1 matches plain parallax")
	assert_true(BackdropLayer.layer_transform(center, reference, 1.0, 1.5).is_equal_approx(Transform2D.IDENTITY), "ground stays locked to the world")
	var sky: Transform2D = BackdropLayer.layer_transform(center, reference, 0.0, 1.5)
	assert_almost_eq(sky.get_scale().x * 1.5, 1.0, "the sky is not magnified on screen")
	# A sky point lands where it was painted on screen, wherever the camera is.
	var screen: Vector2 = ((sky * Vector2(1480.0, 230.0)) - center) * 1.5 + reference
	assert_true(screen.is_equal_approx(Vector2(1480.0, 230.0)), "the moon stays put on screen")


func test_battle_camera_zooms_and_follows_the_player_inside_the_field() -> void:
	var field: Node = _make_battlefield()
	var camera: BattleCamera = field.call(&"get_camera")
	var player: Player = field.get_node("World/Player")
	assert_almost_eq(camera.zoom.x, 1.5, "units are drawn 1.5x bigger")
	var half: float = camera.get_view_size().x * 0.5
	for x: float in [-500.0, 900.0, 4000.0]:
		player.global_position.x = x
		camera.snap()
		assert_true(camera.position.x - half >= camera.bounds_left - 0.5 or camera.bounds_right - camera.bounds_left < half * 2.0,
				"view stays inside the field on the left (player at %d)" % x)
		assert_true(camera.position.x + half <= camera.bounds_right + 0.5 or camera.bounds_right - camera.bounds_left < half * 2.0,
				"view stays inside the field on the right (player at %d)" % x)
	player.global_position.x = 900.0
	camera.snap()
	assert_true(absf(camera.position.x - camera.get_desired_x()) < 0.01 and absf(camera.get_desired_x() - 900.0) <= camera.look_ahead + 0.01
			or camera.bounds_right - camera.bounds_left < half * 2.0, "camera centres near the player")


func test_edge_indicators_point_at_the_hidden_gate_and_incoming_enemies() -> void:
	var field: Node = _make_battlefield()
	var camera: BattleCamera = field.call(&"get_camera")
	var hud: GameHud = field.get_node("Hud")
	var player: Player = field.get_node("World/Player")
	var gate: VillageGate = field.get_node("World/VillageGate")
	player.global_position.x = 2000.0
	camera.snap()
	var enemy: Enemy = (field.get_node("World/EnemySpawner") as EnemySpawner).spawn(HOLLOW_SOLDIER)
	enemy.global_position.x = camera.get_view_rect().position.x - 200.0
	field.call(&"_update_edge_indicators")
	var gate_hidden: bool = gate.get_front_x() < camera.get_view_rect().position.x + 30.0
	assert_eq(hud.get_gate_indicator().visible, gate_hidden, "gate tab shows exactly when the gate is off screen")
	if gate_hidden:
		assert_true(hud.get_gate_indicator().detail.contains("1 at the gate"), "the tab counts enemies at the gate")
		assert_true(hud.get_gate_indicator().alert, "enemies at the gate raise the alert")
	enemy.global_position.x = camera.get_view_rect().end.x + 200.0
	field.call(&"_update_edge_indicators")
	assert_true(hud.get_enemy_indicator().visible and hud.get_enemy_indicator().title == "1 incoming", "right tab counts enemies past the right edge")


func test_glows_are_merged_per_part_and_not_lost() -> void:
	var definitions: Array[Dictionary] = FigurePainter.glows(InkFigure.Kind.HOLLOW_SOLDIER)
	assert_eq(definitions.size(), 1, "both hollow eyes share one additive item")
	if definitions.size() == 1:
		assert_eq((definitions[0]["points"] as PackedVector2Array).size(), 2, "the merged eye glow keeps both eyes")
		assert_eq((definitions[0]["radii"] as PackedFloat32Array).size(), 2, "one radius per eye")
	var oni: Array[Dictionary] = FigurePainter.glows(InkFigure.Kind.ONI_BRUTE)
	var spots: int = 0
	var parts_lit: Dictionary = {}
	for definition: Dictionary in oni:
		spots += (definition["points"] as PackedVector2Array).size()
		parts_lit[definition["part"]] = true
	assert_eq(parts_lit.size(), 2, "the oni's glows sit on two parts (torso, head)")
	# One additive item per part and flicker depth: the steady halo, the flickering cracks, the eyes.
	assert_eq(oni.size(), 3, "the oni's glows merge into three additive items")
	assert_eq(spots, 9, "no oni glow spot is lost in merging")


# --- Health bars and damage numbers -----------------------------------------

func _spawn_enemy_at(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	return enemy


func test_enemy_health_bar_appears_only_after_damage() -> void:
	var enemy: Enemy = _spawn_enemy_at(500.0)
	var bar: WorldHealthBar = enemy.get_node("HealthBar")
	assert_true(not bar.visible, "a full-health enemy shows no bar")
	assert_true(bar.bar_size.x <= HOLLOW_SOLDIER.body_size.x, "the bar is no wider than the body")
	(enemy.get_node("HealthComponent") as HealthComponent).take_damage(10.0)
	assert_true(bar.visible, "the bar appears once the enemy is hurt")


func test_overlapping_enemy_bars_stack_upward() -> void:
	var first: Enemy = _spawn_enemy_at(600.0)
	var second: Enemy = _spawn_enemy_at(610.0)
	var far: Enemy = _spawn_enemy_at(1400.0)
	for enemy: Enemy in [first, second, far]:
		(enemy.get_node("HealthComponent") as HealthComponent).take_damage(10.0)
	WorldHealthBar.layout_staggered()
	var a: WorldHealthBar = first.get_node("HealthBar")
	var b: WorldHealthBar = second.get_node("HealthBar")
	var c: WorldHealthBar = far.get_node("HealthBar")
	# Randomized enemy stature gives each bar a different baseline. Judge visible
	# separation: a one-level offset can still collide with a taller neighbour.
	var first_rect: Rect2 = Rect2(a.global_position - a.bar_size * 0.5, a.bar_size).grow(2.0)
	var second_rect: Rect2 = Rect2(b.global_position - b.bar_size * 0.5, b.bar_size).grow(2.0)
	assert_true(not first_rect.intersects(second_rect), "nearby enemy bars remain visibly separate")
	assert_eq(c.get_stagger_level(), 0, "a bar with no neighbours stays on its unit")


func test_damage_numbers_are_bigger_with_a_solid_ink_outline() -> void:
	assert_true(DamageNumber.FONT_SIZE >= 28 and DamageNumber.FONT_SIZE <= 32, "damage numbers are about 25% smaller than before (40 -> 30)")
	assert_true(DamageNumber.OUTLINE_SIZE >= 8, "damage numbers have a thick dark outline")
