extends "res://tests/test_case.gd"
## Nothing a character wears on its legs or carries in its hands is drawn below the ground, in any state or any move
## between states (with the spring overshoot): feet, legs, hakama hem, weapons, bows and shields, for every kind.

const STEP: float = 1.0 / 60.0
## How far below the feet line (figure units, a hundredth of the figure's height) a part may reach: the ground ink
## and the shadow are about this thick. 3.6 units = 4 px on a 110 px figure.
const TOLERANCE: float = 3.6
const GROUND_PARTS: Array[StringName] = [&"thigh_f", &"thigh_b", &"shin_f", &"shin_b", &"hakama_f", &"hakama_b",
		&"weapon", &"bow", &"shield", &"foot_f", &"foot_b"]
const SEQUENCES: Array = [
	[&"idle", &"run", &"idle"],
	[&"windup", &"strike", &"idle"],
	[&"heavy_windup", &"strike", &"idle"],
	[&"cast", &"strike", &"idle"],
	[&"windup", &"heavy_windup", &"strike", &"windup", &"strike", &"windup", &"strike"],
	[&"hurt", &"idle", &"run", &"hurt"],
	[&"dash", &"idle", &"hurt"],
	[&"run", &"windup", &"strike", &"run", &"dead"],
]


func _height(kind: InkFigure.Kind) -> float:
	match kind:
		InkFigure.Kind.ONI_BRUTE:
			return 190.0
		InkFigure.Kind.FALLEN_DAIMYO:
			return 300.0
	return 110.0


## Lowest point (figure units, y down, feet line at 0) of the ground-facing parts, and which one.
func _lowest(figure: InkFigure) -> Array:
	var scale: float = figure.get_unit_scale()
	var lowest: float = -INF
	var which: String = ""
	for child: Node in figure.get_children():
		var part: FigurePart = child as FigurePart
		if part == null or not part.visible or part.batch == null or not GROUND_PARTS.has(part.part_name):
			continue
		for vertex: Vector2 in part.batch.vertices:
			var y: float = (part.transform * vertex).y / scale
			if y > lowest:
				lowest = y
				which = String(part.part_name)
	return [lowest, which]


func test_no_leg_or_weapon_goes_below_the_ground_for_any_kind() -> void:
	for kind: int in InkFigure.Kind.values():
		var visual: UnitVisual = UnitVisual.new()
		visual.figure_kind = kind as InkFigure.Kind
		visual.figure_height = _height(kind as InkFigure.Kind)
		add_to_tree(visual)
		visual.set_process(false)
		var figure: InkFigure = visual.get_figure()
		var worst: float = -INF
		var detail: String = ""
		for sequence: Array in SEQUENCES:
			for state: StringName in sequence:
				visual.play_state(state)
				for frame: int in 60:
					visual.call(&"_process", STEP)
					var result: Array = _lowest(figure)
					if float(result[0]) > worst:
						worst = float(result[0])
						detail = "%s %s frame %d, %s" % [str(sequence), state, frame, result[1]]
		var name: String = InkFigure.Kind.keys()[kind]
		assert_true(worst <= TOLERANCE, "%s: legs and weapons reach %.1f units below the ground (%s)" % [name, worst, detail])
		visual.free()


func test_the_samurais_bow_and_war_cry_keep_his_legs_and_weapon_above_the_ground() -> void:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = InkFigure.Kind.SAMURAI
	visual.figure_height = 110.0
	add_to_tree(visual)
	visual.set_process(false)
	var worst: float = -INF
	for sequence: Array in [[&"idle", &"shoot", &"idle"], [&"idle", &"war_cry", &"idle"], [&"strike", &"shoot", &"war_cry", &"idle"]]:
		for state: StringName in sequence:
			visual.play_state(state)
			for frame: int in 60:
				visual.call(&"_process", STEP)
				worst = maxf(worst, float(_lowest(visual.get_figure())[0]))
	assert_true(worst <= TOLERANCE, "the samurai's Bow and War Cry reach %.1f units below the ground" % worst)


func test_every_key_pose_keeps_legs_and_weapons_above_the_ground() -> void:
	for kind: int in InkFigure.Kind.values():
		var figure: InkFigure = InkFigure.new()
		figure.height = _height(kind as InkFigure.Kind)
		add_to_tree(figure)
		figure.kind = kind as InkFigure.Kind
		for state: StringName in UnitVisual.STATES:
			if (state == &"shoot" or state == &"war_cry") and kind != InkFigure.Kind.SAMURAI:
				continue
			for step: int in 3:
				for heavy: bool in [false, true]:
					figure.pose.copy_from(FigureKinds.pose(kind as InkFigure.Kind, state, step, heavy))
					figure.refresh()
					var result: Array = _lowest(figure)
					assert_true(float(result[0]) <= TOLERANCE, "%s %s step %d%s: %s reaches %.1f units below the ground" % [
							InkFigure.Kind.keys()[kind], state, step, " heavy" if heavy else "", result[1], float(result[0])])
