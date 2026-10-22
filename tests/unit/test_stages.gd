extends "res://tests/test_case.gd"
## Phase 8: Region 1 stage data, unlock order, saved unlocks, replay rewards, Next Stage, stage select.

const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const STAGE_SELECT_SCENE: PackedScene = preload("res://scenes/stage_select/stage_select.tscn")
const SAVE_PATH: String = "user://test_saves/stages_save.json"
const SETTINGS_PATH: String = "user://test_saves/stages_settings.cfg"


func cleanup() -> void:
	SceneRoutes.battle_stage = null
	tree_root.get_tree().paused = false
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH, SETTINGS_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	super.cleanup()


func _region() -> RegionData:
	return StageProgression.default_region()


func _min_interval(stage: StageData) -> float:
	var smallest: float = INF
	for wave: WaveData in stage.waves:
		for entry: WaveEntry in wave.entries:
			if entry.enemy == HOLLOW_SOLDIER and entry.count > 1:
				smallest = minf(smallest, entry.spawn_interval)
	return smallest


# --- Stage data -------------------------------------------------------------

func test_region_has_five_loadable_stages() -> void:
	var region: RegionData = _region()
	assert_true(region != null, "region loads")
	if region == null:
		return
	assert_eq(region.display_name, "Bamboo Outskirts", "region name")
	assert_eq(region.stages.size(), 5, "five stages")
	var ids: Dictionary = {}
	for stage: StageData in region.stages:
		assert_true(stage != null and not stage.waves.is_empty(), "stage loads with waves")
		if stage == null:
			continue
		assert_true(not ids.has(stage.stage_id), "unique stage id %s" % stage.stage_id)
		ids[stage.stage_id] = true
		for wave: WaveData in stage.waves:
			assert_true(wave != null and not wave.entries.is_empty(), "%s: every wave has entries" % stage.stage_id)
			for entry: WaveEntry in wave.entries:
				assert_true(entry.enemy == HOLLOW_SOLDIER or entry.enemy == ONI_BRUTE or entry.enemy is BossData,
						"%s uses only Hollow Soldiers, Oni Brutes and bosses" % stage.stage_id)
	assert_eq(region.stages[0].stage_id, "stage_1", "stage 1 keeps its id (existing saves stay valid)")


func test_difficulty_rises_each_stage() -> void:
	var stages: Array[StageData] = _region().stages
	for i: int in range(1, stages.size()):
		var before: StageData = stages[i - 1]
		var after: StageData = stages[i]
		assert_true(after.get_enemy_total() > before.get_enemy_total(), "%s has more enemies than %s" % [after.stage_id, before.stage_id])
		assert_true(after.count_enemy(ONI_BRUTE) >= before.count_enemy(ONI_BRUTE), "%s has at least as many Oni" % after.stage_id)
		assert_true(after.waves.size() >= before.waves.size(), "%s has at least as many waves" % after.stage_id)
		assert_true(_min_interval(after) <= _min_interval(before), "%s spawns at least as fast" % after.stage_id)
		assert_true(after.get_full_clear_gold() > before.get_full_clear_gold(), "%s pays more" % after.stage_id)
	var boss_wave: WaveData = stages[4].waves[stages[4].waves.size() - 1]
	var bosses: int = 0
	var minions: int = 0
	for entry: WaveEntry in boss_wave.entries:
		if entry.enemy is BossData:
			bosses += entry.count
		else:
			minions += entry.count
	assert_eq(bosses, 1, "stage 5 ends with one boss, The Fallen Daimyo")
	assert_true(minions >= 3 and minions <= 12, "with a few minions (%d)" % minions)
	for i: int in 4:
		for entry: WaveEntry in stages[4].waves[i].entries:
			assert_true(not (entry.enemy is BossData), "the boss comes only in the final wave")


# --- Unlocks ----------------------------------------------------------------

func test_stages_unlock_in_order() -> void:
	var region: RegionData = _region()
	var progress: PlayerProgress = PlayerProgress.new()
	assert_true(StageProgression.is_unlocked(progress, region, 0), "stage 1 always open")
	for i: int in range(1, 5):
		assert_true(not StageProgression.is_unlocked(progress, region, i), "stage %d locked on a new save" % (i + 1))
	progress.stages_cleared.append("stage_1")
	assert_true(StageProgression.is_unlocked(progress, region, 1), "clearing stage 1 unlocks stage 2")
	assert_true(not StageProgression.is_unlocked(progress, region, 2), "stage 3 still locked")
	progress.stages_cleared.append("stage_2")
	assert_eq(StageProgression.unlocked_count(progress, region), 3, "three unlocked after two clears")
	assert_true(not StageProgression.is_unlocked(progress, region, 5), "out-of-range index is never unlocked")


func test_unlocks_survive_save_and_load() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared.append("stage_1")
	progress.stages_cleared.append("stage_2")
	assert_eq(SaveManager.new(SAVE_PATH).save_progress(progress), OK, "save")
	var loaded: PlayerProgress = SaveManager.new(SAVE_PATH).load_progress()
	assert_true(StageProgression.is_unlocked(loaded, _region(), 2), "stage 3 unlocked after reload")
	assert_true(not StageProgression.is_unlocked(loaded, _region(), 3), "stage 4 still locked after reload")


func test_next_stage_follows_region_order() -> void:
	var region: RegionData = _region()
	assert_true(StageProgression.next_stage(region, region.stages[0]) == region.stages[1], "stage 1 -> stage 2")
	var village: RegionData = StageProgression.regions()[1]
	assert_true(StageProgression.next_stage(region, region.stages[4]) == village.stages[0], "stage 5 -> stage 6, the Burning Village")
	assert_true(StageProgression.next_stage(village, village.stages[4]) == null, "no stage after stage 10")


# --- Rewards ----------------------------------------------------------------

func test_replay_gives_less_gold() -> void:
	var stage: StageData = _region().stages[1]
	var kills: Array[EnemyData] = [HOLLOW_SOLDIER, HOLLOW_SOLDIER, ONI_BRUTE]
	var first: BattleReward = RewardCalculator.calculate(kills, stage, true, false)
	var replay: BattleReward = RewardCalculator.calculate(kills, stage, true, true)
	assert_true(not first.replay and replay.replay, "replay flagged")
	assert_eq(replay.gold, floori(first.kill_gold * stage.replay_gold_multiplier) + floori(first.bonus_gold * stage.replay_gold_multiplier),
			"replay gold = first-clear gold x %.1f" % stage.replay_gold_multiplier)
	assert_true(replay.gold < first.gold, "replay pays less gold")
	assert_eq(replay.xp, first.xp, "XP is not reduced")
	var defeat_replay: BattleReward = RewardCalculator.calculate(kills, stage, false, true)
	assert_true(defeat_replay.gold < RewardCalculator.calculate(kills, stage, false, false).gold, "replay defeats pay less too")


func _battlefield(stage: StageData) -> Node:
	SceneRoutes.battle_stage = stage
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", SAVE_PATH)
	field.set("settings_path", SETTINGS_PATH)
	add_to_tree(field)
	return field


func test_first_clear_offers_next_stage_and_replay_does_not() -> void:
	var stage: StageData = _region().stages[0]
	var field: Node = _battlefield(stage)
	assert_true(field.get_stage() == stage, "battlefield plays the selected stage")
	field.call("_end_battle", true)
	assert_true(not (field.get_node("Hud") as CanvasLayer).visible, "battle controls clear away behind the result overlay")
	var result: ResultScreen = field.get_node("ResultScreen")
	var next_button: Button = result.get_node("%NextButton")
	assert_true(next_button.visible, "Next Stage shown after a first clear")
	assert_true(next_button.text.contains(_region().stages[1].display_name), "button names the next stage")
	var saved: PlayerProgress = SaveManager.new(SAVE_PATH).load_progress()
	assert_true(saved.is_stage_cleared("stage_1"), "first clear saved (unlocks stage 2)")
	assert_eq(saved.gold, stage.clear_gold_bonus, "first clear pays the full bonus")
	field.free()
	tree_root.get_tree().paused = false

	var replay_field: Node = _battlefield(stage)
	replay_field.call("_end_battle", true)
	var replay_result: ResultScreen = replay_field.get_node("ResultScreen")
	assert_true(not (replay_result.get_node("%NextButton") as Button).visible, "no Next Stage button on a replay")
	var after: PlayerProgress = SaveManager.new(SAVE_PATH).load_progress()
	assert_eq(after.gold - saved.gold, floori(stage.clear_gold_bonus * stage.replay_gold_multiplier), "replay bonus reduced")


func test_stage_select_shows_a_card_per_stage_with_locked_ones_unplayable() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared.append("stage_1")
	SaveManager.new(SAVE_PATH).save_progress(progress)
	var select: Node = STAGE_SELECT_SCENE.instantiate()
	select.set("save_path", SAVE_PATH)
	add_to_tree(select)
	for i: int in 5:
		var card: StageCard = select.get_stage_card(i)
		assert_true(card != null, "card %d exists (locked stages still have a card)" % (i + 1))
		if card == null:
			continue
		assert_eq(card.unlocked, i < 2, "stage %d %s" % [i + 1, "playable" if i < 2 else "locked"])
		assert_eq(card.cleared, i == 0, "only stage 1 is cleared")
	assert_eq(select.get_stage_card(2).locked_text, "Clear Bamboo Path", "a locked card says which stage to clear")
	assert_eq(select.get_selected_index(), 1, "the first stage not cleared starts selected")
	assert_true(not (select.get_play_button() as Button).disabled, "and can be played")
	select.get_stage_card(3)._on_focus_entered()
	assert_true((select.get_play_button() as Button).disabled, "a locked stage selected cannot be played")
