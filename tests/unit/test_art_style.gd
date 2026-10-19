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
	assert_almost_eq(figure.height, ONI_BRUTE.body_size.y, "figure is drawn at the body height")
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
		if i > 0:
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
