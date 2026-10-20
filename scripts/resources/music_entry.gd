class_name MusicEntry
extends Resource
## One music "slot" of the game (menu, stage select, battle, boss) and the file that plays in it.

const MUSIC_DIR: String = "res://assets/audio/music/"
const EXTENSIONS: PackedStringArray = ["ogg", "mp3"]

@export var id: StringName = &""
## Files to try, in order: the first one that exists plays.
@export var paths: PackedStringArray = PackedStringArray()
## If set, a track in the music folder whose name contains this (any case) is used first, when present.
## (The stage select asks for the Tokaido track, which may or may not have been added.)
@export var prefer_keyword: String = ""
## Music is quieter than the sound effects so a hit is never drowned.
@export_range(-40.0, 6.0) var volume_db: float = -10.0


## The file to play, or "" if none of them exist.
func resolve_path() -> String:
	if not prefer_keyword.is_empty():
		var found: String = _find_by_keyword(prefer_keyword.to_lower())
		if not found.is_empty():
			return found
	for path: String in paths:
		if ResourceLoader.exists(path):
			return path
	return ""


## A looping .ogg is preferred over an .mp3, and a "_Loop" file over a plain one.
static func _find_by_keyword(keyword: String) -> String:
	var best: String = ""
	var best_score: int = -1
	for file: String in DirAccess.get_files_at(MUSIC_DIR):
		# Exported games list imported files as "name.ogg.import" or "name.ogg.remap".
		var name: String = file.trim_suffix(".import").trim_suffix(".remap")
		if not name.to_lower().contains(keyword) or not EXTENSIONS.has(name.get_extension().to_lower()):
			continue
		var score: int = (2 if name.get_extension().to_lower() == "ogg" else 0) + (1 if name.to_lower().contains("loop") else 0)
		if score > best_score:
			best_score = score
			best = MUSIC_DIR + name
	return best
