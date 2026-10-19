class_name SceneRoutes
extends RefCounted
## Scene paths and the one place scene changes happen.

const MAIN_MENU: String = "res://scenes/main_menu/main_menu.tscn"
const BATTLEFIELD: String = "res://scenes/battlefield/battlefield.tscn"
const UPGRADE_MENU: String = "res://scenes/upgrade_menu/upgrade_menu.tscn"


## Unpauses (result screens pause the tree) and switches scene, reporting failures.
static func go_to(tree: SceneTree, path: String) -> void:
	tree.paused = false
	# A hit-stop must never carry over into the next scene.
	Engine.time_scale = 1.0
	var error: Error = tree.change_scene_to_file(path)
	if error != OK:
		push_error("SceneRoutes: failed to load '%s' (error %d)." % [path, error])
