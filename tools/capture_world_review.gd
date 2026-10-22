extends SceneTree
## Local, isolated visual fixtures for the world/boss/briefing work.
var _out: String = "res://builds/world_review/part_2"
var _mode: String = "boss"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg.begins_with("--mode="): _mode = arg.trim_prefix("--mode=")
	seed(1337)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://world_review")
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5", "stage_6", "stage_7"] as Array[String]
	SaveManager.new("user://world_review/save.json").save_progress(progress)
	SettingsStore.new("user://world_review/settings.cfg").save_settings(GameSettings.new())
	SceneRoutes.battle_stage = load("res://data/stages/stage_10.tres") as StageData
	var field: Node = load("res://scenes/battlefield/battlefield.tscn").instantiate()
	field.set("save_path", "user://world_review/save.json")
	field.set("settings_path", "user://world_review/settings.cfg")
	root.add_child(field)
	(field.get_node("Hud").get_node("%BriefingLabel") as Label).hide()
	var waves: WaveDirector = field.get_node("World/WaveDirector") as WaveDirector
	waves.stop()
	var player: Node2D = field.get_node("World/Player") as Node2D
	player.position.x = 900
	await _frames(30)
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
	print(name, ": ", root.get_texture().get_image().save_png(path))
