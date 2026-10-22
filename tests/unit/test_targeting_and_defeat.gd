extends "res://tests/test_case.gd"
## Spec section 13: enemy target selection and the gate defeat condition.

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/gate/village_gate.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const SAVE_PATH: String = "user://test_saves/defeat_save.json"
const SETTINGS_PATH: String = "user://test_saves/defeat_settings.cfg"


## Minimal target: a Node2D in a target group, optionally untargetable.
class FakeTarget extends Node2D:
	var targetable: bool = true

	func is_targetable() -> bool:
		return targetable


func cleanup() -> void:
	tree_root.get_tree().paused = false
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH, SETTINGS_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	super.cleanup()


func _enemy(data: EnemyData, x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(data)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 0.0)
	return enemy


func _target(group: StringName, x: float, targetable: bool = true) -> FakeTarget:
	var target: FakeTarget = FakeTarget.new()
	target.targetable = targetable
	add_to_tree(target)
	target.add_to_group(group)
	target.global_position = Vector2(x, 0.0)
	return target


# --- Enemy target selection -------------------------------------------------

func test_hollow_soldier_prefers_player_over_ally() -> void:
	var enemy: Enemy = _enemy(HOLLOW_SOLDIER, 1000.0)
	var ally: FakeTarget = _target(&"allies", 950.0)
	var player: FakeTarget = _target(&"player", 820.0)
	assert_true(enemy.select_target() == player, "player chosen first even though the ally is closer")
	player.targetable = false
	assert_true(enemy.select_target() == ally, "falls back to the ally when the player is untargetable")


func test_oni_brute_prefers_allies() -> void:
	var enemy: Enemy = _enemy(ONI_BRUTE, 1000.0)
	var player: FakeTarget = _target(&"player", 960.0)
	var ally: FakeTarget = _target(&"allies", 800.0)
	assert_true(enemy.select_target() == ally, "Oni Brute priority puts allies before the player")
	ally.targetable = false
	assert_true(enemy.select_target() == player, "then the player")


func test_nearest_target_of_the_same_kind() -> void:
	var enemy: Enemy = _enemy(HOLLOW_SOLDIER, 1000.0)
	var far_ally: FakeTarget = _target(&"allies", 800.0)
	var near_ally: FakeTarget = _target(&"allies", 1100.0)
	assert_true(enemy.select_target() == near_ally, "nearest ally chosen")
	near_ally.targetable = false
	assert_true(enemy.select_target() == far_ally, "next nearest when the first is untargetable")


func test_targets_outside_aggro_range_are_ignored() -> void:
	var enemy: Enemy = _enemy(HOLLOW_SOLDIER, 1000.0)
	_target(&"player", 1000.0 - HOLLOW_SOLDIER.aggro_range - 50.0)
	assert_true(enemy.select_target() == null, "nothing in range -> keep advancing")


func test_gate_is_attacked_when_no_defender_blocks() -> void:
	var gate: VillageGate = add_to_tree(GATE_SCENE.instantiate()) as VillageGate
	gate.global_position = Vector2(180.0, 0.0)
	var enemy: Enemy = _enemy(HOLLOW_SOLDIER, gate.get_front_x() + 100.0)
	assert_true(enemy.select_target() == gate, "gate targeted when it is in range and no defender is")
	var player: FakeTarget = _target(&"player", gate.get_front_x() + 150.0)
	assert_true(enemy.select_target() == player, "a defender in range blocks the way to the gate")
	player.targetable = false
	gate.get_health().take_damage(5000.0)
	assert_true(enemy.select_target() == null, "a destroyed gate is no longer a target")


# --- Gate defeat condition --------------------------------------------------

func test_gate_destroyed_exactly_once_at_zero_health() -> void:
	var gate: VillageGate = add_to_tree(GATE_SCENE.instantiate()) as VillageGate
	var destroyed: Array[int] = [0]
	gate.destroyed.connect(func() -> void: destroyed[0] += 1)
	assert_almost_eq(gate.get_health().max_health, 1000.0, "gate has 1000 HP")
	gate.get_health().take_damage(999.0)
	assert_eq(destroyed[0], 0, "not destroyed at 1 HP")
	assert_true(gate.is_targetable(), "still targetable at 1 HP")
	gate.get_health().take_damage(35.0)
	gate.get_health().take_damage(35.0)
	assert_eq(destroyed[0], 1, "destroyed emitted exactly once")
	assert_true(gate.is_destroyed() and not gate.is_targetable(), "destroyed gate is not targetable")


func _make_battlefield() -> Node:
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", SAVE_PATH)
	field.set("settings_path", SETTINGS_PATH)
	add_to_tree(field)
	return field


func test_battlefield_pauses_when_app_loses_focus() -> void:
	var field: Node = _make_battlefield()
	var pause_menu: PauseMenu = field.get_node("PauseMenu")
	field.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(tree_root.get_tree().paused and pause_menu.is_open(), "focus loss opens the pause menu")
	tree_root.get_tree().paused = false
	pause_menu.close()
	field.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(tree_root.get_tree().paused, "iOS/Android backgrounding pauses too")


func test_battlefield_leaves_no_connections_behind() -> void:
	var viewport_signal: Signal = tree_root.get_viewport().size_changed
	var baseline: int = viewport_signal.get_connections().size()
	var field: Node = _make_battlefield()
	assert_true(viewport_signal.get_connections().size() > baseline, "battlefield listens for resizes while alive")
	field.free()
	assert_eq(viewport_signal.get_connections().size(), baseline, "freeing the battlefield removes its connections")


func test_leaving_during_the_last_wave_is_not_a_victory() -> void:
	var stage: StageData = (load("res://data/stages/stage_1.tres") as StageData).duplicate()
	var entry: WaveEntry = WaveEntry.new()
	entry.enemy = HOLLOW_SOLDIER
	entry.count = 2
	var wave: WaveData = WaveData.new()
	wave.entries.append(entry)
	stage.waves = [wave]
	stage.first_wave_delay = 0.0
	SceneRoutes.battle_stage = stage
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", SAVE_PATH)
	field.set("settings_path", SETTINGS_PATH)
	add_to_tree(field)
	SceneRoutes.battle_stage = null
	var director: WaveDirector = field.get_node("World/WaveDirector")
	director.tick(0.0)
	for i: int in 20:
		director.tick(0.5)
	assert_eq(director.get_remaining_count(), 2, "the whole last wave is on the field")
	# Pause menu > Main Menu / Restart: the scene and its enemies are freed as the battle is left.
	field.call(&"_abandon_battle")
	field.free()
	var saved: PlayerProgress = SaveManager.new(SAVE_PATH).load_progress()
	assert_true(not saved.stages_cleared.has("stage_1") and saved.victories == 0, "leaving is not a clear")


func test_gate_destruction_ends_battle_in_defeat() -> void:
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", SAVE_PATH)
	field.set("settings_path", SETTINGS_PATH)
	add_to_tree(field)
	var gate: VillageGate = field.get_node("World/VillageGate")
	var result: ResultScreen = field.get_node("ResultScreen")
	assert_true(not result.visible, "no result screen during battle")
	gate.get_health().take_damage(5000.0)
	assert_true(result.visible, "result screen shown")
	assert_eq((result.get_node("%TitleLabel") as Label).text, "DEFEAT", "defeat, not victory")
	assert_true(tree_root.get_tree().paused, "battle paused after defeat")
	var saved: PlayerProgress = SaveManager.new(SAVE_PATH).load_progress()
	assert_eq(saved.defeats, 1, "defeat recorded in the save")
