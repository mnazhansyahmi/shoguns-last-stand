extends "res://tests/test_case.gd"
## Characters brought to life: per-unit variation (phase, speed, size, spacing, head turns and
## stumbles), idle personalities, torn fluttering cloth, flickering glows, the allies' lighter tone,
## allies spreading apart, health bars that fade after 2 s, and leaves that stay out of the HUD.

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const FRAME: float = 1.0 / 60.0

const ALLY_KINDS: Array[InkFigure.Kind] = [InkFigure.Kind.ASHIGARU, InkFigure.Kind.YUMI_ARCHER,
		InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.SPEAR_GUARDIAN, InkFigure.Kind.ONMYOJI, InkFigure.Kind.HATAMOTO]
const TATTERED_KINDS: Array[InkFigure.Kind] = [InkFigure.Kind.SAMURAI, InkFigure.Kind.ASHIGARU, InkFigure.Kind.YUMI_ARCHER,
		InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.SPEAR_GUARDIAN, InkFigure.Kind.ONMYOJI, InkFigure.Kind.HATAMOTO,
		InkFigure.Kind.ONI_BRUTE]


func _visual(kind: InkFigure.Kind, height: float = 100.0) -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = kind
	visual.figure_height = height
	add_to_tree(visual)
	visual.set_process(false)
	return visual


func _tick(visual: UnitVisual, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME):
		visual.call(&"_process", FRAME)


func _enemy(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	return enemy


func _ally(id: String, x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find(id), x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally


# --- Variation ---------------------------------------------------------------

func test_variation_stays_in_its_ranges() -> void:
	for seed_value: int in range(1, 41):
		var visual: UnitVisual = _visual(InkFigure.Kind.HOLLOW_SOLDIER)
		visual.enable_variation(seed_value)
		assert_true(absf(visual.size_variation - 1.0) <= UnitVisual.VARY_SIZE + 0.0001, "size within +-6%% (seed %d)" % seed_value)
		assert_true(absf(visual.speed_variation - 1.0) <= UnitVisual.VARY_SPEED + 0.0001, "speed within +-10%% (seed %d)" % seed_value)
		assert_true(visual.position.y >= -UnitVisual.VARY_OFFSET_UP - 0.0001 and visual.position.y <= UnitVisual.VARY_OFFSET_DOWN + 0.0001,
				"vertical offset is small (seed %d)" % seed_value)


func test_variation_scales_the_figure_and_is_repeatable_per_seed() -> void:
	var first: UnitVisual = _visual(InkFigure.Kind.ASHIGARU, 100.0)
	first.enable_variation(7)
	first.configure(InkFigure.Kind.ASHIGARU, 100.0)
	var again: UnitVisual = _visual(InkFigure.Kind.ASHIGARU, 100.0)
	again.enable_variation(7)
	again.configure(InkFigure.Kind.ASHIGARU, 100.0)
	var other: UnitVisual = _visual(InkFigure.Kind.ASHIGARU, 100.0)
	other.enable_variation(8)
	other.configure(InkFigure.Kind.ASHIGARU, 100.0)
	assert_almost_eq(first.get_figure().height, 100.0 * first.size_variation, "the figure is drawn at its own size")
	assert_eq(first.size_variation, again.size_variation, "a seed repeats the size")
	assert_eq(first.speed_variation, again.speed_variation, "a seed repeats the speed")
	assert_eq(first.get_figure().clock, again.get_figure().clock, "a seed repeats the animation phase")
	assert_true(first.size_variation != other.size_variation or first.speed_variation != other.speed_variation, "another seed gives another unit")


func test_a_crowd_is_never_in_step() -> void:
	var clocks: Dictionary = {}
	var strides: Dictionary = {}
	var flickers: Dictionary = {}
	for seed_value: int in range(1, 13):
		var visual: UnitVisual = _visual(InkFigure.Kind.HOLLOW_SOLDIER)
		visual.enable_variation(seed_value)
		var fig: InkFigure = visual.get_figure()
		clocks[snappedf(fig.clock, 0.01)] = true
		strides[snappedf(fig.stride_phase, 0.01)] = true
		flickers[snappedf(fig.flicker_phase, 0.01)] = true
	assert_true(clocks.size() >= 11, "twelve soldiers start their cloth on different phases")
	assert_true(strides.size() >= 11, "twelve soldiers start their stride on different phases")
	assert_true(flickers.size() >= 11, "twelve soldiers' lights flicker on different phases")


func test_enemies_and_allies_get_their_own_speed_and_spacing() -> void:
	var speeds: Dictionary = {}
	var spacings: Dictionary = {}
	for i: int in 8:
		var enemy: Enemy = _enemy(400.0 + float(i) * 50.0)
		speeds[snappedf((enemy.get_node("Visual") as UnitVisual).speed_variation, 0.001)] = true
		spacings[snappedf(enemy.get("_spacing_scale"), 0.001)] = true
		assert_true(float(enemy.get("_spacing_scale")) >= 0.75, "an enemy keeps at least its own width's room")
	assert_true(speeds.size() >= 7, "eight enemies walk at different speeds")
	assert_true(spacings.size() >= 7, "eight enemies keep different distances (irregular spacing)")
	var ally_speeds: Dictionary = {}
	for i: int in 6:
		ally_speeds[snappedf((_ally("ashigaru", 600.0).get_node("Visual") as UnitVisual).speed_variation, 0.001)] = true
	assert_true(ally_speeds.size() >= 5, "allies walk at different speeds too")


func test_head_turns_and_stumbles_happen_and_end() -> void:
	var visual: UnitVisual = _visual(InkFigure.Kind.HOLLOW_SOLDIER)
	visual.enable_variation(3)
	visual.play_state(&"idle")
	visual.set("_event_timer", 0.0)
	_tick(visual, FRAME * 2.0)
	assert_eq(visual.get("_event"), &"head_turn", "a standing unit turns its head")
	var length: float = visual.get("_event_length")
	assert_true(length >= 0.5 and length <= 1.2, "a head turn is brief")
	_tick(visual, length + 0.2)
	assert_eq(visual.get("_event"), &"", "the head turn ends")
	# Running units may stumble: the stride slows for the first half.
	var fig: InkFigure = visual.get_figure()
	visual.play_state(&"run")
	visual.set("_event", &"stumble")
	visual.set("_event_time", 0.0)
	visual.set("_event_length", 0.45)
	var before: float = fig.stride_phase
	_tick(visual, FRAME * 3.0)
	var moved: float = absf(fig.stride_phase - before)
	assert_true(moved < FigureKinds.spec(InkFigure.Kind.HOLLOW_SOLDIER).cadence * FRAME * 3.0, "a stumble catches the feet")


func test_no_variation_means_no_events() -> void:
	var visual: UnitVisual = _visual(InkFigure.Kind.SAMURAI)
	visual.play_state(&"idle")
	_tick(visual, 20.0)
	assert_eq(visual.get("_event"), &"", "the player's samurai never stumbles or turns on its own")
	assert_eq(visual.speed_variation, 1.0, "the samurai walks at the speed in its data")
	assert_eq(visual.size_variation, 1.0, "the samurai is drawn at his size")


# --- Idle personality ------------------------------------------------------------

## (range of the torso's lean, range of the hip height) over ten seconds of standing.
func _idle_motion(kind: InkFigure.Kind) -> Vector2:
	var visual: UnitVisual = _visual(kind, 100.0)
	visual.play_state(&"idle")
	var fig: InkFigure = visual.get_figure()
	var lean_min: float = INF
	var lean_max: float = -INF
	var hip_min: float = INF
	var hip_max: float = -INF
	for i: int in 600:
		visual.call(&"_process", FRAME)
		if i < 60:
			continue
		var lean: float = fig.torso_xf.get_rotation()
		lean_min = minf(lean_min, lean)
		lean_max = maxf(lean_max, lean)
		hip_min = minf(hip_min, fig.hip.y)
		hip_max = maxf(hip_max, fig.hip.y)
	return Vector2(lean_max - lean_min, hip_max - hip_min)


func test_idle_personalities_differ_by_character() -> void:
	var samurai: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.SAMURAI)
	var oni: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.ONI_BRUTE)
	var healer: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.SHRINE_HEALER)
	assert_true(oni.breath_hz > samurai.breath_hz * 2.0, "the Oni heaves for breath; the samurai breathes slowly")
	assert_true(oni.idle_bob.x > samurai.idle_bob.x + 1.0, "the Oni stomps from foot to foot; the samurai stands still")
	assert_true(oni.idle_lean.x > healer.idle_lean.x and healer.idle_lean.x > samurai.idle_lean.x, "restless Oni > gentle healer > calm samurai")
	assert_true(healer.idle_lean.y < oni.idle_lean.y, "the healer sways slowly")
	var oni_motion: Vector2 = _idle_motion(InkFigure.Kind.ONI_BRUTE)
	var samurai_motion: Vector2 = _idle_motion(InkFigure.Kind.SAMURAI)
	var healer_motion: Vector2 = _idle_motion(InkFigure.Kind.SHRINE_HEALER)
	assert_true(oni_motion.x > samurai_motion.x * 2.0, "the Oni's body moves much more than the samurai's (%.4f vs %.4f)" % [oni_motion.x, samurai_motion.x])
	assert_true(oni_motion.y > samurai_motion.y + 1.0, "the Oni shifts its weight; the samurai does not")
	assert_true(healer_motion.x > samurai_motion.x, "the healer sways more than the samurai")
	var heads: Dictionary = {}
	for kind: InkFigure.Kind in TATTERED_KINDS:
		heads[FigureKinds.spec(kind).idle_head] = true
	assert_true(heads.size() >= 6, "the characters move their heads in their own ways")


# --- Torn, fluttering cloth -------------------------------------------------------

func test_every_character_has_tattered_cloth() -> void:
	for kind: InkFigure.Kind in TATTERED_KINDS:
		assert_true(FigureTatters.has_tatters(kind), "kind %d has tatters" % kind)
		assert_true(FigurePainter.layout(kind).has(&"hem"), "kind %d draws a hem part" % kind)
		var batch: InkBatch = FigureTatters.batch(kind, 0)
		assert_true(not batch.is_empty(), "kind %d's tatters have geometry" % kind)
		assert_eq(batch.uvs.size(), batch.vertices.size(), "kind %d's tatters carry the rim light" % kind)
	assert_true(FigurePainter.layout(InkFigure.Kind.HOLLOW_SOLDIER).has(&"hem"), "the Hollow Soldier keeps his tattered skirt")


func test_tatters_flutter_between_cached_phases() -> void:
	for kind: InkFigure.Kind in TATTERED_KINDS:
		var a: InkBatch = FigureTatters.batch(kind, 0)
		var b: InkBatch = FigureTatters.batch(kind, 4 * FigureTatters.WIND_LEVELS)
		assert_true(a != b, "kind %d has more than one cloth shape" % kind)
		assert_true(a.vertices != b.vertices, "kind %d's cloth moves between phases" % kind)
		assert_true(FigureTatters.batch(kind, 4 * FigureTatters.WIND_LEVELS) == b, "kind %d's shapes are cached, not rebuilt" % kind)
	var calm: InkBatch = FigureTatters.batch(InkFigure.Kind.ASHIGARU, 3 * FigureTatters.WIND_LEVELS)
	var windy: InkBatch = FigureTatters.batch(InkFigure.Kind.ASHIGARU, 3 * FigureTatters.WIND_LEVELS + 2)
	assert_true(calm.vertices != windy.vertices, "the wind bends the cloth further")


func test_cloth_phase_follows_each_figures_own_clock() -> void:
	var keys: Dictionary = {}
	for seed_value: int in range(1, 25):
		var visual: UnitVisual = _visual(InkFigure.Kind.ASHIGARU)
		visual.enable_variation(seed_value)
		keys[FigureTatters.key(visual.get_figure())] = true
	assert_true(keys.size() >= 6, "24 soldiers show at least six different cloth shapes at once (got %d)" % keys.size())
	var fig: InkFigure = _visual(InkFigure.Kind.ASHIGARU).get_figure()
	fig.clock = 0.0
	var first: int = FigureTatters.key(fig)
	fig.clock = 0.4
	assert_true(FigureTatters.key(fig) != first, "the cloth key advances with the clock")


func test_tatters_are_drawn_by_the_figure() -> void:
	for kind: InkFigure.Kind in TATTERED_KINDS:
		var fig: InkFigure = _visual(kind).get_figure()
		fig.clock = 0.3
		fig.refresh()
		var hem: FigurePart = fig.get_node("hem") as FigurePart
		assert_true(hem != null and hem.batch != null and not hem.batch.is_empty(), "kind %d's hem part holds a cloth shape" % kind)
		assert_true(hem != null and hem.material != null, "kind %d's hem is lit by the rim light" % kind)
	var banner: FigurePart = _visual(InkFigure.Kind.HATAMOTO).get_figure().get_node("banner") as FigurePart
	assert_true(banner != null and banner.batch != null, "the banner keeps its pole and mon")


# --- Glow and tone ----------------------------------------------------------------

func test_every_character_has_a_glowing_detail_that_flickers() -> void:
	var kinds: Array[InkFigure.Kind] = TATTERED_KINDS.duplicate()
	kinds.append(InkFigure.Kind.HOLLOW_SOLDIER)
	for kind: InkFigure.Kind in kinds:
		var glows: Array[Dictionary] = FigurePainter.glows(kind)
		assert_true(not glows.is_empty(), "kind %d has a glowing detail" % kind)
		var flickers: bool = false
		for definition: Dictionary in glows:
			if float(definition.get("flicker", 0.0)) > 0.0:
				flickers = true
		assert_true(flickers, "kind %d's light flickers" % kind)


func test_glows_flicker_out_of_step() -> void:
	var a: InkFigure = _visual(InkFigure.Kind.ONMYOJI).get_figure()
	var b: InkFigure = _visual(InkFigure.Kind.ONMYOJI).get_figure()
	a.clock = 2.0
	b.clock = 2.0
	a.flicker_phase = 0.0
	b.flicker_phase = 2.4
	a.refresh()
	b.refresh()
	var glows_a: Array = a.get("_fall_glows")
	var glows_b: Array = b.get("_fall_glows")
	assert_true(not glows_a.is_empty() and not glows_b.is_empty(), "the onmyoji has a seal glow")
	if not glows_a.is_empty() and not glows_b.is_empty():
		assert_true(not is_equal_approx((glows_a[0] as FigurePart).modulate.a, (glows_b[0] as FigurePart).modulate.a), "two onmyoji's seals pulse apart")


func test_allies_wear_a_lighter_tone_than_the_enemies() -> void:
	assert_true(InkPalette.luminance(InkPalette.ALLY_INK) > InkPalette.luminance(InkPalette.INK) * 2.0, "the allies' ink is clearly lighter")
	assert_true(InkPalette.contrast(InkPalette.ALLY_INK, InkPalette.INK) >= 1.25, "an ally reads apart from an enemy of the same shape")
	for path: String in DirAccess.get_files_at("res://data/atmosphere"):
		var theme_now: AtmosphereTheme = load("res://data/atmosphere/" + path) as AtmosphereTheme if path.ends_with(".tres") else null
		if theme_now == null:
			continue
		for backdrop: Color in [theme_now.sky_horizon, theme_now.mist, theme_now.ground_top]:
			assert_true(InkPalette.contrast(InkPalette.ALLY_INK, backdrop) >= 3.5, "an ally stands out from the backdrop of %s" % path)
			assert_true(InkPalette.contrast(InkPalette.ALLY_INK_BACK, backdrop) >= 2.8, "an ally's far limbs still read on %s" % path)
	assert_true(InkPalette.luminance(InkPalette.ALLY_INK) < InkPalette.luminance(InkPalette.ALLY_INK_BACK), "the near side is darker than the far side")
	for kind: InkFigure.Kind in ALLY_KINDS:
		assert_true(FigurePainter.is_ally_tone(kind), "kind %d is an ally" % kind)
		var torso: InkBatch = FigurePainter.part(kind, &"torso")
		var has_ally: bool = false
		var has_enemy: bool = false
		for color: Color in torso.colors:
			has_ally = has_ally or (is_equal_approx(color.r, InkPalette.ALLY_INK.r) and is_equal_approx(color.b, InkPalette.ALLY_INK.b))
			has_enemy = has_enemy or (is_equal_approx(color.r, InkPalette.INK.r) and is_equal_approx(color.b, InkPalette.INK.b))
		assert_true(has_ally and not has_enemy, "kind %d's body is drawn in the ally tone" % kind)
	for kind: InkFigure.Kind in [InkFigure.Kind.HOLLOW_SOLDIER, InkFigure.Kind.ONI_BRUTE, InkFigure.Kind.SAMURAI]:
		assert_true(not FigurePainter.is_ally_tone(kind), "kind %d keeps its own ink" % kind)
	assert_eq(FigurePainter.tone(InkFigure.Kind.ASHIGARU, InkPalette.ASHIGARU_GOLD), InkPalette.ASHIGARU_GOLD, "accent colours are not toned")


# --- Allies read apart ---------------------------------------------------------------

func test_allies_are_drawn_in_their_own_lanes() -> void:
	var group: Array[Ally] = []
	for i: int in 6:
		group.append(_ally("ashigaru", 700.0))
	var drawn: Array[float] = []
	for ally: Ally in group:
		drawn.append(ally.global_position.x + (ally.get_node("Visual") as UnitVisual).position.x)
		assert_true(absf(ally.lane_x) <= 70.0, "a lane is a small sideways step")
		assert_almost_eq((ally.get_node("HealthBar") as WorldHealthBar).position.x, ally.lane_x, "the health bar follows its ally's lane")
	drawn.sort()
	for i: int in range(1, drawn.size()):
		assert_true(drawn[i] - drawn[i - 1] >= 8.0, "six allies standing on one spot are drawn at least 8 px apart (%.1f)" % (drawn[i] - drawn[i - 1]))
	assert_true(drawn[drawn.size() - 1] - drawn[0] >= 60.0, "and the group is drawn as a spread-out line")


func test_lanes_change_the_picture_not_the_fight() -> void:
	var group: Array[Ally] = []
	for i: int in 5:
		group.append(_ally("ashigaru", 800.0))
	for step: int in 240:
		for ally: Ally in group:
			ally._physics_process(FRAME)
	for ally: Ally in group:
		assert_true(absf(ally.global_position.x - 800.0) <= 12.0, "an ally's body stays where it was summoned")
		assert_true(absf(ally.get_node("CollisionShape2D").position.x if ally.has_node("CollisionShape2D") else 0.0) < 1.0, "its collision is not moved by its lane")


# --- Health bars -----------------------------------------------------------------------

func test_a_health_bar_hides_two_seconds_after_the_last_hit() -> void:
	var enemy: Enemy = _enemy(500.0)
	var bar: WorldHealthBar = enemy.get_node("HealthBar")
	var health: HealthComponent = enemy.get_node("HealthComponent")
	health.take_damage(5.0)
	assert_true(bar.visible and bar.is_showing_recent_hit(), "a hit shows the bar")
	bar._process(1.5)
	assert_true(bar.visible, "still shown after 1.5 s")
	bar._process(0.6)
	assert_true(not bar.visible, "gone 2 s after the hit")
	assert_true(not bar.is_showing_recent_hit(), "and no longer counted as a recent hit")
	health.take_damage(5.0)
	assert_true(bar.visible and is_equal_approx(bar.modulate.a, 1.0), "the next hit brings it back at full strength")
	bar._process(1.9)
	health.take_damage(5.0)
	bar._process(1.9)
	assert_true(bar.visible, "a hit restarts the two seconds")
	bar._process(0.3)
	assert_true(not bar.visible, "and it hides 2 s after the LAST hit")


func test_a_health_bar_fades_before_it_goes() -> void:
	var enemy: Enemy = _enemy(500.0)
	var bar: WorldHealthBar = enemy.get_node("HealthBar")
	(enemy.get_node("HealthComponent") as HealthComponent).take_damage(5.0)
	bar._process(WorldHealthBar.HIDE_DELAY - WorldHealthBar.FADE_TIME * 0.5)
	assert_true(bar.visible and bar.modulate.a < 0.9 and bar.modulate.a > 0.0, "the bar fades over its last moments")


func test_bars_of_a_crowd_do_not_all_stay_on_screen() -> void:
	var enemies: Array[Enemy] = []
	for i: int in 10:
		enemies.append(_enemy(400.0 + float(i) * 20.0))
		(enemies[i].get_node("HealthComponent") as HealthComponent).take_damage(5.0)
	for enemy: Enemy in enemies:
		(enemy.get_node("HealthBar") as WorldHealthBar)._process(2.1)
	var shown: int = 0
	for enemy: Enemy in enemies:
		if (enemy.get_node("HealthBar") as WorldHealthBar).visible:
			shown += 1
	assert_eq(shown, 0, "a crowd that stopped being hit shows no bars")


# --- Leaves stay out of the HUD ----------------------------------------------------------

func test_leaves_do_not_enter_keep_out_rectangles() -> void:
	var leaves: AtmosphereLeaves = AtmosphereLeaves.new()
	leaves.foreground = true
	leaves.keep_out = [Rect2(0.0, 0.0, 300.0, 200.0)]
	add_to_tree(leaves)
	assert_true(leaves.call(&"_in_keep_out", Vector2(100.0, 100.0), 10.0), "a leaf inside the rectangle is kept out")
	assert_true(leaves.call(&"_in_keep_out", Vector2(310.0, 100.0), 10.0), "so is one touching its edge")
	assert_true(not leaves.call(&"_in_keep_out", Vector2(900.0, 600.0), 10.0), "a leaf elsewhere is drawn")
	leaves.keep_out = []
	assert_true(not leaves.call(&"_in_keep_out", Vector2(100.0, 100.0), 10.0), "with no rectangles nothing is kept out")


func test_the_battlefield_keeps_leaves_off_the_hud_and_controls() -> void:
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", "user://test_saves/life_save.json")
	field.set("settings_path", "user://test_saves/life_settings.cfg")
	add_to_tree(field)
	field.call(&"_update_leaf_keep_out")
	var layers: Array[Node] = field.find_children("*", "AtmosphereLeaves", true, false)
	assert_true(layers.size() >= 2, "the backdrop has its leaf layers")
	for layer: Node in layers:
		assert_true(not (layer as AtmosphereLeaves).keep_out.is_empty(), "%s keeps out of the HUD and the touch controls" % layer.name)
