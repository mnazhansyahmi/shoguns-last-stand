extends "res://tests/test_case.gd"
## The dramatic battle HUD: the portrait medallion shows the samurai's own figure, its ring is the Ultimate meter (glows
## and pulses when READY), health is a katana blade with a ghost trail of lost health and a red pulse at low health, the
## spirit and gate bars show their numbers, and nothing animates (redraws every frame) without a reason.

const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")


func _hud() -> GameHud:
	return add_to_tree(HUD_SCENE.instantiate()) as GameHud


func test_the_medallion_portrait_is_the_samurai_figure_itself() -> void:
	var ring: HudUltimateRing = _hud().get_node("%UltimateRing") as HudUltimateRing
	var viewport: SubViewport = ring.get_portrait_viewport()
	assert_true(viewport != null and viewport.get_parent() == ring, "the portrait is rendered into the medallion's own viewport")
	assert_true(viewport.transparent_bg, "on a clear background (the medallion paints the dusk and the moon)")
	var figure: InkFigure = ring.get_portrait_figure()
	assert_true(figure != null and figure.get_parent() == viewport, "by a real InkFigure")
	assert_eq(figure.kind, InkFigure.Kind.SAMURAI, "of the samurai")


func test_a_hit_leaves_a_ghost_of_the_lost_health_that_drains_away() -> void:
	var hud: GameHud = _hud()
	var blade: HudHealthBlade = hud.get_node("%HealthBlade") as HudHealthBlade
	hud.set_player_health(200.0, 200.0)
	blade.advance(1.0)
	assert_almost_eq(blade.ghost, 1.0, "full health: no ghost")
	assert_true(not blade.is_processing(), "and nothing to animate")
	hud.set_player_health(140.0, 200.0)
	assert_almost_eq(blade.ratio, 0.7, "the blade drops to what is left")
	assert_eq(blade.value_text, "140 / 200", "with the number on it")
	assert_almost_eq(blade.ghost, 1.0, "the lost part stays as a ghost")
	assert_true(blade.is_processing(), "which animates")
	blade.advance(HudHealthBlade.GHOST_HOLD * 0.5)
	assert_almost_eq(blade.ghost, 1.0, "it holds a moment")
	for i: int in 120:
		blade.advance(1.0 / 60.0)
	assert_almost_eq(blade.ghost, 0.7, "then drains down to the health")
	assert_true(not blade.is_processing(), "and the blade stops redrawing every frame")
	hud.set_player_health(180.0, 200.0)
	assert_almost_eq(blade.ghost, 0.9, "healing leaves no ghost")


func test_low_health_pulses_the_blade_and_the_medallion_rim() -> void:
	var hud: GameHud = _hud()
	var blade: HudHealthBlade = hud.get_node("%HealthBlade") as HudHealthBlade
	var ring: HudUltimateRing = hud.get_node("%UltimateRing") as HudUltimateRing
	hud.set_player_health(70.0, 200.0)
	assert_true(not blade.is_low() and not ring.danger, "35%: not low yet")
	hud.set_player_health(50.0, 200.0)
	assert_true(blade.is_low(), "25%: the blade warns")
	assert_true(ring.danger, "and so does the medallion rim")
	for i: int in 200:
		blade.advance(1.0 / 60.0)
	assert_true(blade.is_processing() and ring.is_processing(), "the warning keeps pulsing while health is low")
	hud.set_player_health(0.0, 200.0)
	assert_true(not blade.is_low() and not ring.danger, "down: no pulse")
	hud.set_player_health(200.0, 200.0)
	assert_true(not ring.danger, "healed: calm again")


func test_the_ultimate_ring_fills_and_glows_when_ready() -> void:
	var hud: GameHud = _hud()
	var ring: HudUltimateRing = hud.get_node("%UltimateRing") as HudUltimateRing
	hud.set_ultimate(0.42, false)
	assert_almost_eq(ring.ratio, 0.42, "the ring is 42% round")
	assert_eq(ring.value_text, "42%", "and says so on its plate")
	assert_true(not ring.pulsing and not ring.is_processing(), "calm while charging")
	hud.set_ultimate(1.0, true)
	assert_eq(ring.value_text, "READY", "full: READY")
	assert_true(ring.pulsing and ring.is_processing(), "and it glows and pulses")
	hud.set_ultimate(0.0, false)
	assert_true(not ring.pulsing, "spent: calm again")


func test_spirit_and_gate_show_their_numbers() -> void:
	var hud: GameHud = _hud()
	var spirit: HudSpiritBar = hud.get_node("%SpiritBar") as HudSpiritBar
	var gate: HudGateBar = hud.get_node("%GateBar") as HudGateBar
	hud.set_energy(137.0, 600.0)
	assert_almost_eq(spirit.ratio, 137.0 / 600.0, "the spirit bar fills to the energy")
	assert_eq(spirit.value_text, "137 / 600", "with the number at its end")
	assert_true(spirit.is_processing(), "its ink flows")
	hud.set_energy(0.0, 600.0)
	assert_true(not spirit.is_processing(), "an empty bar does not")
	hud.set_gate_health(1000.0, 1000.0)
	hud.set_gate_health(740.0, 1000.0)
	assert_eq(gate.value_text, "740 / 1000", "the gate bar shows the gate's health")
	assert_true(gate.is_processing(), "a hit flashes it")
	for i: int in 60:
		gate.advance(1.0 / 60.0)
	assert_true(not gate.is_processing(), "briefly")


func test_the_blade_runs_from_the_guard_to_its_point() -> void:
	var blade: HudHealthBlade = _hud().get_node("%HealthBlade") as HudHealthBlade
	var shape: PackedVector2Array = blade.get_blade_polygon()
	assert_true(shape.size() >= 5, "a blade outline")
	var right: float = 0.0
	var left: float = INF
	for point: Vector2 in shape:
		right = maxf(right, point.x)
		left = minf(left, point.x)
	assert_almost_eq(right, blade.size.x - 2.0, "its point reaches the right end", 0.5)
	assert_almost_eq(left, HudHealthBlade.GUARD_WIDTH + HudHealthBlade.COLLAR_WIDTH, "it starts past the guard and collar", 0.5)
	assert_true(not Geometry2D.triangulate_polygon(shape).is_empty(), "and it is a simple shape that fills")


func test_touch_mode_keeps_the_vitals() -> void:
	var hud: GameHud = _hud()
	hud.set_touch_mode(true)
	for path: String in ["%HealthBlade", "%SpiritBar", "%GateBar", "%UltimateRing"]:
		assert_true((hud.get_node(path) as Control).is_visible_in_tree(), "%s stays in touch mode" % path)
	assert_true(not (hud.get_node("%SkillRow") as Control).is_visible_in_tree(), "only the keyboard icon row goes")
