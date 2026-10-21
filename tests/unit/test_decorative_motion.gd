extends "res://tests/test_case.gd"

const KINDS: Array[InkFigure.Kind] = [InkFigure.Kind.SAMURAI, InkFigure.Kind.ASHIGARU,
		InkFigure.Kind.YUMI_ARCHER, InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.SPEAR_GUARDIAN,
		InkFigure.Kind.ONMYOJI, InkFigure.Kind.HATAMOTO]
const FRAME: float = 1.0 / 60.0
const SETTINGS_PATH: String = "user://test_saves/motion_settings.cfg"


func cleanup() -> void:
	GameSettings.reduced_decorative_motion = false
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	super.cleanup()


func _visual(kind: InkFigure.Kind) -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	add_to_tree(visual)
	visual.configure(kind, 100.0)
	visual.set_process(false)
	visual.play_state(&"idle")
	for i: int in 60: visual._process(FRAME)
	return visual


func test_menu_hair_and_robe_have_independent_weights_but_soles_are_pinned() -> void:
	for x: float in [0.1, 0.4, 0.6, 0.9]:
		var sole: Color = PortraitMotion.motion_weights(Vector2(x, 0.96))
		assert_true(sole.r == 0.0 and sole.g == 0.0 and sole.b == 0.0, "sole region is not displaced")
	var hair: Color = PortraitMotion.motion_weights(Vector2(0.9, 0.18))
	var robe: Color = PortraitMotion.motion_weights(Vector2(0.9, 0.65))
	assert_true(hair.g > 0.8 and hair.b == 0.0, "hair can flutter independently")
	assert_true(robe.b > 0.8 and robe.g == 0.0, "robe edge has its own motion")
	var portrait: PortraitMotion = PortraitMotion.new()
	add_to_tree(portrait)
	portrait.set_time(1.75)
	assert_almost_eq((portrait.material as ShaderMaterial).get_shader_parameter("motion_time"), 1.75, "time reaches the drawn mesh")
	portrait.reduced_motion = true
	portrait.set_time(2.0)
	assert_almost_eq((portrait.material as ShaderMaterial).get_shader_parameter("motion_amount"), 0.15, "reduced variant reaches the renderer")


func test_every_ally_has_live_anchored_cloth_that_moves_at_idle() -> void:
	for kind: InkFigure.Kind in KINDS:
		var visual: UnitVisual = _visual(kind)
		var fig: InkFigure = visual.get_figure()
		assert_true(fig.secondary != null and not fig.secondary.scarf.is_empty(), "%s has cloth" % kind)
		assert_true((fig.get_node("tails") as FigurePart).dynamic, "%s renders its live chain" % kind)
		var chain: ClothChain = fig.secondary.scarf[0]
		var relative_tip: Vector2 = chain.points[-1] - chain.points[0]
		var most: float = 0.0
		var foot: Vector2 = (fig.get_node("foot_f") as Node2D).global_position
		for i: int in 90:
			visual._process(FRAME)
			most = maxf(most, relative_tip.distance_to(chain.points[-1] - chain.points[0]))
			var expected_anchor: Vector2 = fig.secondary.tail_rest(fig, 0)[0]
			assert_true(chain.points[0].distance_to(expected_anchor) < 0.01, "%s cloth root follows its body" % kind)
			assert_true((fig.get_node("tails") as Node2D).global_position.distance_to(chain.points[0]) < 0.01,
					"cached ribbon drawing remains pinned between repaints")
		assert_true(most > 0.8, "%s idle tips visibly change (%.2f)" % [kind, most])
		assert_true((fig.get_node("foot_f") as Node2D).global_position.distance_to(foot) < 0.2, "decorative idle motion leaves the foot anchored")


func test_hair_follows_turns_and_teleports_without_stretching() -> void:
	var visual: UnitVisual = _visual(InkFigure.Kind.SAMURAI)
	var fig: InkFigure = visual.get_figure()
	assert_true((fig.get_node("mane") as FigurePart).dynamic, "ponytail renders the deforming chain")
	var chain: ClothChain = fig.secondary.hair
	var first_tip: Vector2 = chain.points[-1] - chain.points[0]
	visual.play_state(&"run")
	for frame: int in 120:
		if frame == 55: visual.set_facing(-1)
		if frame == 80: visual.position.x += 900.0
		visual.position.x += 3.5 if frame < 55 else -3.5
		visual._process(FRAME)
		for i: int in range(1, chain.points.size()):
			assert_almost_eq(chain.points[i].distance_to(chain.points[i - 1]), chain.link, "hair links do not stretch", 0.05)
		assert_true(chain.points[-1].distance_to(chain.points[0]) <= chain.link * 6.1, "turns do not explode the ponytail")
	assert_true(first_tip.distance_to(chain.points[-1] - chain.points[0]) > 8.0, "the ponytail changes with movement and facing")


func test_frozen_portrait_bakers_get_hair_and_cloth_on_the_first_frame() -> void:
	var fig: InkFigure = InkFigure.new()
	fig.kind = InkFigure.Kind.SAMURAI
	add_to_tree(fig)
	fig.refresh()
	assert_true(fig.secondary.hair != null and fig.secondary.hair.points.size() == 7, "a frozen samurai still has his ponytail")
	assert_true(not fig.secondary.scarf.is_empty(), "frozen icons have waist cloth")
	var hair: PackedVector2Array = fig.secondary.hair.points.duplicate()
	fig.refresh()
	assert_eq(fig.secondary.hair.points, hair, "repeated baking does not advance frozen cloth")


func test_reduced_motion_persists_and_keeps_combat_pose_changes() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.reduced_motion = true
	assert_eq(SettingsStore.new(SETTINGS_PATH).save_settings(settings), OK, "save reduced motion")
	var loaded: GameSettings = SettingsStore.new(SETTINGS_PATH).load_settings()
	assert_true(loaded.reduced_motion and loaded.duplicate_settings().reduced_motion, "load and duplicate preserve preference")
	loaded.apply_audio()
	var visual: UnitVisual = _visual(InkFigure.Kind.SAMURAI)
	var before: Vector2 = visual.get_figure().pose.grip
	visual.play_state(&"heavy_windup")
	for i: int in 30: visual._process(FRAME)
	assert_true(visual.get_figure().pose.grip.distance_to(before) > 5.0, "reduced decorative motion keeps combat animation")
