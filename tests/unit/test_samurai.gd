extends "res://tests/test_case.gd"
## The samurai's animation: his blade never passes through his body, his arms never stretch,
## cuts have anticipation and follow-through, and his cloth lags behind his movement.

const FRAME: float = 1.0 / 60.0
const COMBO_STATES: Array[StringName] = [&"idle", &"run", &"windup", &"strike", &"cast", &"dash", &"hurt"]
## Along the katana, from this point out is "blade" (the first stretch is the hilt in his hands).
const BLADE_FROM: float = 6.0


func _figure() -> InkFigure:
	var figure: InkFigure = InkFigure.new()
	figure.height = 100.0
	add_to_tree(figure)
	figure.kind = InkFigure.Kind.SAMURAI
	return figure


func _visual() -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = InkFigure.Kind.SAMURAI
	visual.figure_height = 110.0
	add_to_tree(visual)
	visual.set_process(false)
	return visual


func _tick(visual: UnitVisual, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME - 0.001):
		visual.call(&"_process", FRAME)


## Every key pose of the samurai, named.
func _key_poses() -> Dictionary:
	var poses: Dictionary = {}
	for state: StringName in [&"idle", &"run", &"cast", &"dash", &"hurt", &"heavy_windup"]:
		poses[String(state)] = FigureKinds.pose(InkFigure.Kind.SAMURAI, state)
	for step: int in 3:
		poses["windup %d" % step] = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"windup", step)
		poses["strike %d" % step] = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"strike", step)
	poses["heavy strike"] = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"strike", 0, true)
	poses["title"] = FigureKinds.samurai_title_pose()
	return poses


## Where the blade (from BLADE_FROM to the tip) is, in the figure's root space, for a pose.
func _blade_points(figure: InkFigure, pose: FigurePose) -> PackedVector2Array:
	figure.pose.copy_from(pose)
	figure.refresh()
	var points: PackedVector2Array = PackedVector2Array()
	var along: float = BLADE_FROM
	while along <= FigurePainter.KATANA_LENGTH + 2.0:
		points.append(figure.root_xf.affine_inverse() * figure.get_weapon_point(along))
		along += 2.0
	return points


## Names of the body zones the blade passes through in a pose (empty = clear).
func _clipped_zones(figure: InkFigure, pose: FigurePose) -> int:
	var hits: int = 0
	var zones: Array[PackedVector2Array] = FigureKinds.samurai_body_zones(pose)
	for point: Vector2 in _blade_points(figure, pose):
		for zone: PackedVector2Array in zones:
			if Geometry2D.is_point_in_polygon(point, zone):
				hits += 1
				break
	return hits


func test_katana_never_clips_the_body_in_any_pose() -> void:
	var figure: InkFigure = _figure()
	var poses: Dictionary = _key_poses()
	for pose_name: String in poses:
		var clipped: int = _clipped_zones(figure, poses[pose_name])
		assert_eq(clipped, 0, "the katana stays clear of the body in '%s' (points inside the body)" % pose_name)


func test_katana_never_clips_the_body_during_a_swing() -> void:
	var figure: InkFigure = _figure()
	var pairs: Array = [
		[&"idle", 0, &"windup", 0], [&"windup", 0, &"strike", 0], [&"strike", 0, &"windup", 1],
		[&"windup", 1, &"strike", 1], [&"strike", 1, &"windup", 2], [&"windup", 2, &"strike", 2],
		[&"strike", 2, &"idle", 0], [&"idle", 0, &"heavy_windup", 0], [&"heavy_windup", 0, &"strike", -1],
		[&"idle", 0, &"cast", 0], [&"run", 0, &"windup", 0], [&"idle", 0, &"dash", 0], [&"dash", 0, &"idle", 0],
		[&"idle", 0, &"hurt", 0], [&"hurt", 0, &"idle", 0],
	]
	for pair: Array in pairs:
		var heavy_to: bool = pair[3] == -1
		var from: FigurePose = FigureKinds.pose(InkFigure.Kind.SAMURAI, pair[0], pair[1])
		var to: FigurePose = FigureKinds.pose(InkFigure.Kind.SAMURAI, pair[2], maxi(pair[3], 0), heavy_to)
		var blended: FigurePose = FigurePose.new()
		# Past 1.0: the follow-through overshoot.
		for weight: float in [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0, 1.12]:
			blended.copy_from(from)
			blended.blend_toward(to, weight)
			assert_eq(_clipped_zones(figure, blended), 0,
					"katana clear of the body %s %d -> %s at %.2f" % [pair[0], pair[1], pair[2], weight])


func test_arms_never_stretch_in_any_pose() -> void:
	var figure: InkFigure = _figure()
	var reach: float = figure.spec.upper_arm + figure.spec.fore_arm
	var poses: Dictionary = _key_poses()
	for pose_name: String in poses:
		figure.pose.copy_from(poses[pose_name])
		figure.refresh()
		var front: float = figure.spec.shoulder_front.distance_to(figure.front_hand)
		var back: float = figure.spec.shoulder_back.distance_to(figure.back_hand)
		assert_true(front <= reach + 0.05, "front arm reaches its grip in '%s' (%.1f of %.1f)" % [pose_name, front, reach])
		assert_true(back <= reach + 0.05, "back arm reaches its grip in '%s' (%.1f of %.1f)" % [pose_name, back, reach])


func test_hand_swings_on_an_arc_around_the_shoulder() -> void:
	var from: FigurePose = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"windup", 0)
	var to: FigurePose = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"strike", 0)
	var mid: FigurePose = FigurePose.new()
	mid.copy_from(from)
	mid.blend_toward(to, 0.5)
	var straight: Vector2 = from.grip.lerp(to.grip, 0.5)
	var radius_from: float = (from.grip - from.pivot).length()
	var radius_to: float = (to.grip - to.pivot).length()
	assert_almost_eq((mid.grip - mid.pivot).length(), (radius_from + radius_to) * 0.5, "the arm keeps its length along the swing", 0.01)
	assert_true(mid.grip.distance_to(straight) > 1.0, "the hand does not move in a straight line")


func test_cut_overshoots_then_settles() -> void:
	var visual: UnitVisual = _visual()
	visual.play_state(&"windup")
	_tick(visual, 0.08)
	visual.play_state(&"strike")
	var target: float = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"strike", 0).blade
	var start: float = visual.get_figure().pose.blade
	var peak: float = start
	for i: int in 24:
		_tick(visual, FRAME)
		# The cut swings the blade from high (negative) to low (positive).
		peak = maxf(peak, visual.get_figure().pose.blade)
	assert_true(peak > target + 0.04, "the blade swings past its pose (follow-through): peak %.2f, pose %.2f" % [peak, target])
	_tick(visual, 0.6)
	var guard: float = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"idle").blade
	visual.play_state(&"idle")
	_tick(visual, 1.2)
	assert_almost_eq(visual.get_figure().pose.blade, guard, "he settles back to guard", 0.06)


func test_cut_accelerates_into_the_strike() -> void:
	var visual: UnitVisual = _visual()
	visual.play_state(&"windup")
	_tick(visual, 0.08)
	var from: float = visual.get_figure().pose.blade
	visual.play_state(&"strike")
	var target: float = FigureKinds.pose(InkFigure.Kind.SAMURAI, &"strike", 0).blade
	var travelled: Array[float] = []
	for i: int in 4:
		_tick(visual, FRAME)
		travelled.append((visual.get_figure().pose.blade - from) / (target - from))
	assert_true(travelled[0] < travelled[1] - 0.05, "the blade is still speeding up after one frame: %s" % str(travelled))
	assert_true(travelled[3] > 0.6, "and has covered most of the cut within four frames (got %.2f)" % travelled[3])


func test_windup_pulls_back_before_the_cut() -> void:
	var visual: UnitVisual = _visual()
	visual.play_state(&"idle")
	_tick(visual, 0.5)
	var guard_lean: float = visual.get_figure().pose.lean
	visual.play_state(&"windup")
	_tick(visual, 0.08)
	assert_true(visual.get_figure().pose.lean < guard_lean - 0.05, "the body coils back during the wind-up")
	assert_true(visual.get_figure().pose.crouch > 2.0, "and drops into the cut")


func test_cloth_chain_keeps_its_link_length_and_trails_the_anchor() -> void:
	var chain: ClothChain = ClothChain.new(6, 8.0)
	var rest: PackedVector2Array = PackedVector2Array()
	for i: int in 7:
		rest.append(Vector2(-float(i) * 8.0, 0.0))
	chain.reset(rest)
	# The anchor drops sideways at 300 px/s for half a second (across the cloth's own direction).
	var most_behind: float = 0.0
	for frame: int in 30:
		for i: int in 7:
			rest[i] += Vector2(0.0, 5.0)
		chain.step(FRAME, rest, 650.0, 5.0)
		most_behind = minf(most_behind, chain.points[6].y - rest[6].y)
		for i: int in range(1, 7):
			assert_almost_eq(chain.points[i].distance_to(chain.points[i - 1]), 8.0, "link %d keeps its length" % i, 0.05)
	# The whole target shape moved with the anchor, but the cloth lags: its tip falls behind its rest.
	assert_true(most_behind < -2.0, "the tip lags behind where the shape says it should be (by %.1f px)" % -most_behind)


func test_skirt_swings_back_when_running_and_forward_when_stopping() -> void:
	var visual: UnitVisual = _visual()
	visual.get_figure().refresh()
	visual.play_state(&"idle")
	_tick(visual, 0.4)
	var motion: SecondaryMotion = visual.get_figure().secondary
	assert_true(motion != null and motion.loose_armour, "the samurai has swinging armour")
	visual.play_state(&"run")
	for i: int in 30:
		visual.position.x += 3.5
		_tick(visual, FRAME)
	assert_true(motion.skirt.value > 0.08, "the skirt trails behind him while running (%.3f)" % motion.skirt.value)
	assert_true(motion.leg_front.value > 0.04, "the hakama legs trail too")
	visual.play_state(&"idle")
	var lowest: float = motion.skirt.value
	for i: int in 40:
		_tick(visual, FRAME)
		lowest = minf(lowest, motion.skirt.value)
	assert_true(lowest < 0.0, "when he stops, the skirt swings on past upright (%.3f)" % lowest)
	_tick(visual, 2.0)
	assert_true(absf(motion.skirt.value) < 0.03, "and then settles")


func test_scarf_streams_behind_a_running_samurai_and_hangs_when_still() -> void:
	var visual: UnitVisual = _visual()
	visual.play_state(&"idle")
	_tick(visual, 1.0)
	var figure: InkFigure = visual.get_figure()
	var to_local: Transform2D = figure.global_transform.affine_inverse()
	var chain: ClothChain = figure.secondary.scarf[0]
	var still_tip: Vector2 = (to_local * chain.points)[chain.points.size() - 1]
	var still_anchor: Vector2 = (to_local * chain.points)[0]
	visual.play_state(&"run")
	for i: int in 40:
		visual.position.x += 3.5
		_tick(visual, FRAME)
	to_local = figure.global_transform.affine_inverse()
	var run_points: PackedVector2Array = to_local * chain.points
	var run_tip: Vector2 = run_points[run_points.size() - 1]
	assert_true(run_tip.x < run_points[0].x - 25.0, "the scarf streams out behind him when running")
	assert_true(run_tip.y - run_points[0].y < still_tip.y - still_anchor.y, "and rises from where it hung")


func test_cloth_does_not_explode_on_teleport_or_flip() -> void:
	var visual: UnitVisual = _visual()
	visual.play_state(&"run")
	for i: int in 20:
		visual.position.x += 3.5
		_tick(visual, FRAME)
	visual.position.x += 900.0
	_tick(visual, FRAME)
	visual.set_facing(-1)
	for i: int in 30:
		_tick(visual, FRAME)
	var figure: InkFigure = visual.get_figure()
	var chain: ClothChain = figure.secondary.scarf[0]
	var reach: float = chain.link * float(chain.points.size())
	for point: Vector2 in chain.points:
		assert_true(point.distance_to(chain.points[0]) <= reach + 1.0, "scarf points stay within the chain's length")
	assert_true(absf(figure.secondary.skirt.value) < 0.5, "the skirt does not spin out after a teleport")


## The Oni's club must never pass through its own head (it did in the raised pose).
func test_oni_club_stays_clear_of_its_head() -> void:
	var figure: InkFigure = InkFigure.new()
	figure.height = 100.0
	add_to_tree(figure)
	figure.kind = InkFigure.Kind.ONI_BRUTE
	var spec: FigureKinds.Spec = figure.spec
	var poses: Dictionary = {}
	for state: StringName in [&"idle", &"windup", &"strike", &"hurt"]:
		poses[String(state)] = FigureKinds.pose(InkFigure.Kind.ONI_BRUTE, state)
	var pairs: Array = [[&"idle", &"windup"], [&"windup", &"strike"], [&"strike", &"idle"]]
	var checked: Array[FigurePose] = []
	for name: String in poses:
		checked.append(poses[name])
	for pair: Array in pairs:
		for weight: float in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
			var blended: FigurePose = FigurePose.new()
			blended.copy_from(poses[String(pair[0])])
			blended.blend_toward(poses[String(pair[1])], weight)
			checked.append(blended)
	for pose: FigurePose in checked:
		figure.pose.copy_from(pose)
		figure.refresh()
		# Head: a disc around the skull plus the horn and the mane's far horn (head space -> torso space).
		var head_centre: Vector2 = spec.neck + Vector2(3.0, -6.5)
		var horn: PackedVector2Array = PackedVector2Array([spec.neck + Vector2(5.0, -11.0), spec.neck + Vector2(9.0, -17.0),
				spec.neck + Vector2(10.0, -25.0), spec.neck + Vector2(7.0, -30.5)])
		var tilt: Transform2D = Transform2D(pose.head_tilt, spec.neck)
		var hits: int = 0
		var along: float = 4.0
		while along <= 66.0:
			var point: Vector2 = figure.weapon_local * Vector2(along, 0.0)
			var in_head: Vector2 = tilt.affine_inverse() * point
			if in_head.distance_to(Vector2(3.0, -6.5)) < 9.5 + 4.0 or point.distance_to(head_centre) < 6.0:
				hits += 1
			for corner: Vector2 in horn:
				if point.distance_to(tilt * (corner - spec.neck)) < 3.0 + 2.5:
					hits += 1
			along += 3.0
		assert_eq(hits, 0, "the Oni's club stays clear of its head (%d points inside it)" % hits)
