extends SceneTree
## Frame-time probe for a crowded battle: exactly 30 enemies alive (topped up as they die),
## the player in the middle of the field, allies summoned to the cap, everyone fighting.
##   godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd [-- <flags>]
## --fixed-fps keeps the simulation identical from run to run; vsync and the frame cap are
## turned off so the measured time is real work, not waiting. Reports wall-clock frame time
## (average / p95 / max) and the renderer's own CPU and GPU time for the viewport.
## Diagnostic flags (to attribute cost): --hide-figures, --freeze-visuals, --no-backdrop,
## --no-effects, --no-hud.
## Uses its own save/settings under user://perf, never the player's.

const BATTLEFIELD: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HOLLOW: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI: EnemyData = preload("res://data/enemies/oni_brute.tres")
const DATA_DIR: String = "user://perf"
const ENEMIES: int = 30
const WARMUP_FRAMES: int = 120
const MEASURE_FRAMES: int = 900

var _flags: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_flags = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_run.call_deferred()


func _run() -> void:
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var player: Node2D = field.get_node("World/Player")
	player.global_position.x = 1150.0
	if _flags.has("--no-backdrop"):
		(field.get_node("World/Backdrop") as CanvasItem).visible = false
	if _flags.has("--no-effects"):
		for path: String in ["World/Effects", "World/HitEffects"]:
			(field.get_node(path) as CanvasItem).visible = false
	if _flags.has("--no-hud"):
		(field.get_node("Hud") as CanvasLayer).visible = false
	var viewport_rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)

	var wall: PackedFloat64Array = PackedFloat64Array()
	var render_cpu: float = 0.0
	var render_gpu: float = 0.0
	var spawned: int = 0
	var last_usec: int = Time.get_ticks_usec()
	for frame: int in WARMUP_FRAMES + MEASURE_FRAMES:
		if paused:
			field.call(&"_resume")
		energy.set_energy(energy.max_energy)
		if frame % 20 == 0:
			summoner.request_summon((frame / 20) % 2)
		while spawner.get_alive_count() < ENEMIES:
			var enemy: Enemy = spawner.spawn(ONI if spawned % 10 == 0 else HOLLOW)
			spawned += 1
			if enemy == null:
				break
			enemy.global_position.x -= float(spawned % 12) * 40.0
		if _flags.has("--hide-figures") or _flags.has("--freeze-visuals"):
			for node: Node in field.find_children("*", "UnitVisual", true, false):
				var visual: UnitVisual = node as UnitVisual
				visual.get_figure().visible = not _flags.has("--hide-figures")
				visual.set_process(not _flags.has("--freeze-visuals"))
		await process_frame
		var now: int = Time.get_ticks_usec()
		if frame >= WARMUP_FRAMES:
			wall.append(float(now - last_usec) / 1000.0)
			render_cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid) + RenderingServer.get_frame_setup_time_cpu()
			render_gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
		last_usec = now
	var sorted: Array = Array(wall)
	sorted.sort()
	var total: float = 0.0
	for value: float in sorted:
		total += value
	var count: float = float(sorted.size())
	print("flags %s | enemies %d, allies %d, frames %d" % [" ".join(_flags) if not _flags.is_empty() else "-",
			spawner.get_alive_count(), summoner.get_ally_count(), sorted.size()])
	print("frame ms: avg %.2f  p95 %.2f  max %.2f | render cpu avg %.2f  gpu avg %.2f" % [total / count,
			sorted[int(count * 0.95)], sorted[sorted.size() - 1], render_cpu / count, render_gpu / count])
	field.free()
	await AudioManager.shutdown_audio(self)
	quit(0)
