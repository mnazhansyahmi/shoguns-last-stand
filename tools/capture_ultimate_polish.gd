extends SceneTree
## The real delayed-hit timeline, under deterministic timing, isolated save.
var _out: String = "res://docs/combat_polish/part4"


func _initialize() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	Engine.max_fps = 60
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	seed(1337)
	SceneRoutes.battle_stage = load("res://data/stages/stage_8.tres") as StageData
	var field: Node = load("res://scenes/battlefield/battlefield.tscn").instantiate()
	field.set("save_path", "user://combat_polish/save.json")
	field.set("settings_path", "user://combat_polish/settings.cfg")
	field.set("enemy_briefing_enabled", false)
	root.add_child(field)
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	var player: Player = field.get_node("World/Player") as Player
	player.read_input = false
	player.position.x = 680
	player.get_health().set_invulnerable_for(30)
	for frame: int in 30: await process_frame
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner") as EnemySpawner
	for i: int in 7:
		var enemy: Enemy = spawner.spawn(load("res://data/enemies/" + ("oni_brute" if i == 5 else "hollow_soldier") + ".tres") as EnemyData)
		enemy.global_position = Vector2(800 + i * 100, 880)
		enemy.set_physics_process(false)
	for frame: int in 25: await process_frame
	var skill: UltimateSkill = field.get_node("World/UltimateSkill") as UltimateSkill
	var meter: UltimateMeter = field.get_node("World/UltimateMeter") as UltimateMeter
	meter.add_charge(meter.max_charge)
	skill.request()
	while not player.ultimate_cinematic: await process_frame
	skill.set_process(false)
	var last: float = 0.0
	for seconds: float in [0.08, 0.22, 0.38, 0.51, 0.54, 0.62, 0.8, 0.95]:
		skill.advance_cinematic(seconds - last)
		last = seconds
		for frame: int in 2: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(_out.path_join("ultimate_t%03d.png" % roundi(seconds * 100)))
		print("ultimate ", seconds, " scale ", Engine.time_scale)
	var hud: GameHud = field.get_node("Hud") as GameHud
	hud.show_boss("The Burning General")
	hud.set_boss_health(100, 100)
	for frame: int in 2: await process_frame
	hud.set_boss_health(18, 100)
	hud.set_boss_phase(3)
	for frame: int in 2: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("boss_bar_ghost_phase.png"))
	for frame: int in 90: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join("boss_bar_low_cracks.png"))
	field.free()
	SceneRoutes.battle_stage = null
	await AudioManager.shutdown_audio(self)
	quit()
