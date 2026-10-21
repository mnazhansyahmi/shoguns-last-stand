extends SceneTree
## Real-renderer motion evidence. Fixed 60 Hz simulation; capture every fourth
## rendered frame for a 15 fps clip. All menu data lives under user://motion_review.
## godot_console --fixed-fps 60 --path . -s res://tools/record_motion.gd -- --mode=menu|samurai|allies|battle --out=<absolute-dir>

const KINDS: Array[InkFigure.Kind] = [InkFigure.Kind.ASHIGARU, InkFigure.Kind.YUMI_ARCHER,
		InkFigure.Kind.SHRINE_HEALER, InkFigure.Kind.SPEAR_GUARDIAN, InkFigure.Kind.ONMYOJI, InkFigure.Kind.HATAMOTO]
var _mode: String = "menu"
var _out: String = "res://builds/animation_phase/menu_frames"
var _visuals: Array[UnitVisual] = []
var _caption: Label
var _previous_state: StringName = &""
var _errors: int = 0
class RenderErrors extends Logger:
	var count: int = 0
	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING: count += 1
var _render_errors: RenderErrors = RenderErrors.new()
var _battle: Node
var _player: Player


func _initialize() -> void:
	OS.add_logger(_render_errors)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): _mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Engine.max_fps = 0
	seed(4139)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://motion_review")
	if _mode == "menu":
		var menu: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
		menu.set("save_path", "user://motion_review/save.json")
		menu.set("settings_path", "user://motion_review/settings.cfg")
		root.add_child(menu)
	elif _mode == "battle":
		_build_battle()
	else:
		_build_stage()
	# Let imports, material compilation and menu entrances finish before recording.
	for i: int in 75:
		await process_frame
	var frames: int = 600 if _mode in ["samurai", "battle"] else 360
	for frame: int in frames:
		_update_sequence(float(frame) / 60.0)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame % 4 == 0:
			var result: Error = root.get_texture().get_image().save_png(_out.path_join("%04d.png" % (frame / 4)))
			if result != OK: _errors += 1
	print("Recorded %s: %d frames at 15 fps, save errors %d" % [_mode, frames / 4, _errors])
	Input.action_release("move_right")
	Input.action_release("move_left")
	await AudioManager.shutdown_audio(self)
	var result_code: int = 1 if _errors > 0 or _render_errors.count > 0 else 0
	OS.remove_logger(_render_errors)
	quit(result_code)


func _build_stage() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	var back: ColorRect = ColorRect.new()
	back.size = Vector2(1280, 720)
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	root.add_child(back)
	_caption = _label("", Vector2(24, 20), 28)
	var kinds: Array[InkFigure.Kind] = KINDS.duplicate()
	if _mode == "samurai": kinds = [InkFigure.Kind.SAMURAI] as Array[InkFigure.Kind]
	for i: int in kinds.size():
		var origin: Vector2 = Vector2(600, 635) if _mode == "samurai" else Vector2(200 + (i % 3) * 425, 320 + (i / 3) * 345)
		var ground: Line2D = Line2D.new()
		ground.points = PackedVector2Array([origin + Vector2(-130, 0), origin + Vector2(175, 0)])
		ground.width = 2.0
		ground.default_color = InkPalette.INK_DETAIL
		root.add_child(ground)
		var visual: UnitVisual = UnitVisual.new()
		visual.position = origin
		root.add_child(visual)
		visual.configure(kinds[i], 360.0 if _mode == "samurai" else 195.0)
		visual.play_state(&"idle")
		_visuals.append(visual)
		_label(InkFigure.Kind.keys()[kinds[i]].capitalize(), origin + Vector2(-120, 18), 20)


func _update_sequence(time: float) -> void:
	if _mode == "menu": return
	if _mode == "battle":
		_update_battle(time)
		return
	var state: StringName = &"idle"
	if _mode == "samurai":
		if time >= 2.0 and time < 4.7: state = &"run"
		elif time >= 5.4 and time < 5.8: state = &"heavy_windup"
		elif time >= 5.8 and time < 6.35: state = &"strike"
		elif time >= 7.0 and time < 7.3: state = &"shoot"
		elif time >= 8.2 and time < 8.9: state = &"war_cry"
	else:
		if time >= 1.8 and time < 3.8: state = &"run"
		elif time >= 4.25 and time < 4.65: state = &"windup"
		elif time >= 4.65 and time < 5.15: state = &"strike"
	if state != _previous_state:
		for visual: UnitVisual in _visuals:
			visual.play_state(state)
		_previous_state = state
	_caption.text = "%s — %s — %.1f s" % [_mode.capitalize(), state, time]
	for visual: UnitVisual in _visuals:
		if state == &"run":
			var direction: int = -1 if _mode == "samurai" and time >= 3.5 else 1
			visual.position.x += direction * (130.0 if _mode == "samurai" else 34.0) / 60.0
			visual.set_facing(direction)
		elif _mode == "samurai" and time > 4.8:
			visual.set_facing(1)


func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", InkPalette.INK)
	root.add_child(label)
	return label


func _build_battle() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	SaveManager.new("user://motion_review/save.json").save_progress(progress)
	var settings: GameSettings = GameSettings.new()
	settings.touch_mode = GameSettings.TouchMode.OFF
	SettingsStore.new("user://motion_review/settings.cfg").save_settings(settings)
	SceneRoutes.battle_stage = StageProgression.default_region().stages[0]
	_battle = load("res://scenes/battlefield/battlefield.tscn").instantiate()
	_battle.set("save_path", "user://motion_review/save.json")
	_battle.set("settings_path", "user://motion_review/settings.cfg")
	root.add_child(_battle)
	(_battle.get_node("World/WaveDirector") as WaveDirector).stop()
	_player = _battle.get_node("World/Player") as Player
	_player.global_position.x = 900.0
	var energy: SpiritEnergy = _battle.get_node("World/SpiritEnergy") as SpiritEnergy
	energy.max_energy = 1000.0
	energy.set_energy(1000.0)
	var summoner: SummonManager = _battle.get_node("World/SummonManager") as SummonManager
	for slot: int in summoner.get_slot_count(): summoner.request_summon(slot)
	var spawner: EnemySpawner = _battle.get_node("World/EnemySpawner") as EnemySpawner
	for i: int in 5:
		var enemy: Enemy = spawner.spawn(load("res://data/enemies/hollow_soldier.tres") as EnemyData)
		if enemy != null: enemy.global_position.x = 1300.0 + i * 120.0


func _update_battle(time: float) -> void:
	Input.action_release("move_right")
	Input.action_release("move_left")
	if time >= 1.0 and time < 2.8: Input.action_press("move_right")
	if time >= 2.8 and time < 3.4: Input.action_press("move_left")
	var action: StringName = &"idle"
	if time >= 4.0 and time < 4.1: action = &"heavy_attack"
	elif time >= 5.5 and time < 5.6: action = &"bow"
	elif time >= 7.0 and time < 7.1: action = &"war_cry"
	elif time >= 8.4 and time < 8.5: action = &"spirit_slash"
	if action != _previous_state:
		if _previous_state != &"" and _previous_state != &"idle": Input.action_release(_previous_state)
		if action != &"idle": Input.action_press(action)
		_previous_state = action
