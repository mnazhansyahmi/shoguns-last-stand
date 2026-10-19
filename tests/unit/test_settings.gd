extends "res://tests/test_case.gd"
## GameSettings + SettingsStore: round-trip, validation, touch-mode rules, audio buses.

const TEST_PATH: String = "user://test_saves/settings_test.cfg"


func _clear() -> void:
	for path: String in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_raw(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_PATH.get_base_dir()))
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func cleanup() -> void:
	_clear()
	super.cleanup()


func test_defaults() -> void:
	var settings: GameSettings = GameSettings.new()
	assert_almost_eq(settings.ui_scale, 1.0, "default UI scale")
	assert_true(not settings.left_handed, "right-handed by default")
	assert_eq(settings.touch_mode, GameSettings.TouchMode.AUTO, "touch controls auto by default")


func test_missing_file_gives_defaults() -> void:
	_clear()
	var store: SettingsStore = SettingsStore.new(TEST_PATH)
	var settings: GameSettings = store.load_settings()
	assert_almost_eq(settings.music_volume, 0.8, "default music volume")
	assert_true(store.last_warning.is_empty(), "no warning without a file")


func test_settings_round_trip() -> void:
	_clear()
	var settings: GameSettings = GameSettings.new()
	settings.music_volume = 0.25
	settings.sfx_volume = 0.6
	settings.vibration = false
	settings.screen_shake = false
	settings.ui_scale = 1.25
	settings.left_handed = true
	settings.touch_mode = GameSettings.TouchMode.ALWAYS
	var store: SettingsStore = SettingsStore.new(TEST_PATH)
	assert_eq(store.save_settings(settings), OK, "save succeeds")
	assert_true(not FileAccess.file_exists(TEST_PATH + ".tmp"), "temp file moved into place")
	var loaded: GameSettings = SettingsStore.new(TEST_PATH).load_settings()
	assert_almost_eq(loaded.music_volume, 0.25, "music volume")
	assert_almost_eq(loaded.sfx_volume, 0.6, "sfx volume")
	assert_true(not loaded.vibration, "vibration")
	assert_true(not loaded.screen_shake, "screen shake")
	assert_almost_eq(loaded.ui_scale, 1.25, "ui scale")
	assert_true(loaded.left_handed, "left-handed")
	assert_eq(loaded.touch_mode, GameSettings.TouchMode.ALWAYS, "touch mode")


func test_invalid_values_fall_back_per_key() -> void:
	_write_raw('[meta]\nversion=1\n[settings]\nmusic_volume=7.5\nsfx_volume=0.3\nvibration="yes"\nui_scale=0.1\nleft_handed=true\ntouch_mode=9\n')
	var store: SettingsStore = SettingsStore.new(TEST_PATH)
	var loaded: GameSettings = store.load_settings()
	assert_almost_eq(loaded.music_volume, 0.8, "out-of-range music volume -> default")
	assert_almost_eq(loaded.sfx_volume, 0.3, "valid sfx volume kept")
	assert_true(loaded.vibration, "wrong-type vibration -> default")
	assert_almost_eq(loaded.ui_scale, 1.0, "out-of-range UI scale -> default")
	assert_true(loaded.left_handed, "valid left-handed kept")
	assert_eq(loaded.touch_mode, GameSettings.TouchMode.AUTO, "bad touch mode -> default")
	assert_true(not store.last_warning.is_empty(), "warning reported")


func test_unsupported_version_gives_defaults() -> void:
	_write_raw('[meta]\nversion=99\n[settings]\nleft_handed=true\n')
	var store: SettingsStore = SettingsStore.new(TEST_PATH)
	var loaded: GameSettings = store.load_settings()
	assert_true(not loaded.left_handed, "future version ignored")
	assert_true(not store.last_warning.is_empty(), "warning reported")


func test_sanitize_clamps() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.music_volume = -1.0
	settings.ui_scale = 5.0
	settings.sanitize()
	assert_almost_eq(settings.music_volume, 0.0, "volume clamped")
	assert_almost_eq(settings.ui_scale, GameSettings.MAX_UI_SCALE, "UI scale clamped")


func test_touch_mode_rules() -> void:
	var settings: GameSettings = GameSettings.new()
	assert_true(settings.should_show_touch_controls(true), "auto: shown on touchscreens")
	assert_true(not settings.should_show_touch_controls(false), "auto: hidden without touchscreen")
	settings.touch_mode = GameSettings.TouchMode.ALWAYS
	assert_true(settings.should_show_touch_controls(false), "always: shown for mouse testing")
	settings.touch_mode = GameSettings.TouchMode.OFF
	assert_true(not settings.should_show_touch_controls(true), "off: hidden even on touchscreens")


func test_audio_settings_drive_buses() -> void:
	var music: int = AudioServer.get_bus_index(&"Music")
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	assert_true(music >= 0 and sfx >= 0, "Music and SFX buses exist")
	if music < 0 or sfx < 0:
		return
	var settings: GameSettings = GameSettings.new()
	settings.music_volume = 0.5
	settings.sfx_volume = 0.0
	settings.apply_audio()
	assert_almost_eq(AudioServer.get_bus_volume_db(music), linear_to_db(0.5), "music bus volume", 0.01)
	assert_true(AudioServer.is_bus_mute(sfx), "zero SFX volume mutes the bus")
	GameSettings.new().apply_audio()
