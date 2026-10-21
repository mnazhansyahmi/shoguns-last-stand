extends SceneTree
## Frame-pacing probe: the samurai runs right across an empty field with vsync on (the
## monitor's real refresh rate) and every rendered frame records where his figure is drawn.
##   godot_console --path . -s res://tools/frame_pacing.gd [-- --frames=N]
## Reports the refresh rate, how many frames the figure did not move at all, and how uneven
## the per-frame motion is: world speed (drawn x step / frame delta) and the figure's step on
## screen (the camera follows him, so a smooth run barely moves on screen).
## Samples are taken just before each frame is drawn, after every node has processed.
## Uses its own save/settings under user://pacing, never the player's.

const BATTLEFIELD: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const DATA_DIR: String = "user://pacing"
const WARMUP_FRAMES: int = 60
const MEASURE_FRAMES: int = 360

var _figure: Node2D
var _world_x: PackedFloat64Array = PackedFloat64Array()
var _screen_x: PackedFloat64Array = PackedFloat64Array()
var _usec: PackedInt64Array = PackedInt64Array()
var _sampling: bool = false


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	_run.call_deferred()


func _run() -> void:
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	var player: Player = field.get_node("World/Player")
	player.global_position.x = 300.0
	(field.get_node("Camera2D") as BattleCamera).snap()
	_figure = player.get_node("Visual/Figure")
	var frames: int = MEASURE_FRAMES
	for flag: String in OS.get_cmdline_user_args():
		if flag.begins_with("--frames="):
			frames = maxi(int(flag.trim_prefix("--frames=")), 30)
	Input.action_press(&"move_right")
	for frame: int in WARMUP_FRAMES:
		await process_frame
	RenderingServer.frame_pre_draw.connect(_sample)
	_sampling = true
	while _usec.size() < frames:
		await process_frame
	_sampling = false
	RenderingServer.frame_pre_draw.disconnect(_sample)
	Input.action_release(&"move_right")
	_report()
	field.free()
	await AudioManager.shutdown_audio(self)
	quit(0)


func _sample() -> void:
	if not _sampling or not is_instance_valid(_figure):
		return
	_world_x.append(_figure.global_position.x)
	_screen_x.append(_figure.get_global_transform_with_canvas().origin.x)
	_usec.append(Time.get_ticks_usec())


func _report() -> void:
	var speeds: PackedFloat64Array = PackedFloat64Array()
	var screen_steps: PackedFloat64Array = PackedFloat64Array()
	var dts: PackedFloat64Array = PackedFloat64Array()
	var still: int = 0
	for i: int in range(1, _usec.size()):
		var dt: float = float(_usec[i] - _usec[i - 1]) / 1000000.0
		var dx: float = _world_x[i] - _world_x[i - 1]
		if absf(dx) < 0.001:
			still += 1
		dts.append(dt * 1000.0)
		speeds.append(dx / maxf(dt, 0.0001))
		screen_steps.append(_screen_x[i] - _screen_x[i - 1])
	var steps: int = speeds.size()
	print("refresh %.1f Hz | physics %d ticks/s | vsync %d | frames %d" % [DisplayServer.screen_get_refresh_rate(),
			Engine.physics_ticks_per_second, DisplayServer.window_get_vsync_mode(), steps])
	print("frame delta ms: mean %.2f  sd %.2f" % [_mean(dts), _sd(dts)])
	print("frames the figure did not move: %d of %d (%.0f%%)" % [still, steps, 100.0 * float(still) / float(steps)])
	var mean_speed: float = _mean(speeds)
	print("drawn world speed px/s: mean %.1f  sd %.1f  (unevenness %.0f%%)" % [mean_speed, _sd(speeds),
			100.0 * _sd(speeds) / maxf(absf(mean_speed), 0.001)])
	print("on-screen step px/frame: mean %.2f  sd %.2f  max |step| %.2f" % [_mean(screen_steps), _sd(screen_steps),
			_max_abs(screen_steps)])


func _mean(values: PackedFloat64Array) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / maxf(float(values.size()), 1.0)


func _sd(values: PackedFloat64Array) -> float:
	var mean: float = _mean(values)
	var total: float = 0.0
	for value: float in values:
		total += (value - mean) * (value - mean)
	return sqrt(total / maxf(float(values.size()), 1.0))


func _max_abs(values: PackedFloat64Array) -> float:
	var top: float = 0.0
	for value: float in values:
		top = maxf(top, absf(value))
	return top
