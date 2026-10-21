extends Node2D
## Battlefield: wires player, gate, waves, summoning, HUD, touch controls, pause menu and
## result screen together via signals. Loads progression (upgrades apply to this battle) and
## settings at start; saves rewards at the end. Gameplay lives under World (pausable); this
## root and the overlays keep processing while paused.
## Input: summon and pause are read from the Input Map state each frame, so keyboard keys and
## touch buttons (which press the same actions) behave identically.

const UPGRADE_CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
## Every ally; the ones whose stage has been cleared fill the summon slots in this order.
const ALLY_ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const DEBUG_HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const DEBUG_ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const PLAYER_RESPAWN_DELAY: float = 5.0
const SUMMON_ACTIONS: Array[StringName] = [&"summon_1", &"summon_2", &"summon_3", &"summon_4", &"summon_5", &"summon_6"]
## The gate indicator pulses this long after the gate is hit while it is off screen.
const GATE_ALERT_MSEC: int = 3000

## Overridable so automated runs never touch the player's real save/settings.
@export var save_path: String = SaveManager.DEFAULT_PATH
@export var settings_path: String = SettingsStore.DEFAULT_PATH

@onready var _player: Player = $World/Player
@onready var _gate: VillageGate = $World/VillageGate
@onready var _spawner: EnemySpawner = $World/EnemySpawner
@onready var _energy: SpiritEnergy = $World/SpiritEnergy
@onready var _summoner: SummonManager = $World/SummonManager
@onready var _wave_director: WaveDirector = $World/WaveDirector
@onready var _ultimate_meter: UltimateMeter = $World/UltimateMeter
@onready var _ultimate: UltimateSkill = $World/UltimateSkill
@onready var _feedback: BattleFeedback = $World/BattleFeedback
@onready var _player_spawn_point: Marker2D = $World/PlayerSpawnPoint
@onready var _camera: BattleCamera = $Camera2D
@onready var _projectiles: Node2D = $World/Projectiles
@onready var _backdrop: RegionBackdrop = $World/Backdrop
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
var _gate_alert_until_msec: int = 0
var _last_gate_health: float = -1.0
## The stage was already cleared before this battle (replay rewards, no Next Stage button).
var _was_cleared_before: bool = false
var _selected_summon_slot: int = 0
var _summon_names: Array[String] = []
var _summon_accents: Array[Color] = []


func _ready() -> void:
	_save_manager = SaveManager.new(save_path)
	_progress = _save_manager.load_progress()
	_apply_upgrades()
	_touch.set_summon_count(_summoner.get_slot_count())
	_hud.configure_summons(_summoner.ally_slots)
	for data: AllyData in _summoner.ally_slots:
		_summon_names.append(short_name(data))
		_summon_accents.append(FigureKinds.spec(data.figure).accent)
	_settings_store = SettingsStore.new(settings_path)
	_settings = _settings_store.load_settings()
	if SceneRoutes.battle_stage != null:
		_wave_director.stage = SceneRoutes.battle_stage
	if _wave_director.stage != null:
		# The stage's own sky, light and falling leaves.
		_backdrop.apply_theme(_wave_director.stage.atmosphere)
		_was_cleared_before = _progress.is_stage_cleared(_wave_director.stage.stage_id)

	_player.health_changed.connect(_hud.set_player_health)
	_player.died.connect(_on_player_died)
	_player.projectile_fired.connect(_on_projectile_fired)
	_player.war_cry_released.connect(_on_war_cry_released)
	_player.skill_locked.connect(_on_skill_locked)
	_player.bow_unlocked = _progress.is_stage_cleared(Player.BOW_UNLOCK_STAGE)
	_player.war_cry_unlocked = _progress.is_stage_cleared(Player.WAR_CRY_UNLOCK_STAGE)
	_hud.set_skills_unlocked(_player.bow_unlocked, _player.war_cry_unlocked)
	_touch.set_skills_unlocked(_player.bow_unlocked, _player.war_cry_unlocked)
	_gate.health_changed.connect(_hud.set_gate_health)
	_gate.health_changed.connect(_on_gate_health_changed)
	_gate.destroyed.connect(_on_gate_destroyed)
	_energy.energy_changed.connect(_hud.set_energy)
	_ultimate_meter.configure(_player.stats)
	_ultimate.setup(_player, _camera, _ultimate_meter)
	_ultimate_meter.became_ready.connect(_on_ultimate_ready)
	_ultimate.not_ready.connect(_on_ultimate_not_ready)
	_feedback.hit_reported.connect(_on_hit_reported)
	_summoner.summon_failed.connect(_on_summon_failed)
	_summoner.ally_summoned.connect(_on_ally_summoned)
	_wave_director.wave_started.connect(_on_wave_started)
	_wave_director.wave_cleared.connect(_on_wave_cleared)
	_wave_director.remaining_changed.connect(_hud.set_remaining)
	_wave_director.stage_cleared.connect(_on_stage_cleared)
	_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_hud.pause_requested.connect(_on_pause_pressed)
	_pause_menu.set_save_path(save_path)
	_pause_menu.progress_reset.connect(_on_progress_reset)
	_pause_menu.resume_requested.connect(_resume)
	_pause_menu.restart_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.BATTLEFIELD))
	_pause_menu.main_menu_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	_pause_menu.settings_changed.connect(_on_settings_changed)
	_pause_menu.settings_closed.connect(_on_settings_closed)
	_result_screen.retry_requested.connect(_on_retry_requested)
	_result_screen.next_stage_requested.connect(_on_next_stage_requested)
	_result_screen.upgrades_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.UPGRADE_MENU))
	_result_screen.main_menu_requested.connect(SceneRoutes.go_to.bind(get_tree(), SceneRoutes.MAIN_MENU))
	get_viewport().size_changed.connect(_apply_layout)

	var player_health: HealthComponent = _player.get_health()
	_hud.set_player_health(player_health.current_health, player_health.max_health)
	var gate_health: HealthComponent = _gate.get_health()
	_hud.set_gate_health(gate_health.current_health, gate_health.max_health)
	_hud.set_energy(_energy.current, _energy.max_energy)
	_hud.set_remaining(0)
	_hud.set_tutorial_hint(_wave_director.stage.stage_id if _wave_director.stage != null else "", _was_cleared_before)
	_hud.hide_status()
	_apply_settings()
	for warning: String in [_save_manager.last_warning, _settings_store.last_warning]:
		if not warning.is_empty():
			_hud.show_message(warning, 4.0)

	_camera.target = _player
	_camera.snap()
	AudioManager.play_music(&"battle")

	# Started after the signals above are connected so no wave event is missed.
	_wave_director.start()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_on_pause_pressed()
	if not get_tree().paused and not _is_game_over:
		_read_gamepad_summons()
		for slot: int in SUMMON_ACTIONS.size():
			if Input.is_action_just_pressed(SUMMON_ACTIONS[slot]):
				_summoner.request_summon(slot)
		if Input.is_action_just_pressed("ultimate"):
			_ultimate.request()
		if Input.is_action_just_pressed("stance"):
			_summoner.toggle_stance()
			_hud.show_message("Allies: %s" % SummonManager.stance_name(_summoner.get_stance()), 1.2)
	_update_cooldown_displays()
	_update_stance_display()
	_update_respawn(delta)
	# Text and indicators that change a few times a second are refreshed a few times a second, on different frames so
	# no single frame carries them all; the bars above animate smoothly, so they stay per frame.
	var tick: int = Engine.get_process_frames()
	match tick % 6:
		0, 3:
			_update_edge_indicators()
		1:
			_update_leaf_keep_out()
		2:
			_hud.set_summon_text("Allies %d/%d" % [_summoner.get_ally_count(), _summoner.max_allies])
			_update_wave_text()


## Falling leaves never fly over the HUD or the touch controls.
func _update_leaf_keep_out() -> void:
	var rects: Array[Rect2] = _hud.get_keep_out_rects()
	rects.append_array(_touch.get_keep_out_rects())
	_backdrop.set_keep_out(rects)


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
	_hud.release_summons()
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
	_camera.update_base()
	_update_camera_lift(viewport_size, safe_rect)


## With touch controls on screen, move the camera down (the world up) so the ground, the
## gate and every unit stay above the joystick and buttons. The lift is in screen pixels.
func _update_camera_lift(viewport_size: Vector2, safe_rect: Rect2) -> void:
	var lift: float = 0.0
	if _touch.is_active():
		var rects: Dictionary = TouchLayout.compute(viewport_size, safe_rect, _settings.ui_scale, _settings.left_handed)
		lift = TouchLayout.ground_lift(rects, _camera.get_ground_screen_y())
	_camera.set_lift(lift)


## Camera lift in world units (0 without touch controls).
func get_camera_lift() -> float:
	return _camera.get_lift()


func get_camera() -> BattleCamera:
	return _camera


## The view only shows part of the field: point at the gate and at enemies that are off screen.
func _update_edge_indicators() -> void:
	var view: Rect2 = _camera.get_view_rect()
	var at_gate: int = 0
	var incoming: int = 0
	var oni_incoming: bool = false
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null:
			continue
		var x: float = enemy.global_position.x
		if x < view.position.x:
			at_gate += 1
		elif x > view.end.x:
			incoming += 1
			oni_incoming = oni_incoming or (enemy.data != null and enemy.data.figure == InkFigure.Kind.ONI_BRUTE)
	var gate_health: HealthComponent = _gate.get_health()
	var gate_hidden: bool = _gate.get_front_x() < view.position.x + 30.0
	var alert: bool = Time.get_ticks_msec() < _gate_alert_until_msec or at_gate > 0
	_hud.set_edge_indicators(gate_hidden, gate_health.current_health / maxf(gate_health.max_health, 0.001),
			at_gate, alert, incoming, oni_incoming)


func _on_gate_health_changed(current: float, _maximum: float) -> void:
	if _last_gate_health >= 0.0 and current < _last_gate_health:
		_gate_alert_until_msec = Time.get_ticks_msec() + GATE_ALERT_MSEC
	_last_gate_health = current


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
		KEY_F3:
			_ultimate_meter.add_charge(_ultimate_meter.max_charge)
		_:
			return
	get_viewport().set_input_as_handled()


# --- HUD updates ------------------------------------------------------------

## Replaces this battle's stats with upgraded copies. Base .tres resources stay untouched.
func _apply_upgrades() -> void:
	_player.apply_stats(UpgradeApplier.build_player_stats(_player.stats, _progress, UPGRADE_CATALOG))
	var upgraded_slots: Array[AllyData] = []
	for data: AllyData in ALLY_ROSTER.get_unlocked(_progress):
		upgraded_slots.append(UpgradeApplier.build_ally_data(data, _progress, UPGRADE_CATALOG))
	_summoner.ally_slots = upgraded_slots
	_summoner.max_allies = UpgradeApplier.build_ally_cap(_progress, UPGRADE_CATALOG)
	_energy.regen_per_second = UpgradeApplier.build_spirit_regen(_energy.regen_per_second, _progress, UPGRADE_CATALOG)
	_energy.max_energy = UpgradeApplier.build_spirit_max(_energy.max_energy, _progress, UPGRADE_CATALOG)
	_hud.set_energy(_energy.current, _energy.max_energy)


func _update_stance_display() -> void:
	var stance: Ally.Stance = _summoner.get_stance()
	_hud.set_stance(SummonManager.stance_name(stance))
	if _touch.is_active():
		_touch.set_stance_state(SummonManager.stance_name(stance), stance == Ally.Stance.CHARGE)


func _update_cooldown_displays() -> void:
	_hud.set_ultimate(_ultimate_meter.get_ratio(), _ultimate_meter.is_ready())
	var cooldowns: Dictionary = _player.get_ability_cooldowns()
	_hud.set_ability_cooldowns(cooldowns)
	if _touch.is_active():
		_touch.set_ultimate_charge(_ultimate_meter.get_ratio(), _ultimate_meter.is_ready())
		for key: String in cooldowns:
			var info: Vector2 = cooldowns[key]
			_touch.set_ability_cooldown(key, info.x / maxf(info.y, 0.001), info.x)
	for slot: int in _summoner.get_slot_count():
		var data: AllyData = _summoner.get_slot_data(slot)
		if data == null:
			continue
		var left: float = _summoner.get_cooldown_left(slot)
		if _touch.is_active():
			_touch.set_summon_state(slot, _summon_names[slot], roundi(data.cost), left / maxf(data.summon_cooldown, 0.001), left,
				_energy.can_afford(data.cost), _summon_accents[slot], data.figure)
		else:
			_hud.set_summon_state(slot, roundi(data.cost), left, data.summon_cooldown, _energy.can_afford(data.cost))


## "Shrine Healer" -> "Healer": the last word, short enough for a button.
static func short_name(data: AllyData) -> String:
	return data.display_name.get_slice(" ", data.display_name.get_slice_count(" ") - 1)


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


func get_stage() -> StageData:
	return _wave_director.stage


func _on_retry_requested() -> void:
	SceneRoutes.go_to_battle(get_tree(), _wave_director.stage)


func _on_next_stage_requested() -> void:
	var next: StageData = StageProgression.next_stage(StageProgression.region_of(_wave_director.stage), _wave_director.stage)
	if next != null:
		SceneRoutes.go_to_battle(get_tree(), next)


## Fighting charges the Ultimate: damage the samurai deals (allies count less) and damage he takes.
func _on_hit_reported(victim: Node, hit: HitData) -> void:
	if victim is Enemy:
		if is_instance_valid(hit.source) and hit.source is Player:
			_ultimate_meter.add_damage_dealt(hit.damage)
		elif is_instance_valid(hit.source) and hit.source is Ally:
			_ultimate_meter.add_damage_dealt(hit.damage, true)
	elif victim is Player:
		_ultimate_meter.add_damage_taken(hit.damage)


func _on_ultimate_ready() -> void:
	AudioManager.play(&"ultimate_ready")
	_hud.show_message("Ultimate ready!", 1.8)


func _on_ultimate_not_ready(ratio: float) -> void:
	_hud.show_message("Ultimate charging - %d%%" % floori(ratio * 100.0))


func _on_ally_summoned(_ally: Ally, _slot: int) -> void:
	AudioManager.play(&"summon")


## The War Cry: every ally near the samurai deals more damage and attacks faster for a while.
func _on_war_cry_released(origin: Vector2) -> void:
	var stats: PlayerStats = _player.stats
	var rallied: int = 0
	for node: Node in get_tree().get_nodes_in_group("allies"):
		var ally: Ally = node as Ally
		if ally != null and not ally.is_dead() and absf(ally.global_position.x - origin.x) <= stats.war_cry_radius:
			# Each ally flashes gold as the ring passes over it.
			var flash_delay: float = WarCryRing.time_to_reach(absf(ally.global_position.x - origin.x), stats.war_cry_radius)
			ally.apply_war_cry(stats.war_cry_duration, stats.war_cry_damage_bonus, stats.war_cry_speed_bonus, flash_delay)
			rallied += 1
	var ring: WarCryRing = WarCryRing.new()
	ring.setup(stats.war_cry_radius, _player.get_shout_point() - origin, _player.facing)
	_projectiles.add_child(ring)
	ring.global_position = origin
	_hud.show_message("War Cry! %d allies rallied" % rallied if rallied > 0 else "War Cry! (no allies nearby)", 1.6)


func _on_skill_locked(skill: StringName) -> void:
	if skill == &"bow":
		_hud.show_message("The Bow unlocks when you clear Stage 1", 2.0)
	else:
		_hud.show_message("War Cry unlocks when you clear Stage 2", 2.0)


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
	if CombatSounds.is_big(enemy.data):
		AudioManager.play(&"roar", CombatSounds.roar_pitch(enemy.data))
	var boss: Boss = enemy as Boss
	if boss != null:
		_hud.show_boss(boss.data.display_name)
		boss.boss_health_changed.connect(_hud.set_boss_health)
		_hud.set_boss_health(boss.get_health().current_health, boss.get_health().max_health)
		boss.phase_changed.connect(_on_boss_phase_changed)
		boss.minions_requested.connect(_on_boss_minions_requested.bind(boss))
		boss.defeated.connect(_on_boss_defeated)
		# The most intense track, crossfaded in as he arrives.
		AudioManager.play_music(&"boss")


func _on_boss_phase_changed(_phase: int, banner: String) -> void:
	if not banner.is_empty():
		_hud.show_banner(banner)


## The boss calls minions: they rise at the given x positions and fall with him.
func _on_boss_minions_requested(enemy_data: EnemyData, positions: PackedFloat32Array, boss: Boss) -> void:
	for x: float in positions:
		var minion: Enemy = _spawner.spawn(enemy_data)
		if minion != null:
			minion.global_position = Vector2(x, boss.global_position.y)
			boss.register_minion(minion)


func _on_boss_defeated(_enemy: Enemy) -> void:
	_hud.hide_boss()


## Every enemy killed (wave or debug) is worth its reward.
func _on_enemy_defeated(enemy: Enemy) -> void:
	AudioManager.play(&"enemy_death", CombatSounds.death_pitch(enemy.data))
	if not _is_game_over and enemy.data != null:
		_kills.append(enemy.data)


func _on_stage_cleared() -> void:
	_hud.set_tutorial_hint("", true)
	_end_battle(true)


func _on_gate_destroyed() -> void:
	AudioManager.play(&"gate_destroyed")
	_end_battle(false)


func _end_battle(victory: bool) -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_respawn_time_left = -1.0
	_wave_director.stop()
	_feedback.end_hit_stop()
	AudioManager.play(&"victory" if victory else &"defeat")
	_touch.set_active(false)
	_hud.release_summons()
	_pause_menu.close()
	_hud.hide_status()
	var stage: StageData = _wave_director.stage
	var reward: BattleReward = RewardCalculator.calculate(_kills, stage, victory, _was_cleared_before)
	var unlocked_before: Array[AllyData] = ALLY_ROSTER.get_unlocked(_progress)
	var levels_gained: int = _progress.record_battle(reward, stage.stage_id if stage != null else "")
	var new_allies: PackedStringArray = PackedStringArray()
	for data: AllyData in ALLY_ROSTER.get_unlocked(_progress):
		if not unlocked_before.has(data):
			new_allies.append(data.display_name)
	var save_error: Error = _save_manager.save_progress(_progress)
	var next_name: String = ""
	if victory and not _was_cleared_before:
		var next: StageData = StageProgression.next_stage(StageProgression.region_of(stage), stage)
		if next != null:
			next_name = next.display_name
	_result_screen.show_result(reward, _progress, levels_gained, save_error, next_name, new_allies)
	get_tree().paused = true


## Leave the battle after resetting so its old progress cannot be written back by a later result.
func _on_progress_reset() -> void:
	_is_game_over = true
	SceneRoutes.go_to.call_deferred(get_tree(), SceneRoutes.MAIN_MENU)


func _read_gamepad_summons() -> void:
	var count: int = _summoner.get_slot_count()
	if count <= 0:
		return
	var direction: int = int(Input.is_action_just_pressed("select_summon_next")) - int(Input.is_action_just_pressed("select_summon_prev"))
	if direction != 0:
		_selected_summon_slot = posmod(_selected_summon_slot + direction, count)
		for slot: int in count:
			var button: TouchActionButton = _hud.get_summon_button(slot)
			button.selected = slot == _selected_summon_slot
			button.queue_redraw()
		_hud.show_message("Summon: %s · R3" % _summoner.get_slot_data(_selected_summon_slot).display_name)
	if Input.is_action_just_pressed("summon_selected"):
		_summoner.request_summon(_selected_summon_slot)
