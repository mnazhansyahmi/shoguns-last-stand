extends Node2D
## Battlefield: wires player, gate, waves, summoning, HUD and result screen together via signals.
## Loads progression at start (upgrades apply to this battle's stats) and saves rewards at the end.
## Gameplay lives under World (pausable); this root and the overlays keep processing while paused.
## Pause temporarily returns to the main menu (no rewards) until the pause menu exists.

const UPGRADE_CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const DEBUG_HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const DEBUG_ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const PLAYER_RESPAWN_DELAY: float = 5.0

## Overridable so automated runs never touch the player's real save.
@export var save_path: String = SaveManager.DEFAULT_PATH

@onready var _player: Player = $World/Player
@onready var _gate: VillageGate = $World/VillageGate
@onready var _spawner: EnemySpawner = $World/EnemySpawner
@onready var _energy: SpiritEnergy = $World/SpiritEnergy
@onready var _summoner: SummonManager = $World/SummonManager
@onready var _wave_director: WaveDirector = $World/WaveDirector
@onready var _player_spawn_point: Marker2D = $World/PlayerSpawnPoint
@onready var _projectiles: Node2D = $World/Projectiles
@onready var _hud: DebugHud = $DebugHud
@onready var _result_screen: ResultScreen = $ResultScreen

var _is_game_over: bool = false
var _respawn_time_left: float = -1.0
var _save_manager: SaveManager
var _progress: PlayerProgress
var _kills: Array[EnemyData] = []


func _ready() -> void:
	_save_manager = SaveManager.new(save_path)
	_progress = _save_manager.load_progress()
	_apply_upgrades()

	_player.health_changed.connect(_hud.set_player_health)
	_player.died.connect(_on_player_died)
	_player.projectile_fired.connect(_on_projectile_fired)
	_gate.health_changed.connect(_hud.set_gate_health)
	_gate.destroyed.connect(_on_gate_destroyed)
	_energy.energy_changed.connect(_hud.set_energy)
	_summoner.summon_failed.connect(_on_summon_failed)
	_wave_director.wave_started.connect(_on_wave_started)
	_wave_director.wave_cleared.connect(_on_wave_cleared)
	_wave_director.remaining_changed.connect(_hud.set_remaining)
	_wave_director.stage_cleared.connect(_on_stage_cleared)
	_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_result_screen.retry_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.BATTLEFIELD))
	_result_screen.upgrades_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.UPGRADE_MENU))
	_result_screen.main_menu_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))

	var player_health: HealthComponent = _player.get_health()
	_hud.set_player_health(player_health.current_health, player_health.max_health)
	var gate_health: HealthComponent = _gate.get_health()
	_hud.set_gate_health(gate_health.current_health, gate_health.max_health)
	_hud.set_energy(_energy.current, _energy.max_energy)
	_hud.set_remaining(0)
	_hud.set_debug_hint_visible(OS.is_debug_build())
	_hud.hide_status()
	if not _save_manager.last_warning.is_empty():
		_hud.show_message(_save_manager.last_warning, 4.0)

	# Started after the signals above are connected so no wave event is missed.
	_wave_director.start()


func _process(delta: float) -> void:
	_hud.set_cooldowns(_player.get_dash_cooldown_left(), _player.get_heavy_cooldown_left(),
			_player.get_spirit_slash_cooldown_left())
	_hud.set_summon_text(_build_summon_text())
	_update_wave_text()
	_update_respawn(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)
		return
	if _is_game_over:
		return
	if event.is_action_pressed("summon_1"):
		_summoner.request_summon(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("summon_2"):
		_summoner.request_summon(1)
		get_viewport().set_input_as_handled()
	elif OS.is_debug_build():
		_handle_debug_input(event)


## Debug-only spawns. These enemies are not part of any wave.
func _handle_debug_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F1:
			_spawner.spawn(DEBUG_HOLLOW_SOLDIER)
		KEY_F2:
			_spawner.spawn(DEBUG_ONI_BRUTE)
		_:
			return
	get_viewport().set_input_as_handled()


## Replaces this battle's stats with upgraded copies. Base .tres resources stay untouched.
func _apply_upgrades() -> void:
	_player.apply_stats(UpgradeApplier.build_player_stats(_player.stats, _progress, UPGRADE_CATALOG))
	var upgraded_slots: Array[AllyData] = []
	for data: AllyData in _summoner.ally_slots:
		upgraded_slots.append(UpgradeApplier.build_ally_data(data, _progress, UPGRADE_CATALOG) if data != null else null)
	_summoner.ally_slots = upgraded_slots
	_energy.regen_per_second = UpgradeApplier.build_spirit_regen(_energy.regen_per_second, _progress, UPGRADE_CATALOG)


func _build_summon_text() -> String:
	var parts: PackedStringArray = []
	for slot: int in _summoner.get_slot_count():
		var data: AllyData = _summoner.get_slot_data(slot)
		if data == null:
			continue
		var status: String = ""
		var cooldown: float = _summoner.get_cooldown_left(slot)
		if cooldown > 0.0:
			status = " - %s" % DebugHud.format_cooldown(cooldown)
		elif not _energy.can_afford(data.cost):
			status = " - need energy"
		parts.append("[%d] %s (%d)%s" % [slot + 1, data.display_name, roundi(data.cost), status])
	parts.append("Allies %d / %d" % [_summoner.get_ally_count(), _summoner.max_allies])
	return "    ".join(parts)


func _update_wave_text() -> void:
	var total: int = _wave_director.get_total_waves()
	if _wave_director.is_complete():
		_hud.set_wave_text("All waves cleared")
	elif _wave_director.is_in_break():
		_hud.set_wave_text("Wave %d / %d in %ds" % [_wave_director.get_current_wave(), total,
				ceili(_wave_director.get_break_time_left())])
	else:
		_hud.set_wave_text("Wave %d / %d" % [_wave_director.get_current_wave(), total])


func _update_respawn(delta: float) -> void:
	if _respawn_time_left < 0.0 or _is_game_over:
		return
	_respawn_time_left -= delta
	if _respawn_time_left <= 0.0:
		_respawn_time_left = -1.0
		_player.respawn(_player_spawn_point.global_position)
		_hud.hide_status()
	else:
		_hud.show_status("Samurai down - respawn in %d" % ceili(_respawn_time_left))


func _on_player_died() -> void:
	_respawn_time_left = PLAYER_RESPAWN_DELAY


func _on_projectile_fired(projectile: Node2D) -> void:
	_projectiles.add_child(projectile)


func _on_summon_failed(_slot: int, result: SummonManager.Result) -> void:
	_hud.show_message(SummonManager.describe(result))


func _on_wave_started(wave_number: int, total_waves: int) -> void:
	_hud.show_banner("Wave %d" % wave_number if wave_number < total_waves else "Final Wave")


func _on_wave_cleared(wave_number: int) -> void:
	if wave_number < _wave_director.get_total_waves():
		_hud.show_banner("Wave %d cleared" % wave_number)


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.defeated.connect(_on_enemy_defeated)


## Every enemy killed (wave or debug) is worth its reward.
func _on_enemy_defeated(enemy: Enemy) -> void:
	if not _is_game_over and enemy.data != null:
		_kills.append(enemy.data)


func _on_stage_cleared() -> void:
	_end_battle(true)


func _on_gate_destroyed() -> void:
	_end_battle(false)


func _end_battle(victory: bool) -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_respawn_time_left = -1.0
	_wave_director.stop()
	_hud.hide_status()
	var stage: StageData = _wave_director.stage
	var reward: BattleReward = RewardCalculator.calculate(_kills, stage, victory)
	var levels_gained: int = _progress.record_battle(reward, stage.stage_id if stage != null else "")
	var save_error: Error = _save_manager.save_progress(_progress)
	_result_screen.show_result(reward, _progress, levels_gained, save_error)
	get_tree().paused = true
