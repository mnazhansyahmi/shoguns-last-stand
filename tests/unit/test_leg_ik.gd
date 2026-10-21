extends "res://tests/test_case.gd"
## Exercises the actual animator and rendered bones, rather than duplicating the IK formula.
const STEP: float = 1.0 / 60.0
const LEGS: Array[StringName] = [&"thigh_f", &"shin_f", &"thigh_b", &"shin_b"]


func _visual(kind: InkFigure.Kind) -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = kind
	visual.figure_height = 190.0 if kind == InkFigure.Kind.ONI_BRUTE else (300.0 if kind == InkFigure.Kind.FALLEN_DAIMYO else 110.0)
	add_to_tree(visual)
	visual.set_process(false)
	return visual


func _length_error(fig: InkFigure) -> float:
	var worst: float = 0.0
	for side: int in 2:
		var origin: Vector2 = fig.hip + Vector2(2.0 if side == 0 else -2.0, 0.0)
		var knee: Vector2 = fig.front_knee if side == 0 else fig.back_knee
		var ankle: Vector2 = fig.front_ankle if side == 0 else fig.back_ankle
		worst = maxf(worst, absf(origin.distance_to(knee) - fig.spec.thigh))
		worst = maxf(worst, absf(knee.distance_to(ankle) - fig.spec.shin))
		worst = maxf(worst, absf((fig.root_xf * origin).distance_to(fig.root_xf * knee) / fig.get_unit_scale() - fig.spec.thigh))
		worst = maxf(worst, absf((fig.root_xf * knee).distance_to(fig.root_xf * ankle) / fig.get_unit_scale() - fig.spec.shin))
	return worst


func test_every_kind_keeps_bone_lengths_and_forward_knees_through_all_poses() -> void:
	for kind: int in InkFigure.Kind.values():
		var visual: UnitVisual = _visual(kind as InkFigure.Kind)
		var fig: InkFigure = visual.get_figure()
		var worst: float = 0.0
		var backward: float = 0.0
		var bend_max: float = 0.0
		var stretch: float = 0.0
		for state: StringName in UnitVisual.STATES:
			visual.play_state(state)
			for frame: int in 60:
				if state == &"run":
					visual.position.x += (90.0 if fig.spec.heavy_gait else 220.0) * STEP
				visual._process(STEP)
				worst = maxf(worst, _length_error(fig))
				for side: int in 2:
					var origin: Vector2 = fig.hip + Vector2(2.0 if side == 0 else -2.0, 0.0)
					var knee: Vector2 = fig.front_knee if side == 0 else fig.back_knee
					var ankle: Vector2 = fig.front_ankle if side == 0 else fig.back_ankle
					backward = minf(backward, (knee - origin).cross(ankle - knee))
					bend_max = maxf(bend_max, absf((knee - origin).angle_to(ankle - knee)))
				for child: Node in fig.get_children():
					var part: FigurePart = child as FigurePart
					if part != null and LEGS.has(part.part_name):
						var bone: Transform2D = fig.root_xf.affine_inverse() * part.transform
						stretch = maxf(stretch, absf(bone.x.length() - 1.0))
		assert_true(worst < 0.02, "%s bone length error %.4f" % [InkFigure.Kind.keys()[kind], worst])
		assert_true(backward >= -0.001, "%s knees always bend forward" % InkFigure.Kind.keys()[kind])
		assert_true(rad_to_deg(bend_max) <= LegIK.MAX_BEND + 0.1, "%s never folds flat (%.1f degrees)" % [InkFigure.Kind.keys()[kind], rad_to_deg(bend_max)])
		assert_true(stretch < 0.001, "%s drawn bones are never stretched (%.4f)" % [InkFigure.Kind.keys()[kind], stretch])
		visual.free()


func test_human_idle_knees_bend_less_than_fifteen_degrees() -> void:
	for kind: int in InkFigure.Kind.values():
		var visual: UnitVisual = _visual(kind as InkFigure.Kind)
		var fig: InkFigure = visual.get_figure()
		if fig.spec.is_enemy:
			visual.free()
			continue
		visual.play_state(&"idle")
		var worst: float = 0.0
		for frame: int in 360:
			visual._process(STEP)
			for side: int in 2:
				var origin: Vector2 = fig.hip + Vector2(2.0 if side == 0 else -2.0, 0.0)
				var knee: Vector2 = fig.front_knee if side == 0 else fig.back_knee
				var ankle: Vector2 = fig.front_ankle if side == 0 else fig.back_ankle
				worst = maxf(worst, absf((knee - origin).angle_to(ankle - knee)))
		assert_true(rad_to_deg(worst) < 15.0, "%s idle bend %.1f degrees" % [InkFigure.Kind.keys()[kind], rad_to_deg(worst)])
		visual.free()


func test_planted_feet_stay_fixed_and_flat_at_different_speeds_and_facings() -> void:
	for kind: int in InkFigure.Kind.values():
		var visual: UnitVisual = _visual(kind as InkFigure.Kind)
		var fig: InkFigure = visual.get_figure()
		var worst: float = 0.0
		var lowest: float = -INF
		var longest: float = 0.0
		for facing: int in [-1, 1]:
			visual.set_facing(facing)
			visual.play_state(&"run")
			var previous: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
			var was_planted: Array[bool] = [false, false]
			for frame: int in 480:
				var speed: float = [45.0, 120.0, 250.0, 0.0][(frame / 120) % 4]
				visual.position.x += facing * speed * STEP
				visual._process(STEP)
				# Keep the diagnostic visible even after crossing the viewport.
				visual.call(&"_apply")
				longest = maxf(longest, _length_error(fig))
				for side: int in 2:
					var ankle: Vector2 = fig.to_global(fig.root_xf * (fig.front_ankle if side == 0 else fig.back_ankle))
					if was_planted[side] and fig.gait.planted[side]:
						worst = maxf(worst, previous[side].distance_to(ankle))
					previous[side] = ankle
					was_planted[side] = fig.gait.planted[side]
				for child: Node in fig.get_children():
					var part: FigurePart = child as FigurePart
					if part == null or (part.part_name != &"foot_f" and part.part_name != &"foot_b"):
						continue
					for vertex: Vector2 in FigurePainter._original_vertices(part.batch):
						lowest = maxf(lowest, (part.transform * vertex).y)
		assert_true(worst <= 2.0, "%s planted drift %.3f px" % [InkFigure.Kind.keys()[kind], worst])
		assert_true(lowest <= 0.01, "%s sole never below ground (%.3f px)" % [InkFigure.Kind.keys()[kind], lowest])
		assert_true(longest < 0.02, "%s speed transitions keep bone lengths (%.4f)" % [InkFigure.Kind.keys()[kind], longest])
		visual.free()


func test_walk_support_run_flight_and_stopped_phase() -> void:
	for speed: float in [70.0, 250.0]:
		var visual: UnitVisual = _visual(InkFigure.Kind.SAMURAI)
		visual.play_state(&"run")
		var flights: int = 0
		var heel_frames: int = 0
		for frame: int in 240:
			visual.position.x += speed * STEP
			visual._process(STEP)
			var gait: LegGait = visual.get_figure().gait
			if not gait.planted[0] and not gait.planted[1]:
				flights += 1
			if gait.heel[0] < -0.1 or gait.heel[1] < -0.1:
				heel_frames += 1
		assert_true(flights == 0 if speed < 100.0 else flights > 0, "walk has support; run has a flight interval")
		assert_true(heel_frames > 0, "swing approaches contact heel first")
		for frame: int in 120:
			visual._process(STEP)
		var phase: float = visual.get_figure().gait.phase
		for frame: int in 60:
			visual._process(STEP)
		assert_almost_eq(visual.get_figure().gait.phase, phase, "stopped feet settle then stop cycling")
		visual.free()


func test_close_and_distant_targets_adjust_hips_without_stretching() -> void:
	var thigh: float = 23.0
	var shin: float = 23.0
	for target_x: float in [0.0, 28.0]:
		var front: Vector2 = Vector2(target_x + 2.0, -LegIK.SOLE)
		var back: Vector2 = Vector2(-target_x - 2.0, -LegIK.SOLE)
		var hip: Vector2 = LegIK.fit_hip(Vector2(0.0, -5.0 if target_x == 0.0 else -70.0), front, back, thigh, shin)
		var origin: Vector2 = hip + Vector2(2.0, 0.0)
		var knee: Vector2 = LegIK.knee(origin, front, thigh, shin)
		assert_almost_eq(origin.distance_to(knee), thigh, "thigh stays fixed", 0.01)
		assert_almost_eq(knee.distance_to(front), shin, "shin stays fixed", 0.01)
		assert_true(hip.y < -20.0 if target_x == 0.0 else hip.y > -70.0, "pelvis lifts for close targets and lowers into distant reach")


func test_all_authored_combo_and_heavy_keys_keep_fixed_legs() -> void:
	for kind: int in InkFigure.Kind.values():
		var visual: UnitVisual = _visual(kind as InkFigure.Kind)
		var fig: InkFigure = visual.get_figure()
		var worst: float = 0.0
		for state: StringName in UnitVisual.STATES:
			for combo: int in 3:
				for heavy: bool in [false, true]:
					fig.pose.copy_from(FigureKinds.pose(kind as InkFigure.Kind, state, combo, heavy))
					fig.refresh()
					worst = maxf(worst, _length_error(fig))
		assert_true(worst < 0.02, "%s all key poses keep fixed bones (%.4f)" % [InkFigure.Kind.keys()[kind], worst])
		visual.free()


func test_samurai_full_speed_cadence_and_pelvis_are_continuous() -> void:
	var visual: UnitVisual = _visual(InkFigure.Kind.SAMURAI)
	visual.play_state(&"run")
	var fig: InkFigure = visual.get_figure()
	var cycles: float = 0.0
	var previous_phase: float = 0.0
	var previous_hip: Vector2 = Vector2.ZERO
	var worst_step: float = 0.0
	for frame: int in 600:
		visual.position.x += 210.0 * STEP
		visual._process(STEP)
		visual.call(&"_apply")
		if frame > 60:
			cycles += fposmod(fig.gait.phase - previous_phase, 1.0)
			worst_step = maxf(worst_step, absf(fig.hip.y - previous_hip.y))
		previous_phase = fig.gait.phase
		previous_hip = fig.hip
	var frequency: float = cycles / (539.0 * STEP)
	assert_true(frequency > 1.4 and frequency < 2.2,
			"full-speed stride is purposeful rather than a rapid shuffle (%.2f cycles/s)" % frequency)
	assert_true(worst_step < 4.0, "support changes never snap the pelvis (%.2f units/frame)" % worst_step)
	visual.play_state(&"idle")
	for frame: int in 120:
		visual._process(STEP)
	assert_true(fig.gait.is_settled() and fig.upright, "a stopped swing finishes before the upright idle pose")
	visual.free()
