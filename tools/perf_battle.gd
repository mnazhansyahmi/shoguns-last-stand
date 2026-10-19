extends SceneTree
## Frame-time probe for a crowded battle: 30 enemies plus a full set of allies, fighting.
##   godot_console --headless --fixed-fps 60 --path . -s res://tools/perf_battle.gd   (CPU: scripts, physics, drawing commands)
##   godot_console --fixed-fps 60 --path . -s res://tools/perf_battle.gd              (adds real rendering on this GPU)
## Prints average / p95 / max of the engine's per-frame process + physics time.
## Uses its own save/settings under user://perf, never the player's.

const BATTLEFIELD: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HOLLOW: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI: EnemyData = preload("res://data/enemies/oni_brute.tres")
const DATA_DIR: String = "user://perf"
const WARMUP_FRAMES: int = 60
const MEASURE_FRAMES: int = 900


## Diagnostics: --hide-figures (pose maths only, no drawing), --freeze-visuals (no animation at all).
var _hide_figures: bool = false
var _freeze_visuals: bool = false


func _initialize() -> void:
	_hide_figures = OS.get_cmdline_user_args().has("--hide-figures")
	_freeze_visuals = OS.get_cmdline_user_args().has("--freeze-visuals")
	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	_run.call_deferred()


func _run() -> void:
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	for i: int in 30:
		var enemy: Enemy = spawner.spawn(ONI if i % 10 == 0 else HOLLOW)
		if enemy != null:
			enemy.global_position.x -= float(i) * 30.0
	var samples: PackedFloat64Array = PackedFloat64Array()
	for frame: int in WARMUP_FRAMES + MEASURE_FRAMES:
		if paused:
			field.call(&"_resume")
		energy.set_energy(energy.max_energy)
		if frame % 20 == 0:
			summoner.request_summon((frame / 20) % 2)
		if _hide_figures or _freeze_visuals:
			for node: Node in field.find_children("*", "UnitVisual", true, false):
				var visual: UnitVisual = node as UnitVisual
				visual.get_figure().visible = not _hide_figures
				visual.set_process(not _freeze_visuals)
		await process_frame
		if frame >= WARMUP_FRAMES:
			samples.append((Performance.get_monitor(Performance.TIME_PROCESS)
					+ Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	var enemies: int = spawner.get_alive_count()
	var allies: int = summoner.get_ally_count()
	var sorted: Array = Array(samples)
	sorted.sort()
	var total: float = 0.0
	for value: float in sorted:
		total += value
	print("frames %d, enemies alive at end %d, allies %d" % [sorted.size(), enemies, allies])
	print("frame time ms: avg %.2f  p95 %.2f  max %.2f" % [total / sorted.size(), sorted[int(sorted.size() * 0.95)], sorted[sorted.size() - 1]])
	field.free()
	await AudioManager.shutdown_audio(self)
	quit(0)
