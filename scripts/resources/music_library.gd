class_name MusicLibrary
extends Resource
## The game's music slots by id (data/audio/music_library.tres).

@export var entries: Array[MusicEntry] = []


func find(id: StringName) -> MusicEntry:
	for entry: MusicEntry in entries:
		if entry != null and entry.id == id:
			return entry
	return null
