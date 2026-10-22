extends SceneTree
## Local, isolated visual fixtures for the world/boss/briefing work.
var _out: String = "res://builds/world_review/part_2"
var _mode: String = "boss"
var _stage: int = 10


func _initialize() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(Vector2i.ZERO)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	Engine.max_fps = 60
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg.begins_with("--mode="): _mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--stage="): _stage = int(arg.trim_prefix("--stage="))
	seed(1337)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://world_review")
	if _mode == "menu":
		var menu: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
		menu.set("save_path", "user://world_review/menu_save.json")
		menu.set("settings_path", "user://world_review/menu_settings.cfg")
		root.add_child(menu)
		await _frames(180) # Let the menu button entrance finish before comparing pixels.
		var art: Control = menu.get_node("TitleArt") as Control
		art.set_process(false)
		var painting: LivingMenuPainting = art.get_node("ScenePainting") as LivingMenuPainting
		for seconds: float in [0.0, 1.0, 2.0, 4.0, 11.3, 14.0]:
			painting.set_time(seconds)
			await _frames(2)
			await _save("menu_t%03d" % roundi(seconds * 10))
		painting.reduced_motion = true
		for seconds: float in [0.0, 2.0]:
			painting.set_time(seconds)
			await _frames(2)
			await _save("menu_reduced_t%03d" % roundi(seconds * 10))
		painting._character.hide()
		await _frames(2)
		await _save("menu_background_only")
		var metadata: Dictionary = {"scene_position": [painting.position.x, painting.position.y],
			"logical_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
			"scene_scale": painting.scale.x, "character_offset": [LivingMenuPainting.CHARACTER_OFFSET.x, LivingMenuPainting.CHARACTER_OFFSET.y],
			"character_scale": [LivingMenuPainting.CHARACTER_SCALE.x, LivingMenuPainting.CHARACTER_SCALE.y]}
		var file: FileAccess = FileAccess.open(_out.path_join("menu_transform.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(metadata, "\t"))
		file.close()
		menu.free()
		GameSettings.reduced_decorative_motion = false
		await AudioManager.shutdown_audio(self)
		quit()
		return
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5", "stage_6", "stage_7"] as Array[String]
	SaveManager.new("user://world_review/save.json").save_progress(progress)
	SettingsStore.new("user://world_review/settings.cfg").save_settings(GameSettings.new())
	SceneRoutes.battle_stage = load("res://data/stages/stage_%d.tres" % _stage) as StageData
	var field: Node = load("res://scenes/battlefield/battlefield.tscn").instantiate()
	field.set("save_path", "user://world_review/save.json")
	field.set("enemy_briefing_enabled", false)
	field.set("settings_path", "user://world_review/settings.cfg")
	root.add_child(field)
	(field.get_node("Hud").get_node("%BriefingLabel") as Label).hide()
	var waves: WaveDirector = field.get_node("World/WaveDirector") as WaveDirector
	waves.stop()
	var player: Node2D = field.get_node("World/Player") as Node2D
	player.position.x = 900
	await _frames(30)
	if _mode == "world":
		# Inspect both camera bounds without a staged crowd obscuring the paint.
		for x: float in [200.0, 1900.0]:
			player.position.x = x
			(field.get_node("Camera2D") as BattleCamera).snap()
			await _frames(30)
			await _save("world_stage%d_%s" % [_stage, "left" if x < 1000 else "right"])
		field.free()
		SceneRoutes.battle_stage = null
		await AudioManager.shutdown_audio(self)
		quit()
		return
	if _mode == "briefing":
		field.call("_open_enemy_briefing", false)
		await _frames(3)
		await _save("enemy_briefing")
		field.free()
		paused = false
		SceneRoutes.battle_stage = null
		await AudioManager.shutdown_audio(self)
		quit()
		return
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner") as EnemySpawner
	var boss: Enemy = spawner.spawn(load("res://data/enemies/burning_general.tres") as EnemyData)
	boss.position.x = 1240
	var spirit: Enemy = spawner.spawn(load("res://data/enemies/flying_spirit.tres") as EnemyData)
	spirit.position.x = 1500
	await _frames(20)
	await _save("boss_entrance")
	await _frames(160)
	await _save("boss_battle")
	field.free()
	SceneRoutes.battle_stage = null
	paused = false
	await AudioManager.shutdown_audio(self)
	quit()


func _frames(count: int) -> void:
	for i: int in count: await process_frame
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var path: String = _out.path_join(name + ".png")
	var image: Image = root.get_texture().get_image()
	print(name, ": ", image.save_png(path))
	if name.begins_with("world_stage"):
		image.get_region(Rect2i(640, 300, 640, 440)).save_png(_out.path_join(name + "_100pct.png"))
