extends "res://tests/test_case.gd"

const HEAVIES: Array[InkFigure.Kind] = [InkFigure.Kind.ONI_BRUTE, InkFigure.Kind.FALLEN_DAIMYO, InkFigure.Kind.BURNING_GENERAL]
const STATES: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"hurt", &"dead"]


func test_heavy_arms_keep_solved_joints_and_reachable_two_handed_grips() -> void:
	for kind: InkFigure.Kind in HEAVIES:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		add_to_tree(figure)
		for state: StringName in STATES:
			figure.pose = FigureKinds.pose(kind, state)
			figure.refresh()
			var label: String = "%s %s" % [kind, state]
			var upper: FigurePart = figure.get_node("upper_f")
			var fore: FigurePart = figure.get_node("fore_f")
			assert_true(upper.position.distance_to(figure.torso_xf * figure.spec.shoulder_front) < 0.01, label + " shoulder stays pinned")
			assert_true((upper.transform * Vector2(figure.spec.upper_arm, 0)).distance_to(fore.position) < 0.01, label + " elbow stays closed")
			assert_true(figure.spec.shoulder_front.distance_to(figure.front_hand) <= figure.spec.upper_arm + figure.spec.fore_arm + 0.05, label + " front hand is reachable")
			assert_true(figure.spec.shoulder_back.distance_to(figure.back_hand) <= figure.spec.upper_arm + figure.spec.fore_arm + 0.05, label + " far hand is reachable")
			assert_true(figure.get_node("upper_f").get_index() < figure.get_node("head").get_index(), label + " upper arm never paints over face")
			assert_true(figure.get_node("shoulder_f").get_index() < fore.get_index(), label + " cap leaves fist visible")


func test_heavy_shoulder_caps_sample_opaque_paint_at_the_joint() -> void:
	for kind: InkFigure.Kind in HEAVIES:
		var patch: Array = RosterSpriteArt.shoulder_patch(kind, false)
		var image: Image = RosterSpriteArt.atlas(kind).get_image()
		var source: Vector2 = (patch[3] as PackedVector2Array)[0] * Vector2(image.get_size())
		assert_true(image.get_pixelv(Vector2i(source)).a > 0.9, "%s shoulder cap samples solid paint" % kind)
		var center: Vector2 = RosterSpriteArt.frame(kind, &"torso") * (patch[1] as PackedVector2Array)[0]
		assert_true(center.distance_to(FigureKinds.spec(kind).shoulder_front) < 0.01, "cap is centred on the shoulder")


func test_archers_grip_the_visual_bow_middle_and_quantized_string_nock() -> void:
	for kind: InkFigure.Kind in [InkFigure.Kind.YUMI_ARCHER, InkFigure.Kind.SPECTRAL_ARCHER]:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		add_to_tree(figure)
		var lengths: Vector2 = FigurePainter.bow_lengths(kind)
		assert_almost_eq(lengths.x, lengths.y, "equal limbs put the grip at the visual middle")
		for state: StringName in STATES:
			for draw_index: int in 25:
				figure.pose = FigureKinds.pose(kind, state)
				figure.pose.bow_draw = draw_index / 24.0
				figure.pose.release = 0.0
				figure.refresh()
				var bow: FigurePart = figure.get_node("bow")
				var grip: Vector2 = figure.torso_xf * figure.front_hand
				assert_true(bow.position.distance_to(grip) < 0.01, "front hand holds bow origin in every pose")
				var amount: float = float(FigurePainter.bow_step(figure.pose.bow_draw)) / FigurePainter.BOW_STEPS
				var nock: Vector2 = bow.transform * Vector2(FigurePainter.bow_nock_x(amount), 0)
				assert_true(nock.distance_to(figure.torso_xf * figure.back_hand) < 0.01, "drawing fingers follow the rendered nock")
		assert_true(figure.get_node("grip_b").get_index() > figure.get_node("bow").get_index(), "string fingers render above the string")
