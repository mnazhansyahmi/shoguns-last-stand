extends "res://tests/test_case.gd"
## Every character kind stands on two visible legs: at ankle height the drawn silhouette is two separate stretches
## (two feet), not one solid block. The Hatamoto once hung a solid skirt panel down to the ground and showed none.

const STEP: float = 1.0 / 60.0
## The silhouette is read this high above the ground (figure units): through the feet and ankles.
const ROW: float = 4.0
## Parts that are not the body (they may cross the legs without being legs).
const NOT_BODY: Array[StringName] = [&"shadow", &"marker", &"weapon", &"bow", &"yumi_back", &"banner", &"blade_glow", &"shield"]


func _height(kind: InkFigure.Kind) -> float:
	match kind:
		InkFigure.Kind.ONI_BRUTE:
			return 190.0
		InkFigure.Kind.FALLEN_DAIMYO:
			return 300.0
	return 110.0


## The horizontal stretches (x ranges, figure units) the body covers `ROW` units above the ground.
func _runs(figure: InkFigure) -> Array[Vector2]:
	var scale: float = figure.get_unit_scale()
	var y: float = -ROW * scale
	var spans: Array[Vector2] = []
	for child: Node in figure.get_children():
		var part: FigurePart = child as FigurePart
		if part == null or not part.visible or part.batch == null or NOT_BODY.has(part.part_name):
			continue
		var batch: InkBatch = part.batch
		var count: int = batch.vertices.size()
		if batch.uvs.size() == count and count > 0:
			count = count / 2
		for i: int in range(0, batch.indices.size(), 3):
			var points: Array[Vector2] = []
			for k: int in 3:
				var index: int = batch.indices[i + k]
				if index >= count:
					points.clear()
					break
				points.append(part.transform * batch.vertices[index])
			if points.size() != 3:
				continue
			var low: float = INF
			var high: float = -INF
			for edge: int in 3:
				var a: Vector2 = points[edge]
				var b: Vector2 = points[(edge + 1) % 3]
				if (a.y - y) * (b.y - y) <= 0.0 and not is_equal_approx(a.y, b.y):
					var x: float = a.x + (b.x - a.x) * (y - a.y) / (b.y - a.y)
					low = minf(low, x)
					high = maxf(high, x)
			if low <= high:
				spans.append(Vector2(low, high) / scale)
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var runs: Array[Vector2] = []
	for span: Vector2 in spans:
		if not runs.is_empty() and span.x <= runs[runs.size() - 1].y + 0.8:
			runs[runs.size() - 1].y = maxf(runs[runs.size() - 1].y, span.y)
		else:
			runs.append(span)
	return runs


func test_every_kind_stands_on_two_visible_legs() -> void:
	for kind: int in InkFigure.Kind.values():
		if kind == InkFigure.Kind.FLYING_SPIRIT:
			continue # Legless flight is asserted separately in test_region_2_art.
		var visual: UnitVisual = UnitVisual.new()
		visual.figure_kind = kind as InkFigure.Kind
		visual.figure_height = _height(kind as InkFigure.Kind)
		add_to_tree(visual)
		visual.set_process(false)
		var figure: InkFigure = visual.get_figure()
		for state: StringName in [&"idle", &"windup", &"strike", &"hurt", &"cast"]:
			visual.play_state(state)
			for frame: int in 40:
				visual.call(&"_process", STEP)
			var runs: Array[Vector2] = _runs(figure)
			assert_true(runs.size() >= 2, "%s %s: the body is %d solid stretch(es) at ankle height, not two legs" % [
					InkFigure.Kind.keys()[kind], state, runs.size()])
		visual.free()


func test_the_hatamoto_keeps_the_guardians_plain_legs_and_the_samurai_is_leaner() -> void:
	for kind: InkFigure.Kind in [InkFigure.Kind.HATAMOTO]:
		var plain: FigureKinds.Spec = FigureKinds.spec(kind)
		var guardian: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.SPEAR_GUARDIAN)
		assert_true(absf(plain.thigh_w.x - guardian.thigh_w.x) < 1.0 and absf(plain.shin_w.x - guardian.shin_w.x) < 1.5, "%s legs are as slim as the Spear Guardian's" % InkFigure.Kind.keys()[kind])
		assert_true(FigurePainter.layout(kind).has(&"foot_f"), "the foot stays flat independently of the shin")
	var lean: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.SAMURAI)
	assert_true(lean.thigh_w.x >= 9.0 and lean.thigh_w.x < FigureKinds.spec(InkFigure.Kind.HATAMOTO).thigh_w.x,
			"the light samurai has real trouser volume while remaining slimmer than armoured allies")
	assert_true(FigurePainter.layout(InkFigure.Kind.SAMURAI).has(&"foot_f"), "the samurai keeps independent soles")
	var order: Array[StringName] = FigurePainter.layout(InkFigure.Kind.HATAMOTO)
	for name: StringName in [&"thigh_f", &"shin_f", &"thigh_b", &"shin_b"]:
		assert_true(order.has(name), "the Hatamoto draws %s" % name)
		assert_true(FigurePainter.part(InkFigure.Kind.HATAMOTO, name) != null, "and it has a shape")
	assert_true(not order.has(&"hakama_f"), "and no solid hakama block over the legs")
