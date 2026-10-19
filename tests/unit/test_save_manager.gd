extends "res://tests/test_case.gd"
## Save file round-trip, backup rotation and recovery from corrupted files.
## Uses its own folder under user:// so the real save is never touched.

const TEST_DIR: String = "user://test_saves"
const TEST_PATH: String = "user://test_saves/save_test.json"


func _fresh_manager() -> SaveManager:
	_clear_files()
	return SaveManager.new(TEST_PATH)


func _clear_files() -> void:
	for path: String in [TEST_PATH, TEST_PATH + ".bak", TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_raw(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _sample_progress(gold: int) -> PlayerProgress:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = gold
	progress.xp = 320
	progress.set_upgrade_level("samurai_max_health", 2)
	progress.set_upgrade_level("spirit_regen", 1)
	progress.stages_cleared.append("stage_1")
	progress.battles_played = 4
	progress.victories = 1
	progress.defeats = 3
	progress.enemies_defeated = 40
	return progress


func cleanup() -> void:
	_clear_files()
	super.cleanup()


func test_first_run_starts_new_game() -> void:
	var manager: SaveManager = _fresh_manager()
	var progress: PlayerProgress = manager.load_progress()
	assert_eq(manager.last_load_source, SaveManager.LoadSource.NEW_GAME, "no save -> new game")
	assert_eq(progress.gold, 0, "fresh gold")
	assert_true(manager.last_warning.is_empty(), "no warning on first run")


func test_save_load_round_trip() -> void:
	var manager: SaveManager = _fresh_manager()
	assert_eq(manager.save_progress(_sample_progress(275)), OK, "save succeeds")
	assert_true(not FileAccess.file_exists(TEST_PATH + ".tmp"), "temp file moved into place")
	var loaded: PlayerProgress = SaveManager.new(TEST_PATH).load_progress()
	assert_eq(loaded.gold, 275, "gold")
	assert_eq(loaded.xp, 320, "xp")
	assert_eq(loaded.get_level(), 3, "level derived from xp")
	assert_eq(loaded.get_upgrade_level("samurai_max_health"), 2, "upgrade level")
	assert_eq(loaded.get_upgrade_level("spirit_regen"), 1, "second upgrade level")
	assert_true(loaded.is_stage_cleared("stage_1"), "stage cleared")
	assert_eq(loaded.battles_played, 4, "battles")
	assert_eq(loaded.victories, 1, "victories")
	assert_eq(loaded.defeats, 3, "defeats")
	assert_eq(loaded.enemies_defeated, 40, "enemies defeated")


func test_save_file_is_versioned_json() -> void:
	var manager: SaveManager = _fresh_manager()
	manager.save_progress(_sample_progress(10))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "file is a JSON object")
	if typeof(parsed) == TYPE_DICTIONARY:
		assert_eq(int(parsed["version"]), SaveManager.SAVE_VERSION, "version field")
		assert_eq(int(parsed["data"]["gold"]), 10, "data.gold")
		assert_eq(int(parsed["data"]["level"]), 3, "data.level")


func test_second_save_keeps_previous_as_backup() -> void:
	var manager: SaveManager = _fresh_manager()
	manager.save_progress(_sample_progress(100))
	manager.save_progress(_sample_progress(200))
	assert_eq(manager.read_save_file(TEST_PATH).gold, 200, "main has newest save")
	assert_eq(manager.read_save_file(TEST_PATH + ".bak").gold, 100, "backup has previous save")


func test_corrupted_save_falls_back_to_backup() -> void:
	var manager: SaveManager = _fresh_manager()
	manager.save_progress(_sample_progress(100))
	manager.save_progress(_sample_progress(200))
	_write_raw(TEST_PATH, "{ this is not json")
	var loader: SaveManager = SaveManager.new(TEST_PATH)
	var progress: PlayerProgress = loader.load_progress()
	assert_eq(loader.last_load_source, SaveManager.LoadSource.BACKUP, "loaded from backup")
	assert_eq(progress.gold, 100, "backup contents restored")
	assert_true(not loader.last_warning.is_empty(), "warning reported")


func test_saving_after_corruption_keeps_good_backup() -> void:
	var manager: SaveManager = _fresh_manager()
	manager.save_progress(_sample_progress(100))
	manager.save_progress(_sample_progress(200))
	_write_raw(TEST_PATH, "garbage")
	var loader: SaveManager = SaveManager.new(TEST_PATH)
	var progress: PlayerProgress = loader.load_progress()
	progress.gold += 5
	assert_eq(loader.save_progress(progress), OK, "save after recovery succeeds")
	assert_eq(loader.read_save_file(TEST_PATH).gold, 105, "new main save")
	assert_eq(loader.read_save_file(TEST_PATH + ".bak").gold, 100, "good backup not replaced by the corrupt file")


func test_both_corrupted_starts_fresh() -> void:
	var manager: SaveManager = _fresh_manager()
	manager.save_progress(_sample_progress(100))
	manager.save_progress(_sample_progress(200))
	_write_raw(TEST_PATH, "")
	_write_raw(TEST_PATH + ".bak", "[1, 2, 3]")
	var loader: SaveManager = SaveManager.new(TEST_PATH)
	var progress: PlayerProgress = loader.load_progress()
	assert_eq(loader.last_load_source, SaveManager.LoadSource.RECOVERED_FRESH, "fresh after double corruption")
	assert_eq(progress.gold, 0, "fresh progress")
	assert_true(not loader.last_warning.is_empty(), "warning reported")
	assert_eq(loader.save_progress(progress), OK, "can save again afterwards")


func test_invalid_contents_are_rejected() -> void:
	var manager: SaveManager = _fresh_manager()
	var bad_documents: Array[String] = [
		'{"version": 1}',
		'{"version": 99, "data": {"gold": 1, "xp": 0}}',
		'{"version": 1, "data": {"gold": -5, "xp": 0}}',
		'{"version": 1, "data": {"gold": "lots", "xp": 0}}',
		'{"version": 1, "data": {"gold": 1.5, "xp": 0}}',
		'{"version": 1, "data": {"gold": 1, "xp": 0, "upgrades": {"samurai_damage": -1}}}',
		'{"version": 1, "data": {"gold": 1, "xp": 0, "stages_cleared": "stage_1"}}',
	]
	for text: String in bad_documents:
		_write_raw(TEST_PATH, text)
		assert_true(manager.read_save_file(TEST_PATH) == null, "rejected: %s" % text)


func test_reset_progress_clears_everything() -> void:
	var manager: SaveManager = _fresh_manager()
	manager.save_progress(_sample_progress(100))
	manager.save_progress(_sample_progress(200))
	assert_eq(manager.reset_progress(), OK, "reset succeeds")
	assert_true(not FileAccess.file_exists(TEST_PATH + ".bak"), "backup removed")
	var progress: PlayerProgress = SaveManager.new(TEST_PATH).load_progress()
	assert_eq(progress.gold, 0, "gold reset")
	assert_eq(progress.get_upgrade_level("samurai_max_health"), 0, "upgrades reset")
