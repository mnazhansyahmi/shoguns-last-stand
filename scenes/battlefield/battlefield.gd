extends Node2D
## Phase 1 battlefield: static placeholder layout (ground, gate, spawn point).
## Pause temporarily returns to the main menu until the pause menu exists.

const MAIN_MENU_SCENE: String = "res://scenes/main_menu/main_menu.tscn"

@onready var gate_position: Marker2D = $VillageGate
@onready var enemy_spawn_point: Marker2D = $EnemySpawnPoint
@onready var player_spawn_point: Marker2D = $PlayerSpawnPoint


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _return_to_menu() -> void:
	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_error("Battlefield: failed to load '%s' (error %d)" % [MAIN_MENU_SCENE, error])
