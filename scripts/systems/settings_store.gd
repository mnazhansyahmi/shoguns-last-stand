class_name SettingsStore
extends RefCounted
## Saves GameSettings to a versioned ConfigFile in user://.
## Saving writes a temp file and renames it into place. Loading never fails: a missing or
## unreadable file gives defaults, and each invalid value falls back to its default.
##
## user://settings.cfg (version 1):
## [meta] version=1
## [settings] music_volume, sfx_volume, ui_scale (float); vibration, screen_shake, blood,
##            left_handed (bool); touch_mode (int: 0 auto, 1 always, 2 off)

const VERSION: int = 1
const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"

var path: String
## Note about the last load when something had to be replaced by defaults ("" otherwise).
var last_warning: String = ""


func _init(settings_path: String = DEFAULT_PATH) -> void:
	path = settings_path


func load_settings() -> GameSettings:
	last_warning = ""
	var settings: GameSettings = GameSettings.new()
	if not FileAccess.file_exists(path):
		return settings
	var config: ConfigFile = ConfigFile.new()
	var error: Error = config.load(path)
	if error != OK:
		return _with_warning(settings, "settings file unreadable (error %d); using defaults" % error)
	var version: Variant = config.get_value("meta", "version", -1)
	if typeof(version) != TYPE_INT or version < 1 or version > VERSION:
		return _with_warning(settings, "unsupported settings version; using defaults")

	var problems: PackedStringArray = []
	settings.music_volume = _read_float(config, "music_volume", settings.music_volume, 0.0, 1.0, problems)
	settings.sfx_volume = _read_float(config, "sfx_volume", settings.sfx_volume, 0.0, 1.0, problems)
	settings.ui_scale = _read_float(config, "ui_scale", settings.ui_scale,
			GameSettings.MIN_UI_SCALE, GameSettings.MAX_UI_SCALE, problems)
	settings.vibration = _read_bool(config, "vibration", settings.vibration, problems)
	settings.screen_shake = _read_bool(config, "screen_shake", settings.screen_shake, problems)
	settings.blood = _read_bool(config, "blood", settings.blood, problems)
	settings.left_handed = _read_bool(config, "left_handed", settings.left_handed, problems)
	var mode: Variant = config.get_value(SECTION, "touch_mode", settings.touch_mode)
	if typeof(mode) == TYPE_INT and mode >= GameSettings.TouchMode.AUTO and mode <= GameSettings.TouchMode.OFF:
		settings.touch_mode = mode
	else:
		problems.append("touch_mode")
	if not problems.is_empty():
		_with_warning(settings, "invalid settings reset to default: %s" % ", ".join(problems))
	return settings


func save_settings(settings: GameSettings) -> Error:
	if settings == null:
		return ERR_INVALID_PARAMETER
	settings.sanitize()
	var config: ConfigFile = ConfigFile.new()
	config.set_value("meta", "version", VERSION)
	config.set_value(SECTION, "music_volume", settings.music_volume)
	config.set_value(SECTION, "sfx_volume", settings.sfx_volume)
	config.set_value(SECTION, "ui_scale", settings.ui_scale)
	config.set_value(SECTION, "vibration", settings.vibration)
	config.set_value(SECTION, "screen_shake", settings.screen_shake)
	config.set_value(SECTION, "blood", settings.blood)
	config.set_value(SECTION, "left_handed", settings.left_handed)
	config.set_value(SECTION, "touch_mode", int(settings.touch_mode))

	var dir_error: Error = DirAccess.make_dir_recursive_absolute(_global(path.get_base_dir()))
	if dir_error != OK:
		push_warning("SettingsStore: cannot create settings directory (error %d)." % dir_error)
		return dir_error
	var temp_path: String = path + ".tmp"
	var error: Error = config.save(temp_path)
	if error != OK:
		push_warning("SettingsStore: cannot write settings (error %d)." % error)
		return error
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_global(path))
	error = DirAccess.rename_absolute(_global(temp_path), _global(path))
	if error != OK:
		push_warning("SettingsStore: cannot move settings into place (error %d)." % error)
	return error


func _read_float(config: ConfigFile, key: String, fallback: float, min_value: float, max_value: float,
		problems: PackedStringArray) -> float:
	var value: Variant = config.get_value(SECTION, key, fallback)
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		problems.append(key)
		return fallback
	var number: float = float(value)
	if is_nan(number) or number < min_value or number > max_value:
		problems.append(key)
		return fallback
	return number


func _read_bool(config: ConfigFile, key: String, fallback: bool, problems: PackedStringArray) -> bool:
	var value: Variant = config.get_value(SECTION, key, fallback)
	if typeof(value) != TYPE_BOOL:
		problems.append(key)
		return fallback
	return value


func _with_warning(settings: GameSettings, message: String) -> GameSettings:
	last_warning = message
	push_warning("SettingsStore: " + message)
	return settings


func _global(file_path: String) -> String:
	return ProjectSettings.globalize_path(file_path)
