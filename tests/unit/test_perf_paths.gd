extends "res://tests/test_case.gd"
## The performance shortcuts behave exactly like the slow paths they replace: the batched effect shapes match what
## stroke() and a circle drew, blood is freed the moment there is nothing left to draw, a figure standing still does not
## re-solve its stance, and a settled pose stops being blended (and starts again on the next state).

const ASHIGARU: InkFigure.Kind = InkFigure.Kind.ASHIGARU


func test_a_segment_is_the_same_quad_as_a_two_point_stroke() -> void:
	var a: Vector2 = Vector2(3.0, -2.0)
	var b: Vector2 = Vector2(40.0, 17.0)
	var color: Color = Color(0.6, 0.1, 0.1, 0.8)
	var stroke: InkBatch = InkBatch.new()
	stroke.stroke(PackedVector2Array([a, b]), 1.4, 5.0, color)
	var segment: InkBatch = InkBatch.new()
	segment.segment(a, b, 1.4, 5.0, color)
	assert_eq(segment.vertices, stroke.vertices, "the same four corners")
	assert_eq(segment.indices, stroke.indices, "drawn as the same two triangles")
	assert_eq(segment.colors, stroke.colors, "in the same colour")
	var empty: InkBatch = InkBatch.new()
	empty.segment(a, a, 2.0, 2.0, color)
	assert_eq(empty.indices.size(), 6, "a zero-length segment still draws (it points right, as a stroke does)")


func test_a_disc_is_a_fan_of_triangles_around_its_centre() -> void:
	var batch: InkBatch = InkBatch.new()
	var center: Vector2 = Vector2(10.0, 20.0)
	batch.disc(center, 4.0, Color.RED, 10)
	assert_eq(batch.vertices.size(), 11, "the centre and ten points on the rim")
	assert_eq(batch.indices.size(), 30, "ten triangles")
	for i: int in range(1, batch.vertices.size()):
		assert_almost_eq(batch.vertices[i].distance_to(center), 4.0, "every rim point is on the circle", 0.0001)
	for index: int in batch.indices:
		assert_true(index >= 0 and index < batch.vertices.size(), "no triangle points outside the batch")


func test_a_triangulated_blot_is_drawn_without_triangulating_it_again() -> void:
	var blot: PackedVector2Array = PackedVector2Array([Vector2(-5.0, -3.0), Vector2(6.0, -4.0), Vector2(7.0, 5.0), Vector2(-4.0, 4.0)])
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(blot)
	var batch: InkBatch = InkBatch.new()
	batch.fill_triangulated(blot, triangles, Color.BLACK, 2.0)
	assert_eq(batch.indices.size(), triangles.size(), "the cached triangles are used as they are")
	assert_eq(batch.vertices[1], blot[1] * 2.0, "scaled about the origin")
	var none: InkBatch = InkBatch.new()
	none.fill_triangulated(blot, PackedInt32Array(), Color.BLACK)
	assert_true(none.is_empty(), "a blot that could not be triangulated draws nothing")


func test_blood_is_freed_once_the_spray_is_gone_and_every_drop_has_landed() -> void:
	var blood: InkBlood = InkBlood.new()
	blood.setup(1.0, 60.0, false, false, false)
	add_to_tree(blood)
	assert_eq(blood.live_drops(), InkBlood.amount(false, false, false), "all the drops start in the air")
	var ticks: int = 0
	while not blood.is_queued_for_deletion() and ticks < 200:
		blood._process(1.0 / 60.0)
		ticks += 1
	assert_true(blood.is_queued_for_deletion(), "it frees itself")
	assert_eq(blood.live_drops(), 0, "with no drop left in the air")
	assert_true(blood.progress() >= InkBlood.SPRAY_END, "and not before the spray was done")
	assert_true(blood.age < InkBlood.LIFETIME, "which is before its full lifetime")


func test_a_figure_standing_still_keeps_its_stance_and_a_move_still_steps() -> void:
	var spec: FigureKinds.Spec = FigureKinds.spec(ASHIGARU)
	var still: LegGait = LegGait.new()
	var once: LegGait = LegGait.new()
	var frame: Transform2D = Transform2D(0.0, Vector2.ONE, 0.0, Vector2(300.0, 400.0))
	once.step(frame, spec, 1.0 / 60.0)
	for i: int in 5:
		still.step(frame, spec, 1.0 / 60.0)
	assert_eq(still.targets, once.targets, "the feet stay where they were planted")
	assert_eq(still.heel, once.heel, "with the heels flat")
	assert_almost_eq(still.bob, 0.0, "no bob")
	assert_almost_eq(still.phase, once.phase, "and the gait does not advance")
	still.step(frame.translated(Vector2(30.0, 0.0)), spec, 1.0 / 60.0)
	assert_true(still.phase > 0.0 or not still.planted[0] or not still.planted[1], "moving again takes a step at once")
	still.reset()
	still.step(frame, spec, 1.0 / 60.0)
	assert_eq(still.targets, once.targets, "after a reset it solves the stance from scratch")


func test_a_settled_pose_stops_blending_and_the_next_state_starts_it_again() -> void:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = ASHIGARU
	visual.figure_height = 110.0
	add_to_tree(visual)
	visual.play_state(&"idle")
	for i: int in 60:
		visual._process(1.0 / 60.0)
	assert_true(visual._blend_left > 0.0, "a second after a state starts it is still easing")
	for i: int in 600:
		visual._process(1.0 / 60.0)
	assert_true(visual._blend_left <= 0.0, "ten seconds on it has settled and is no longer blended")
	assert_almost_eq(visual._pose.lean, visual._target.lean, "right on its target", 0.0001)
	visual.play_state(&"windup")
	assert_true(visual._blend_left > 0.0, "a new state starts the blend again")
	var before: float = visual._pose.blade
	for i: int in 10:
		visual._process(1.0 / 60.0)
	assert_true(not is_equal_approx(visual._pose.blade, before) or is_equal_approx(visual._target.blade, before), "and the pose moves toward the new target")
