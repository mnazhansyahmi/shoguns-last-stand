extends "res://tests/test_case.gd"
## The atmosphere pass: a theme for every stage (and they stay light enough behind the fighters),
## wind that changes over time, swaying reeds, falling leaves, light rays and the sun's rim light.

const BACKDROP_SCENE: PackedScene = preload("res://scenes/backdrops/bamboo_outskirts.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const FRAME: float = 1.0 / 60.0


func cleanup() -> void:
	Atmosphere.set_theme(null)
	Atmosphere.time = 0.0
	SceneRoutes.battle_stage = null
	super.cleanup()


func _themes() -> Array[AtmosphereTheme]:
	var themes: Array[AtmosphereTheme] = []
	for stage: StageData in StageProgression.default_region().stages:
		themes.append(stage.atmosphere)
	return themes


# --- Themes ---------------------------------------------------------------------

func test_every_stage_has_its_own_theme() -> void:
	var stages: Array[StageData] = StageProgression.default_region().stages
	var ids: Dictionary = {}
	for stage: StageData in stages:
		assert_true(stage.atmosphere != null, "%s has an atmosphere theme" % stage.stage_id)
		if stage.atmosphere == null:
			continue
		assert_true(not ids.has(stage.atmosphere.theme_id), "%s's theme is its own (%s)" % [stage.stage_id, stage.atmosphere.theme_id])
		ids[stage.atmosphere.theme_id] = true
	var themes: Array[AtmosphereTheme] = _themes()
	for i: int in themes.size():
		for j: int in range(i + 1, themes.size()):
			var apart: float = absf(themes[i].sky_mid.h - themes[j].sky_mid.h) + absf(themes[i].sky_low.v - themes[j].sky_low.v) \
					+ absf(themes[i].sky_top.v - themes[j].sky_top.v) + absf(themes[i].sky_horizon.h - themes[j].sky_horizon.h)
			assert_true(apart > 0.08 or themes[i].eclipse != themes[j].eclipse, "themes %d and %d look different" % [i + 1, j + 1])


func test_every_theme_keeps_the_fighters_readable() -> void:
	for theme: AtmosphereTheme in _themes():
		for entry: Dictionary in theme.action_band_colors():
			var color: Color = entry["color"]
			var ratio: float = InkPalette.contrast(InkPalette.INK, color)
			assert_true(ratio >= float(entry["ratio"]), "%s: %s vs ink is at least %.1f:1 (got %.2f)" % [theme.theme_id, entry["name"], entry["ratio"], ratio])
		assert_true(InkPalette.contrast(InkPalette.INK, theme.rim_color) >= 3.0, "%s: the rim light shows against ink" % theme.theme_id)
		assert_true(InkPalette.contrast(InkPalette.INK, theme.reed_plume) >= 3.0, "%s: reed plumes are light" % theme.theme_id)
		for leaf: Color in theme.leaf_colors:
			assert_true(InkPalette.contrast(InkPalette.INK, leaf) >= 2.0, "%s: leaves are visible against ink" % theme.theme_id)


func test_sky_gets_lighter_toward_the_horizon() -> void:
	for theme: AtmosphereTheme in _themes():
		var top: float = InkPalette.luminance(theme.sky_top)
		var low: float = InkPalette.luminance(theme.sky_low)
		var horizon: float = InkPalette.luminance(theme.sky_horizon)
		assert_true(top < low and low <= horizon + 0.001, "%s: indigo at the top, gold at the horizon" % theme.theme_id)


# --- Wind -------------------------------------------------------------------------

func test_wind_strength_changes_over_time_and_stays_in_range() -> void:
	Atmosphere.set_theme(load("res://data/atmosphere/golden_sunset.tres") as AtmosphereTheme)
	var lowest: float = 2.0
	var highest: float = -1.0
	var t: float = 0.0
	while t < 180.0:
		var strength: float = Atmosphere.wind_strength(t)
		assert_true(strength >= 0.0 and strength <= 1.0, "wind %.2f is within 0..1 at %.0f s" % [strength, t])
		lowest = minf(lowest, strength)
		highest = maxf(highest, strength)
		t += 0.5
	assert_true(highest - lowest > 0.25, "gusts make the wind change (%.2f to %.2f)" % [lowest, highest])
	assert_true(absf(Atmosphere.wind_at(0.0, 5.0) - Atmosphere.wind_at(900.0, 5.0)) > 0.01, "a gust is a wave: the wind differs along the field")


func test_windier_stages_blow_harder() -> void:
	var calm: AtmosphereTheme = load("res://data/atmosphere/misty_grove.tres") as AtmosphereTheme
	var wild: AtmosphereTheme = load("res://data/atmosphere/ember_hollow.tres") as AtmosphereTheme
	var calm_sum: float = 0.0
	var wild_sum: float = 0.0
	for i: int in 100:
		Atmosphere.set_theme(calm)
		calm_sum += Atmosphere.wind_strength(float(i))
		Atmosphere.set_theme(wild)
		wild_sum += Atmosphere.wind_strength(float(i))
	assert_true(wild_sum > calm_sum, "Oni's Hollow is windier than the Misty Grove")


# --- Backdrop ---------------------------------------------------------------------

func test_backdrop_has_clouds_rays_reeds_and_leaves() -> void:
	var backdrop: RegionBackdrop = add_to_tree(BACKDROP_SCENE.instantiate()) as RegionBackdrop
	var high: BackdropLayer = backdrop.get_node("CloudsHigh") as BackdropLayer
	var low: BackdropLayer = backdrop.get_node("CloudsLow") as BackdropLayer
	assert_true(high.drift_speed != 0.0 and low.drift_speed != 0.0 and high.drift_speed != low.drift_speed, "two cloud layers drift at different speeds")
	var rays: BackdropLayer = backdrop.get_node("Rays") as BackdropLayer
	assert_true(rays.additive and rays.material is CanvasItemMaterial, "the light rays are drawn additively")
	for reed_name: String in ["ReedsBack", "ReedsFront"]:
		var reeds: BackdropLayer = backdrop.get_node(reed_name) as BackdropLayer
		assert_true(reeds.sway and reeds.material is ShaderMaterial, "%s sway in the wind" % reed_name)
	assert_true((backdrop.get_node("ReedsFront") as CanvasItem).z_index > 0 and (backdrop.get_node("LeavesFront") as CanvasItem).z_index > 0, "front reeds and leaves pass in front of the fighters")
	assert_true((backdrop.get_node("ReedsBack") as CanvasItem).z_index == 0, "back reeds stand behind them")
	var leaves: int = 0
	for child: Node in backdrop.get_children():
		if child is AtmosphereLeaves:
			leaves += (child as AtmosphereLeaves).count
	assert_true(leaves >= 20 and leaves <= 60, "a few dozen leaves, not a storm (%d)" % leaves)


func test_menus_hide_the_front_atmosphere_so_buttons_stay_clear() -> void:
	var scene: RegionBackdrop = BACKDROP_SCENE.instantiate() as RegionBackdrop
	scene.front_fog = false
	add_to_tree(scene)
	for node_name: String in ["FrontFog", "ReedsFront", "LeavesFront"]:
		assert_true(not (scene.get_node(node_name) as CanvasItem).visible, "%s is hidden behind menus" % node_name)
	assert_true((scene.get_node("LeavesBack") as CanvasItem).visible, "but the leaves behind the menu keep falling")


func test_reeds_bend_with_the_wind_through_the_shader() -> void:
	var backdrop: RegionBackdrop = add_to_tree(BACKDROP_SCENE.instantiate()) as RegionBackdrop
	var reeds: BackdropLayer = backdrop.get_node("ReedsBack") as BackdropLayer
	var material: ShaderMaterial = reeds.material as ShaderMaterial
	Atmosphere.time = 3.0
	reeds.call(&"_process", FRAME)
	var first: float = material.get_shader_parameter("wind")
	Atmosphere.time = 41.0
	reeds.call(&"_process", FRAME)
	var second: float = material.get_shader_parameter("wind")
	assert_true(absf(first - second) > 0.001, "the shader's wind follows the changing wind (%.2f vs %.2f)" % [first, second])
	assert_almost_eq(float(material.get_shader_parameter("time")), 41.0, "and its clock", 0.001)


func test_backdrop_advances_the_wind_clock_and_pulses_the_rays() -> void:
	var backdrop: RegionBackdrop = add_to_tree(BACKDROP_SCENE.instantiate()) as RegionBackdrop
	var before: float = Atmosphere.time
	var rays: CanvasItem = backdrop.get_node("Rays") as CanvasItem
	var seen: Array[float] = []
	for i: int in 400:
		backdrop.call(&"_process", 0.1)
		seen.append(rays.modulate.a)
	assert_almost_eq(Atmosphere.time - before, 40.0, "the clock advances with the backdrop", 0.01)
	assert_true(seen.max() - seen.min() > 0.15, "the light rays breathe slowly")
	assert_true(seen.min() >= 0.3 and seen.max() <= 1.0, "and stay visible but subtle")


func test_battle_uses_its_stages_theme() -> void:
	var stage: StageData = StageProgression.default_region().stages[3]
	SceneRoutes.battle_stage = stage
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", "user://test_saves/atmosphere_save.json")
	field.set("settings_path", "user://test_saves/atmosphere_settings.cfg")
	add_to_tree(field)
	assert_eq(Atmosphere.current().theme_id, stage.atmosphere.theme_id, "the battle's backdrop wears the stage's theme")
	assert_eq(Atmosphere.current().theme_id, "broken_shrine", "stage 4 is the Broken Shrine's blood-red sunset")
	var rim_color: Color = Atmosphere.rim_material().get_shader_parameter("rim_color")
	assert_eq(rim_color, Atmosphere.rim_color_for(stage.atmosphere), "and the rim light turns to that theme's colour")


# --- Falling leaves ---------------------------------------------------------------

func _leaves(foreground: bool, count: int) -> AtmosphereLeaves:
	var leaves: AtmosphereLeaves = AtmosphereLeaves.new()
	leaves.foreground = foreground
	leaves.count = count
	add_to_tree(leaves)
	leaves.set_process(false)
	return leaves


func test_leaves_fall_and_drift_downwind_and_are_reborn_when_they_leave() -> void:
	Atmosphere.set_theme(load("res://data/atmosphere/golden_sunset.tres") as AtmosphereTheme)
	var leaves: AtmosphereLeaves = _leaves(false, 30)
	leaves.call(&"_process", FRAME)
	var start: PackedVector2Array = leaves.get("_position").duplicate()
	for i: int in 60:
		leaves.call(&"_process", FRAME)
	var now: PackedVector2Array = leaves.get("_position")
	var travelled: Vector2 = Vector2.ZERO
	for i: int in start.size():
		travelled += now[i] - start[i]
	assert_true(travelled.y > 0.0, "leaves sink")
	assert_true(travelled.x > 0.0, "and the wind carries them to the right")
	# Run a long time: none may wander off for good.
	for i: int in 1500:
		leaves.call(&"_process", 0.04)
	var view: Rect2 = (leaves.call(&"_view_rect") as Rect2).grow(300.0)
	var inside: int = 0
	var positions: PackedVector2Array = leaves.get("_position")
	for point: Vector2 in positions:
		if view.has_point(point):
			inside += 1
	assert_true(inside >= 26, "after a minute the leaves are still around the screen (%d of 30)" % inside)


func test_foreground_leaves_are_bigger_and_a_stronger_wind_blows_them_faster() -> void:
	Atmosphere.set_theme(load("res://data/atmosphere/golden_sunset.tres") as AtmosphereTheme)
	var back: AtmosphereLeaves = _leaves(false, 10)
	var front: AtmosphereLeaves = _leaves(true, 10)
	var back_sizes: PackedFloat32Array = back.get("_size")
	var front_sizes: PackedFloat32Array = front.get("_size")
	var back_mean: float = 0.0
	var front_mean: float = 0.0
	for i: int in 10:
		back_mean += back_sizes[i]
		front_mean += front_sizes[i]
	assert_true(front_mean > back_mean * 1.2, "foreground leaves are bigger")
	assert_true(_mean_wind_speed("misty_grove") < _mean_wind_speed("ember_hollow"), "leaves blow faster in the windier stage")


## Average sideways speed of 20 leaves after two seconds in a theme's wind.
func _mean_wind_speed(theme_name: String) -> float:
	Atmosphere.set_theme(load("res://data/atmosphere/%s.tres" % theme_name) as AtmosphereTheme)
	Atmosphere.time = 0.0
	var leaves: AtmosphereLeaves = _leaves(false, 20)
	for i: int in 120:
		leaves.call(&"_process", FRAME)
	var velocities: PackedVector2Array = leaves.get("_velocity")
	var total: float = 0.0
	for velocity: Vector2 in velocities:
		total += velocity.x
	return total / float(velocities.size())


# --- Rim light --------------------------------------------------------------------

func test_every_body_part_carries_the_rim_light_copy() -> void:
	for kind: int in InkFigure.Kind.size():
		var parts: Dictionary = FigurePainter._build(kind as InkFigure.Kind)
		for part_name: StringName in parts:
			var batch: InkBatch = parts[part_name] as InkBatch
			var label: String = "%s / %s" % [InkFigure.Kind.keys()[kind], part_name]
			if part_name == &"shadow" or part_name == &"blade_glow":
				assert_true(batch.uvs.is_empty(), "%s has no rim" % label)
				continue
			assert_eq(batch.uvs.size(), batch.vertices.size(), "%s has a UV per vertex" % label)
			var flagged: int = 0
			for uv: Vector2 in batch.uvs:
				if uv.x > 0.5:
					flagged += 1
			assert_eq(flagged * 2, batch.vertices.size(), "half of %s is the rim copy" % label)


func test_rim_copy_is_drawn_first_and_shares_the_shapes() -> void:
	var plain: InkBatch = InkBatch.new()
	plain.fill_convex(PackedVector2Array([Vector2(0.0, 0.0), Vector2(10.0, 0.0), Vector2(5.0, 8.0)]), Color.RED)
	var lit: InkBatch = plain.with_rim()
	assert_eq(lit.vertices.size(), plain.vertices.size() * 2, "the shapes are there twice")
	assert_eq(lit.indices.size(), plain.indices.size() * 2, "with twice the triangles")
	assert_true(lit.indices[0] < plain.vertices.size() and lit.indices[plain.indices.size()] >= plain.vertices.size(), "the rim copy comes first, the shapes themselves on top")
	assert_true(lit.uvs[0].x > 0.5 and lit.uvs[plain.vertices.size()].x < 0.5, "and only the copy is flagged for the shader")
	assert_eq(lit.colors[plain.vertices.size()], Color.RED, "the real shapes keep their colour")


func test_all_figures_share_one_rim_material() -> void:
	var first: InkFigure = InkFigure.new()
	first.height = 100.0
	add_to_tree(first)
	first.kind = InkFigure.Kind.SAMURAI
	var second: InkFigure = InkFigure.new()
	second.height = 100.0
	add_to_tree(second)
	second.kind = InkFigure.Kind.ONI_BRUTE
	var torso_a: FigurePart = first.get_node("torso") as FigurePart
	var torso_b: FigurePart = second.get_node("torso") as FigurePart
	assert_true(torso_a.material != null and torso_a.material == torso_b.material, "every figure's parts use the same material (so they batch)")
	assert_true(torso_a.material == Atmosphere.rim_material(), "which is the Atmosphere's rim material")
	var offset: Vector2 = Atmosphere.rim_material().get_shader_parameter("rim_offset")
	assert_true(offset.x > 0.0 and offset.y < 0.0, "the light comes from the upper right, where the sun is")
	assert_true(offset.length() >= 1.8 and offset.length() <= 3.0, "and the rim is a thin but clearly visible sliver (%.1f world px)" % offset.length())


func test_shaders_compile_with_the_expected_uniforms() -> void:
	var rim: Shader = load(Atmosphere.RIM_SHADER_PATH) as Shader
	assert_true(rim != null, "the rim shader loads")
	var rim_names: Array[String] = []
	for uniform: Dictionary in rim.get_shader_uniform_list():
		rim_names.append(uniform["name"])
	assert_true(rim_names.has("rim_color") and rim_names.has("rim_offset"), "it takes a colour and an offset")
	var reed: Shader = load("res://scripts/visuals/shaders/reed_sway.gdshader") as Shader
	var reed_names: Array[String] = []
	for uniform: Dictionary in reed.get_shader_uniform_list():
		reed_names.append(uniform["name"])
	assert_true(reed_names.has("wind") and reed_names.has("time"), "the reed shader takes the wind and the time")


func test_rim_stands_out_against_the_sky_of_every_theme() -> void:
	for theme: AtmosphereTheme in _themes():
		var rim: Color = Atmosphere.rim_color_for(theme)
		for backdrop: Color in [theme.sky_horizon, theme.mist, theme.ground_top]:
			assert_true(InkPalette.contrast(rim, backdrop) >= 1.35, "%s: the rim is %.2f:1 against a backdrop colour (needs 1.35)" % [theme.theme_id, InkPalette.contrast(rim, backdrop)])
		assert_true(InkPalette.contrast(rim, InkPalette.INK) >= 5.5, "%s: and strongly against the ink body" % theme.theme_id)
