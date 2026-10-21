extends "res://tests/test_case.gd"
## Region 2, the Burning Village: stages 6-10, unlocked after stage 5 and numbered on from Region 1; the stage select's
## region tabs; the burning-village atmosphere (houses on fire, smoke, embers rising).

const STAGE_SELECT_SCENE: PackedScene = preload("res://scenes/stage_select/stage_select.tscn")
const SAVE_DIR: String = "user://test_region_2/"
const REGION_1_IDS: Array[String] = ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5"]


func cleanup() -> void:
	Atmosphere.set_theme(null)
	super.cleanup()


func _village() -> RegionData:
	return StageProgression.regions()[1]


func _select(cleared: Array[String]) -> StageSelect:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = cleared.duplicate()
	SaveManager.new(SAVE_DIR + "save.json").save_progress(progress)
	var select: StageSelect = STAGE_SELECT_SCENE.instantiate() as StageSelect
	select.save_path = SAVE_DIR + "save.json"
	add_to_tree(select)
	return select


# --- Data ---------------------------------------------------------------------

func test_the_campaign_has_two_regions_and_region_2_has_stages_6_to_10() -> void:
	var regions: Array[RegionData] = StageProgression.regions()
	assert_eq(regions.size(), 2, "two regions")
	assert_eq(regions[0].region_id, "bamboo_outskirts", "Region 1 first")
	var village: RegionData = _village()
	assert_eq(village.display_name, "Burning Village", "Region 2 is the Burning Village")
	assert_eq(village.stages.size(), 5, "five stages")
	for i: int in 5:
		var stage: StageData = village.stages[i]
		assert_eq(stage.stage_id, "stage_%d" % (i + 6), "stage %d keeps its save id" % (i + 6))
		assert_true(not stage.waves.is_empty() and not stage.tagline.is_empty() and stage.tagline.length() <= 32, "%s has waves and a short tagline" % stage.stage_id)
		assert_eq(StageProgression.stage_number(stage), i + 6, "numbered on from Region 1")
	assert_eq(StageProgression.first_stage_number(village), 6, "Region 2 starts at stage 6")
	assert_eq(StageProgression.stage_line(village, village.stages[1]), "Stage 7 - Ashen Fields", "the Continue line")
	assert_eq(StageProgression.all_stages().size(), 10, "ten stages in all")


func test_difficulty_and_rewards_continue_from_stage_5() -> void:
	var stages: Array[StageData] = StageProgression.all_stages()
	for i: int in range(5, stages.size()):
		var before: StageData = stages[i - 1]
		var after: StageData = stages[i]
		assert_true(after.get_full_clear_gold() > before.get_full_clear_gold(), "%s pays more than %s" % [after.stage_id, before.stage_id])
		assert_true(after.clear_xp_bonus > before.clear_xp_bonus, "%s gives more XP" % after.stage_id)
		assert_true(after.waves.size() >= 5, "%s has at least five waves" % after.stage_id)
	assert_true(stages[5].get_enemy_total() >= stages[4].get_enemy_total(), "stage 6 brings at least stage 5's numbers")


# --- Unlocks ------------------------------------------------------------------

func test_stage_6_opens_only_after_stage_5() -> void:
	var village: RegionData = _village()
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	assert_true(not StageProgression.is_region_unlocked(progress, village), "locked until stage 5 is cleared")
	assert_eq(StageProgression.required_stage(village, 0).stage_id, "stage_5", "stage 6 needs stage 5")
	progress.stages_cleared.append("stage_5")
	assert_true(StageProgression.is_unlocked(progress, village, 0), "stage 6 opens after stage 5")
	assert_true(not StageProgression.is_unlocked(progress, village, 1), "stage 7 still locked")
	assert_eq(StageProgression.campaign_continue_stage(progress).stage_id, "stage_6", "Continue moves on to stage 6")
	assert_true(StageProgression.region_of(village.stages[2]) == village, "a stage knows its region")


# --- Stage select -------------------------------------------------------------

func test_the_stage_select_has_a_tab_per_region_and_opens_on_the_next_stages_region() -> void:
	var select: StageSelect = _select(REGION_1_IDS)
	assert_true(select.get_region_tab(0) != null and select.get_region_tab(1) != null, "two region tabs")
	assert_eq(select.get_region_tab(1).text, "Burning Village", "named after the region")
	assert_true(select.get_region_tab(0).custom_minimum_size.y >= TouchLayout.MIN_TOUCH_TARGET, "tabs are big touch targets")
	assert_eq(select.get_region().region_id, "burning_village", "with Region 1 cleared it opens on the Burning Village")
	assert_true(select.get_region_tab(1).button_pressed and not select.get_region_tab(0).button_pressed, "and its tab is lit")
	var first: StageCard = select.get_stage_card(0)
	assert_eq(first.get_number(), 6, "the first card is stage 6")
	assert_true(first.unlocked and not select.get_stage_card(1).unlocked, "stage 6 open, stage 7 locked")
	assert_eq(select.get_stage_card(1).get_locked_text(), "Clear Ember Road", "a locked card names the stage before it")
	assert_eq((select.get_node("%DetailName") as Label).text, "6. Ember Road", "the side panel uses the campaign number")
	select.get_region_tab(0).emit_signal("pressed")
	assert_eq(select.get_region().region_id, "bamboo_outskirts", "the other tab shows Region 1")
	assert_eq(select.get_stage_card(4).get_number(), 5, "numbered 1 to 5")
	assert_true(select.get_stage_card(5) == null, "only Region 1's cards")


func test_a_locked_region_shows_its_cards_padlocked() -> void:
	var select: StageSelect = _select(["stage_1"] as Array[String])
	assert_eq(select.get_region().region_id, "bamboo_outskirts", "a save in Region 1 opens on Region 1")
	select.show_region(_village())
	for i: int in 5:
		assert_true(not select.get_stage_card(i).unlocked, "stage %d locked" % (i + 6))
	assert_eq(select.get_stage_card(0).get_locked_text(), "Clear Oni's Hollow", "stage 6 asks for stage 5")
	assert_true((select.get_play_button() as Button).disabled, "nothing to play there yet")


# --- Atmosphere ---------------------------------------------------------------

func test_region_2_burns() -> void:
	var intensity: float = -1.0
	for stage: StageData in _village().stages:
		var theme: AtmosphereTheme = stage.atmosphere
		assert_eq(theme.scenery, AtmosphereTheme.Scenery.BURNING_VILLAGE, "%s is the burning village" % stage.stage_id)
		assert_true(theme.ember_share > 0.0 and theme.petal_share < 0.2, "%s: embers instead of petals" % stage.stage_id)
		assert_true(theme.fire_intensity > intensity, "%s burns more than the stage before" % stage.stage_id)
		intensity = theme.fire_intensity
		var burning: int = 0
		for site: Vector4 in BurningVillagePainter.house_sites(theme):
			if site.w > 0.0:
				burning += 1
		assert_true(burning >= 2, "%s has houses on fire (%d)" % [stage.stage_id, burning])
		assert_true(theme.sky_low.r > theme.sky_low.b + 0.3, "%s has an orange sky" % stage.stage_id)
	for stage: StageData in StageProgression.default_region().stages:
		assert_eq(stage.atmosphere.scenery, AtmosphereTheme.Scenery.BAMBOO_OUTSKIRTS, "%s keeps its bamboo" % stage.stage_id)
		assert_eq(stage.atmosphere.ember_share, 0.0, "%s has no embers" % stage.stage_id)


func test_embers_rise_and_glow_layer_flickers() -> void:
	Atmosphere.set_theme(_village().stages[4].atmosphere)
	var leaves: AtmosphereLeaves = AtmosphereLeaves.new()
	leaves.count = 40
	add_to_tree(leaves)
	leaves._process(1.0 / 60.0)
	var embers: Array[int] = []
	for i: int in leaves.count:
		if leaves._is_petal[i] == AtmosphereLeaves.EMBER:
			embers.append(i)
	assert_true(embers.size() >= 10, "most of the drift is embers in the burning keep (%d)" % embers.size())
	for frame: int in 60:
		leaves._process(1.0 / 60.0)
	var rising: int = 0
	for i: int in embers:
		if leaves._velocity[i].y < 0.0:
			rising += 1
	assert_true(rising >= embers.size() * 0.8, "embers rise (%d of %d)" % [rising, embers.size()])
	var backdrop: RegionBackdrop = add_to_tree(load("res://scenes/backdrops/bamboo_outskirts.tscn").instantiate()) as RegionBackdrop
	var fires: BackdropLayer = backdrop.get_node("Fires") as BackdropLayer
	assert_true(fires.additive and fires.depth == (backdrop.get_node("BambooFar") as BackdropLayer).depth, "the glow sits at the houses' depth, additive")
	var alphas: Dictionary = {}
	for frame: int in 20:
		Atmosphere.time += 0.05
		backdrop._process(0.0)
		alphas[snappedf(fires.modulate.a, 0.01)] = true
	assert_true(alphas.size() > 3, "the fire glow flickers")
