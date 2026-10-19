extends Node2D
## Battlefield: wires player, gate, waves, summoning, HUD, touch controls, pause menu and
## result screen together via signals. Loads progression (upgrades apply to this battle) and
## settings at start; saves rewards at the end. Gameplay lives under World (pausable); this
## root and the overlays keep processing while paused.
## Input: summon and pause are read from the Input Map state each frame, so keyboard keys and
## touch buttons (which press the same actions) behave identically.

const UPGRADE_CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const DEBUG_HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const DEBUG_ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const PLAYER_RESPAWN_DELAY: float = 5.0
const SUMMON_ACTIONS: Array[StringName] = [&"summon_1", &"summon_2"]

## Overridable so automated runs never touch the player's real save/settings.
@export var save_path: String = SaveManager.DEFAULT_PATH
@export var settings_path: String = SettingsStore.DEFAULT_PATH

@onready var _player: Player = $World/Player
@onready var _gate: VillageGate = $World/VillageGate
@onready var _spawner: EnemySpawner = $World/EnemySpawner
@onready var _energy: SpiritEnergy = $World/SpiritEnergy
@onready var _summoner: SummonManager = $World/SummonManager
@onready var _wave_director: WaveDirector = $World/WaveDirector
@onready var _feedback: BattleFeedback = $World/BattleFeedback
@onready var _player_spawn_point: Marker2D = $World/PlayerSpawnPoint
@onready var _camera: Camera2D = $Camera2D
@onready var _projectiles: Node2D = $World/Projectiles
@onready var _hud: GameHud = $Hud
@onready var _touch: TouchControls = $TouchControls
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _result_screen: ResultScreen = $ResultScreen

var _is_game_over: bool = false
var _respawn_time_left: float = -1.0
var _save_manager: SaveManager
var _progress: PlayerProgress
var _settings_store: SettingsStore
var _settings: GameSettings
var _kills: Array[EnemyData] = []
var _camera_base_y: float = 0.0


func _ready() -> void:
	_camera_base_y = _camera.position.y
	_save_manager = SaveManager.new(save_path)
	_progress = _save_manager.load_progress()
	_apply_upgrades()
	_settings_store = SettingsStore.new(settings_path)
	_settings = _settings_store.load_settings()

	_player.health_changed.connect(_hud.set_player_health)
	_player.died.connect(_on_player_died)
	_player.projectile_fired.connect(_on_projectile_fired)
	_player.get_health().damaged.connect(_on_player_damaged)
	_gate.health_changed.connect(_hud.set_gate_health)
	_gate.destroyed.connect(_on_gate_destroyed)
	_gate.get_health().damaged.connect(_on_gate_damaged)
	_energy.energy_changed.connect(_hud.set_energy)
	_summoner.summon_failed.connect(_on_summon_failed)
	_wave_director.wave_started.connect(_on_wave_started)
	_wave_director.wave_cleared.connect(_on_wave_cleared)
	_wave_director.remaining_changed.connect(_hud.set_remaining)
	_wave_director.stage_cleared.connect(_on_stage_cleared)
	_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_hud.pause_requested.connect(_on_pause_pressed)
	_pause_menu.resume_requested.connect(_resume)
	_pause_menu.restart_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.BATTLEFIELD))
	_pause_menu.main_menu_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	_pause_menu.settings_changed.connect(_on_settings_changed)
	_pause_menu.settings_closed.connect(_on_settings_closed)
	_result_screen.retry_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.BATTLEFIELD))
	_result_screen.upgrades_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.UPGRADE_MENU))
	_result_screen.main_menu_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	get_viewport().size_changed.connect(_apply_layout)

	var player_health: HealthComponent = _player.get_health()
	_hud.set_player_health(player_health.current_health, player_health.max_health)
	var gate_health: HealthComponent = _gate.get_health()
	_hud.set_gate_health(gate_health.current_health, gate_health.max_health)
	_hud.set_energy(_energy.current, _energy.max_energy)
	_hud.set_remaining(0)
	_hud.set_debug_hint_visible(OS.is_debug_build())
	_hud.hide_status()
	_apply_settings()
	for warning: String in [_save_manager.last_warning, _settings_store.last_warning]:
		if not warning.is_empty():
			_hud.show_message(warning, 4.0)

	# Started after the signals above are connected so no wave event is missed.
	_wave_director.start()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_on_pause_pressed()
	if not get_tree().paused and not _is_game_over:
		for slot: int in SUMMON_ACTIONS.size():
			if Input.is_action_just_pressed(SUMMON_ACTIONS[slot]):
				_summoner.request_summon(slot)
	_update_cooldown_displays()
	_hud.set_summon_text(_build_summon_text())
	_update_wave_text()
	_update_respawn(delta)


## Pause when the app is backgrounded or loses focus (phone call, home gesture, alt-tab),
## so the gate cannot fall while the player is away.
func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT and what != NOTIFICATION_APPLICATION_PAUSED:
		return
	if is_node_ready() and not _is_game_over and not get_tree().paused:
		_pause()


## AUTO touch mode on desktop: show touch controls after the first real finger touch.
func _input(event: InputEvent) -> void:
	if not GameSettings.real_touch_detected and GameSettings.is_real_touch(event):
		GameSettings.real_touch_detected = true
		if _settings.touch_mode == GameSettings.TouchMode.AUTO:
			_apply_settings()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and not _is_game_over and not get_tree().paused:
		_handle_debug_input(event)


# --- Pause and settings -----------------------------------------------------

func _on_pause_pressed() -> void:
	if _is_game_over:
		SceneRoutes.go_to(get_tree(), SceneRoutes.MAIN_MENU)
	elif _pause_menu.is_settings_open():
		_pause_menu.close_settings()
	elif get_tree().paused:
		_resume()
	else:
		_pause()


func _pause() -> void:
	get_tree().paused = true
	_touch.release_all()
	_pause_menu.open(_settings)


func _resume() -> void:
	_pause_menu.close()
	get_tree().paused = false


func _on_settings_changed(settings: GameSettings) -> void:
	_settings = settings
	_apply_settings()


func _on_settings_closed(settings: GameSettings) -> void:
	_settings = settings
	_apply_settings()
	var error: Error = _settings_store.save_settings(settings)
	if error != OK:
		_hud.show_message("Could not save settings (error %d)." % error, 3.0)


func _apply_settings() -> void:
	_settings.apply_audio()
	_feedback.configure(_settings)
	var show_touch: bool = _settings.should_show_touch_controls(GameSettings.detect_touchscreen())
	_touch.set_active(show_touch and not _is_game_over)
	_hud.set_touch_mode(show_touch)
	_apply_layout()


## Re-run on viewport resize and settings changes (safe area, UI scale, handedness).
func _apply_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_rect: Rect2 = TouchLayout.get_safe_rect(get_viewport())
	_touch.apply_layout(viewport_size, safe_rect, _settings.ui_scale, _settings.left_handed)
	_hud.apply_layout(safe_rect, viewport_size, _settings.ui_scale)
	_update_camera_lift(viewport_size, safe_rect)


## With touch controls on screen, move the camera down (the world up) so the ground, the
## gate and every unit stay above the joystick and buttons.
func _update_camera_lift(viewport_size: Vector2, safe_rect: Rect2) -> void:
	var lift: float = 0.0
	if _touch.is_active():
		var rects: Dictionary = TouchLayout.compute(viewport_size, safe_rect, _settings.ui_scale, _settings.left_handed)
		var ground_screen_y: float = _player_spawn_point.global_position.y - _camera_base_y + viewport_size.y * 0.5
		lift = TouchLayout.ground_lift(rects, ground_screen_y)
	_camera.position.y = _camera_base_y + lift


func get_camera_lift() -> float:
	return _camera.position.y - _camera_base_y


# --- Debug ------------------------------------------------------------------

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


# --- HUD updates ------------------------------------------------------------

## Replaces this battle's stats with upgraded copies. Base .tres resources stay untouched.
func _apply_upgrades() -> void:
	_player.apply_stats(UpgradeApplier.build_player_stats(_player.stats, _progress, UPGRADE_CATALOG))
	var upgraded_slots: Array[AllyData] = []
	for data: AllyData in _summoner.ally_slots:
		upgraded_slots.append(UpgradeApplier.build_ally_data(data, _progress, UPGRADE_CATALOG) if data != null else null)
	_summoner.ally_slots = upgraded_slots
	_energy.regen_per_second = UpgradeApplier.build_spirit_regen(_energy.regen_per_second, _progress, UPGRADE_CATALOG)


func _update_cooldown_displays() -> void:
	var cooldowns: Dictionary = _player.get_ability_cooldowns()
	_hud.set_ability_cooldowns(cooldowns)
	for key: String in cooldowns:
		var info: Vector2 = cooldowns[key]
		_touch.set_ability_cooldown(key, info.x / maxf(info.y, 0.001), info.x)
	for slot: int in _summoner.get_slot_count():
		var data: AllyData = _summoner.get_slot_data(slot)
		if data == null:
			continue
		var left: float = _summoner.get_cooldown_left(slot)
		_touch.set_summon_state(slot, data.display_name.get_slice(" ", data.display_name.get_slice_count(" ") - 1),
				roundi(data.cost), left / maxf(data.summon_cooldown, 0.001), left, _energy.can_afford(data.cost))


func _build_summon_text() -> String:
	var parts: PackedStringArray = []
	for slot: int in _summoner.get_slot_count():
		var data: AllyData = _summoner.get_slot_data(slot)
		if data == null:
			continue
		var status: String = ""
		var cooldown: float = _summoner.get_cooldown_left(slot)
		if cooldown > 0.0:
			status = " - %s" % GameHud.format_cooldown(cooldown)
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
	if _respawn_time_left < 0.0 or _is_game_over or get_tree().paused:
		return
	_respawn_time_left -= delta
	if _respawn_time_left <= 0.0:
		_respawn_time_left = -1.0
		_player.respawn(_player_spawn_point.global_position)
		_hud.hide_status()
	else:
		_hud.show_status("Samurai down - respawn in %d" % ceili(_respawn_time_left))


# --- Gameplay events --------------------------------------------------------

func _on_player_died() -> void:
	_respawn_time_left = PLAYER_RESPAWN_DELAY


func _on_player_damaged(_amount: float, _source: Node) -> void:
	_feedback.on_player_hit()


func _on_gate_damaged(_amount: float, _source: Node) -> void:
	_feedback.on_gate_hit()


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
	_touch.set_active(false)
	_pause_menu.close()
	_hud.hide_status()
	var stage: StageData = _wave_director.stage
	var reward: BattleReward = RewardCalculator.calculate(_kills, stage, victory)
	var levels_gained: int = _progress.record_battle(reward, stage.stage_id if stage != null else "")
	var save_error: Error = _save_manager.save_progress(_progress)
	_result_screen.show_result(reward, _progress, levels_gained, save_error)
	get_tree().paused = true
