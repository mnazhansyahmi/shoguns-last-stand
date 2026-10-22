extends SceneTree
## Actual boss AI and presentation, isolated from the player's save.
var _out: String = "res://docs/combat_polish/part3"


func _initialize() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	Engine.max_fps = 60
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://combat_polish")
	SaveManager.new("user://combat_polish/save.json").save_progress(PlayerProgress.new())
	for id: String in ["fallen_daimyo", "burning_general"]:
		seed(1337)
		var folder: String = _out.path_join(id)
		DirAccess.make_dir_recursive_absolute(folder)
		SceneRoutes.battle_stage = load("res://data/stages/stage_%d.tres" % (10 if id == "burning_general" else 5)) as StageData
		var field: Node = load("res://scenes/battlefield/battlefield.tscn").instantiate()
		field.set("save_path", "user://combat_polish/save.json")
		field.set("settings_path", "user://combat_polish/settings.cfg")
		field.set("enemy_briefing_enabled", false)
		root.add_child(field)
		(field.get_node("World/WaveDirector") as WaveDirector).stop()
		var player: Player = field.get_node("World/Player") as Player
		player.read_input = false
		player.position.x = 900
		player.get_node("HealthComponent").call("set_invulnerable_for", 30.0)
		for i: int in 30: await process_frame
		var boss: Enemy = (field.get_node("World/EnemySpawner") as EnemySpawner).spawn(load("res://data/enemies/" + id + ".tres") as EnemyData)
		boss.position.x = 1300
		for frame: int in 360:
			await process_frame
			if frame % 6 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(folder.path_join("frame_%03d.png" % (frame / 6)))
		field.free()
		print(id, " 60 animation frames captured")
	SceneRoutes.battle_stage = null
	await AudioManager.shutdown_audio(self)
	quit()
