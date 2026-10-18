extends Node2D
## Battlefield: wires player, gate, spawner and the debug HUD together via signals.
## Gameplay lives under World (pausable); this root and the HUD keep processing while paused.
## Pause temporarily returns to the main menu until the pause menu exists.

const MAIN_MENU_SCENE: String = "res://scenes/main_menu/main_menu.tscn"
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const PLAYER_RESPAWN_DELAY: float = 5.0

@onready var _player: Player = $World/Player
@onready var _gate: VillageGate = $World/VillageGate
@onready var _spawner: EnemySpawner = $World/EnemySpawner
@onready var _player_spawn_point: Marker2D = $World/PlayerSpawnPoint
@onready var _projectiles: Node2D = $World/Projectiles
@onready var _hud: DebugHud = $DebugHud

var _is_defeated: bool = false
var _respawn_time_left: float = -1.0


func _ready() -> void:
	_player.health_changed.connect(_hud.set_player_health)
	_player.died.connect(_on_player_died)
	_player.projectile_fired.connect(_on_projectile_fired)
	_gate.health_changed.connect(_hud.set_gate_health)
	_gate.destroyed.connect(_on_gate_destroyed)

	var player_health: HealthComponent = _player.get_health()
	_hud.set_player_health(player_health.current_health, player_health.max_health)
	var gate_health: HealthComponent = _gate.get_health()
	_hud.set_gate_health(gate_health.current_health, gate_health.max_health)
	_hud.hide_status()


func _process(delta: float) -> void:
	_hud.set_cooldowns(_player.get_dash_cooldown_left(), _player.get_heavy_cooldown_left(),
			_player.get_spirit_slash_cooldown_left())
	_hud.set_enemy_count(get_tree().get_node_count_in_group("enemies"))
	if _respawn_time_left >= 0.0 and not _is_defeated:
		_respawn_time_left -= delta
		if _respawn_time_left <= 0.0:
			_respawn_time_left = -1.0
			_player.respawn(_player_spawn_point.global_position)
			_hud.hide_status()
		else:
			_hud.show_status("Samurai down - respawn in %d" % ceili(_respawn_time_left))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_return_to_menu()
		return
	if _is_defeated:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Temporary debug spawns until the WaveDirector arrives in Phase 3.
	match key.keycode:
		KEY_F1:
			_spawner.spawn(HOLLOW_SOLDIER)
		KEY_F2:
			_spawner.spawn(ONI_BRUTE)
		_:
			return
	get_viewport().set_input_as_handled()


func _on_player_died() -> void:
	_respawn_time_left = PLAYER_RESPAWN_DELAY


func _on_projectile_fired(projectile: Node2D) -> void:
	_projectiles.add_child(projectile)


func _on_gate_destroyed() -> void:
	_is_defeated = true
	_respawn_time_left = -1.0
	_hud.show_status("DEFEAT\nThe village gate has fallen.\nEsc: main menu")
	get_tree().paused = true


func _return_to_menu() -> void:
	get_tree().paused = false
	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_error("Battlefield: failed to load '%s' (error %d)" % [MAIN_MENU_SCENE, error])
