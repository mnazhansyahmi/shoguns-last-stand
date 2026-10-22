extends SceneTree
var _size: Vector2i = Vector2i(1920, 1080)
var _touch: bool = false
var _tag: String = "1920"
const OUT: String = "res://docs/boss_attack_review/header"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--720": _size = Vector2i(1280, 720); _tag = "1280"
		if arg == "--phone": _size = Vector2i(2400, 1080); _touch = true; _tag = "phone"
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(_size)
	Engine.max_fps = 60
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute("user://boss_attack_review")
	SaveManager.new("user://boss_attack_review/save.json").save_progress(PlayerProgress.new())
	var settings: GameSettings = GameSettings.new()
	settings.touch_mode = GameSettings.TouchMode.ALWAYS if _touch else GameSettings.TouchMode.OFF
	SettingsStore.new("user://boss_attack_review/settings.cfg").save_settings(settings)
	SceneRoutes.battle_stage = load("res://data/stages/stage_10.tres") as StageData
	var field: Node = load("res://scenes/battlefield/battlefield.tscn").instantiate()
	field.set("save_path", "user://boss_attack_review/save.json")
	field.set("settings_path", "user://boss_attack_review/settings.cfg")
	field.set("enemy_briefing_enabled", false)
	root.add_child(field)
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	var player: Player = field.get_node("World/Player") as Player
	player.read_input = false
	player.position.x = 920
	for i: int in 30: await process_frame
	var boss: Enemy = (field.get_node("World/EnemySpawner") as EnemySpawner).spawn(load("res://data/enemies/burning_general.tres") as EnemyData)
	boss.position = Vector2(1250, 880)
	boss.set_physics_process(false)
	(boss.get_node("Visual") as UnitVisual).play_state(&"idle")
	var hud: GameHud = field.get_node("Hud") as GameHud
	var entrance: Node = hud.get_node_or_null("BossEntrance")
	if entrance != null: entrance.queue_free()
	for i: int in 60: await process_frame
	for peak: bool in [false, true]:
		boss.position.y = 802 if peak else 880
		for i: int in 2: await process_frame
		await RenderingServer.frame_post_draw
		var path: String = OUT.path_join(_tag + ("_leap" if peak else "_hud") + ".png")
		root.get_texture().get_image().save_png(path)
		print(path, " logical=", root.get_visible_rect().size, " bar=", hud.get_boss_bar().get_global_rect(), " camera zoom=", (field.get_node("Camera2D") as Camera2D).zoom)
	field.free()
	SceneRoutes.battle_stage = null
	await AudioManager.shutdown_audio(self)
	quit()
