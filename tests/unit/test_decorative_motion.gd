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


func test_menu_uses_articulated_limbs_and_keeps_both_soles_pinned() -> void:
	var portrait: PortraitMotion = PortraitMotion.new()
	add_to_tree(portrait)
	var foot_f: Vector2 = portrait.front_ankle
	var foot_b: Vector2 = portrait.back_ankle
	var first_hand: Vector2 = portrait.front_hand
	var motion: float = 0.0
	for step: int in 180:
		portrait.set_time(float(step) / 60.0)
		motion = maxf(motion, first_hand.distance_to(portrait.front_hand))
		assert_true(portrait.front_ankle.distance_to(foot_f) < 0.01, "front sole stays planted")
		assert_true(portrait.back_ankle.distance_to(foot_b) < 0.01, "back sole stays planted")
	assert_true(motion > 0.1, "the articulated resting hand follows breathing")
	assert_true(portrait.get_node("fore_f") != portrait.get_node("torso"), "hand and body are independent painted parts")
	assert_true(is_nan(portrait.spec.back_hand_on_weapon.x), "the relaxed hand is released from the sword")
	assert_true(portrait.secondary.hair != null, "title hair has the same live chain as gameplay")
	portrait.reduced_motion = true
	portrait.set_time(2.0)
	assert_true(absf(portrait.breath) <= 0.15, "reduced motion damps the resting pose")


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
