class_name SfxLibrary
extends Resource
## All sound effects the game can play, by id.

@export var entries: Array[SfxEntry] = []


func find(id: StringName) -> SfxEntry:
	for entry: SfxEntry in entries:
		if entry != null and entry.id == id:
			return entry
	return null
