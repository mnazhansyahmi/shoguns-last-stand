class_name SaveManager
extends RefCounted
## Versioned JSON save in user://.
## Saving: write <path>.tmp, verify it, move the previous valid save to <path>.bak, then move
## the temp file into place. Loading: validate the main save; fall back to the backup; if both
## are invalid, start fresh. Corruption is reported with push_warning, never a crash.
##
## File format (version 1):
## { "version": 1, "saved_at_unix": int, "data": {
##     "gold": int, "xp": int, "level": int, "upgrades": { id: int },
##     "stages_cleared": [String], "last_stage": String (optional), "stats": { "battles", "victories", "defeats", "enemies_defeated": int } } }

enum LoadSource { NEW_GAME, MAIN, BACKUP, RECOVERED_FRESH }

const SAVE_VERSION: int = 1
const DEFAULT_PATH: String = "user://savegame.json"
const MAX_SANE_VALUE: float = 1.0e9
const MAX_UPGRADE_LEVEL: int = 100

var save_path: String
var backup_path: String
var temp_path: String
## Where the last load_progress() result came from.
var last_load_source: LoadSource = LoadSource.NEW_GAME
## Human-readable note when the last load had to recover from a bad save ("" otherwise).
var last_warning: String = ""

var _last_reason: String = ""


func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path
	backup_path = path + ".bak"
	temp_path = path + ".tmp"


func has_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)


func load_progress() -> PlayerProgress:
	last_warning = ""
	if not has_save():
		last_load_source = LoadSource.NEW_GAME
		return PlayerProgress.new()

	var main: PlayerProgress = read_save_file(save_path)
	if main != null:
		last_load_source = LoadSource.MAIN
		return main
	var main_reason: String = _last_reason

	var backup: PlayerProgress = read_save_file(backup_path)
	if backup != null:
		last_load_source = LoadSource.BACKUP
		last_warning = "Save file was damaged (%s). Restored from backup." % main_reason
		push_warning("SaveManager: " + last_warning)
		return backup

	last_load_source = LoadSource.RECOVERED_FRESH
	last_warning = "Save file and backup were damaged (%s / %s). Starting fresh." % [main_reason, _last_reason]
	push_warning("SaveManager: " + last_warning)
	return PlayerProgress.new()


func save_progress(progress: PlayerProgress) -> Error:
	if progress == null:
		return ERR_INVALID_PARAMETER
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(_global(save_path.get_base_dir()))
	if dir_error != OK:
		push_warning("SaveManager: cannot create save directory (error %d)." % dir_error)
		return dir_error

	var document: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"data": progress.to_dict(),
	}
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_warning("SaveManager: cannot write temp save (error %d)." % open_error)
		return open_error
	file.store_string(JSON.stringify(document, "\t"))
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		push_warning("SaveManager: writing temp save failed (error %d)." % write_error)
		return write_error
	if read_save_file(temp_path) == null:
		push_warning("SaveManager: temp save failed verification (%s)." % _last_reason)
		return ERR_FILE_CORRUPT

	# Keep the previous save as the backup, but never replace a good backup with a bad main file.
	if FileAccess.file_exists(save_path):
		if read_save_file(save_path) != null:
			_remove_if_exists(backup_path)
			var backup_error: Error = DirAccess.rename_absolute(_global(save_path), _global(backup_path))
			if backup_error != OK:
				push_warning("SaveManager: could not rotate backup (error %d)." % backup_error)
				return backup_error
		else:
			_remove_if_exists(save_path)

	var move_error: Error = DirAccess.rename_absolute(_global(temp_path), _global(save_path))
	if move_error != OK:
		push_warning("SaveManager: could not move temp save into place (error %d)." % move_error)
	return move_error


## Deletes the save, backup and temp files, then writes a fresh save.
func reset_progress() -> Error:
	_remove_if_exists(save_path)
	_remove_if_exists(backup_path)
	_remove_if_exists(temp_path)
	return save_progress(PlayerProgress.new())


## Reads and validates one save file. Returns null (reason in _last_reason) if invalid.
func read_save_file(path: String) -> PlayerProgress:
	_last_reason = ""
	if not FileAccess.file_exists(path):
		_last_reason = "missing"
		return null
	var text: String = FileAccess.get_file_as_string(path)
	if text.strip_edges().is_empty():
		_last_reason = "empty file"
		return null
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		_last_reason = "invalid JSON at line %d" % json.get_error_line()
		return null
	return _progress_from_document(json.data)


# --- Validation -------------------------------------------------------------

func _progress_from_document(document: Variant) -> PlayerProgress:
	if typeof(document) != TYPE_DICTIONARY:
		return _invalid("root is not an object")
	var version: int = _to_int(document.get("version"))
	if version < 1:
		return _invalid("missing or bad version")
	if version > SAVE_VERSION:
		return _invalid("save version %d is newer than supported %d" % [version, SAVE_VERSION])
	var data: Variant = _migrate(document.get("data"), version)
	if typeof(data) != TYPE_DICTIONARY:
		return _invalid("missing data object")

	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = _to_int(data.get("gold"))
	progress.xp = _to_int(data.get("xp"))
	if progress.gold < 0 or progress.xp < 0:
		return _invalid("gold/xp missing or negative")

	var upgrades: Variant = data.get("upgrades", {})
	if typeof(upgrades) != TYPE_DICTIONARY:
		return _invalid("upgrades is not an object")
	for key: Variant in upgrades:
		var level: int = _to_int(upgrades[key])
		if typeof(key) != TYPE_STRING or level < 0 or level > MAX_UPGRADE_LEVEL:
			return _invalid("bad upgrade entry '%s'" % str(key))
		progress.set_upgrade_level(key, level)

	var stages: Variant = data.get("stages_cleared", [])
	if typeof(stages) != TYPE_ARRAY:
		return _invalid("stages_cleared is not a list")
	for stage_id: Variant in stages:
		if typeof(stage_id) != TYPE_STRING:
			return _invalid("bad stage id")
		if not progress.stages_cleared.has(stage_id):
			progress.stages_cleared.append(stage_id)

	var last_stage: Variant = data.get("last_stage", "")
	if typeof(last_stage) == TYPE_STRING:
		progress.last_stage_id = last_stage

	var stats: Variant = data.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return _invalid("stats is not an object")
	progress.battles_played = maxi(_to_int(stats.get("battles", 0)), 0)
	progress.victories = maxi(_to_int(stats.get("victories", 0)), 0)
	progress.defeats = maxi(_to_int(stats.get("defeats", 0)), 0)
	progress.enemies_defeated = maxi(_to_int(stats.get("enemies_defeated", 0)), 0)
	return progress


## Upgrades older save layouts to the current one. Version 1 is current: nothing to do.
func _migrate(data: Variant, _from_version: int) -> Variant:
	return data


## JSON numbers arrive as floats. Returns -1 for anything that is not a whole, sane number.
func _to_int(value: Variant) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return -1
	var number: float = float(value)
	if is_nan(number) or is_inf(number) or number < 0.0 or number > MAX_SANE_VALUE or number != floorf(number):
		return -1
	return int(number)


func _invalid(reason: String) -> PlayerProgress:
	_last_reason = reason
	return null


func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_global(path))


func _global(path: String) -> String:
	return ProjectSettings.globalize_path(path)
