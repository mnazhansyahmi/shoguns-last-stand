extends SceneTree
## Renders screenshots of the title screen, stage select and a staged battle for visual review.
## Needs a real renderer, so run it WITHOUT --headless:
##   godot_console --path . -s res://tools/capture_screenshots.gd -- --out=C:/some/dir
## Optional: --size=WxH sets the window size (default 1920x1080), --tag=name prefixes files.
## Uses its own save/settings under user://screenshots, never the player's.

const MAIN_MENU: PackedScene = preload("res://scenes/main_menu/main_menu.tscn")
const STAGE_SELECT: PackedScene = preload("res://scenes/stage_select/stage_select.tscn")
const BATTLEFIELD: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HOLLOW: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI: EnemyData = preload("res://data/enemies/oni_brute.tres")
const DATA_DIR: String = "user://screenshots"

var _out_dir: String = "user://screenshots"
var _tag: String = ""
var _battle: Node


func _initialize() -> void:
	var size: Vector2i = Vector2i(1920, 1080)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if parts.size() == 2:
				size = Vector2i(parts[0].to_int(), parts[1].to_int())
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=") + "_"
	DirAccess.make_dir_recursive_absolute(_out_dir)
	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	DisplayServer.window_set_size(size)
	_run.call_deferred()


func _run() -> void:
	await _capture_figure_sheet()
	var menu: Node = MAIN_MENU.instantiate()
	menu.set("save_path", DATA_DIR + "/save.json")
	menu.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(menu)
	await _frames(40)
	await _capture("menu")
	menu.free()

	var select: Node = STAGE_SELECT.instantiate()
	if "save_path" in select:
		select.set("save_path", DATA_DIR + "/save.json")
	root.add_child(select)
	await _frames(20)
	await _capture("stage_select")
	select.free()

	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var player: Node2D = field.get_node("World/Player")
	energy.set_energy(energy.max_energy)
	summoner.request_summon(0)
	await _frames(10)
	summoner.request_summon(1)
	for i: int in 3:
		var enemy: Enemy = spawner.spawn(HOLLOW)
		if enemy != null:
			enemy.global_position.x -= 260.0 + i * 120.0
	var oni: Enemy = spawner.spawn(ONI)
	if oni != null:
		oni.global_position.x += 60.0
	player.global_position.x = 900.0
	_battle = field
	await _frames(150)
	Input.action_press("attack")
	await _frames(14)
	Input.action_release("attack")
	await _capture("battle")
	Input.action_press("spirit_slash")
	await _frames(20)
	Input.action_release("spirit_slash")
	await _frames(6)
	await _capture("battle_slash")
	await _frames(120)
	await _capture("battle_later")
	field.free()
	await _frames(2)
	quit(0)


## Every figure kind in every animation state, on the mist colour fighters stand against.
func _capture_figure_sheet() -> void:
	var sheet: Node2D = Node2D.new()
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	var states: Array[StringName] = [&"idle", &"run", &"windup", &"strike", &"heavy_windup", &"cast", &"hurt", &"dead"]
	var heights: Array[float] = [110.0, 100.0, 96.0, 110.0, 190.0]
	var row_y: Array[float] = [190.0, 360.0, 520.0, 690.0, 1000.0]
	var dead: Array[UnitVisual] = []
	for kind: int in heights.size():
		for column: int in states.size():
			var visual: UnitVisual = UnitVisual.new()
			visual.figure_kind = kind as InkFigure.Kind
			visual.figure_height = heights[kind]
			visual.position = Vector2(120.0 + column * 225.0, row_y[kind]) / 1.05
			sheet.add_child(visual)
			if states[column] == &"dead":
				dead.append(visual)
			else:
				visual.play_state(states[column])
	sheet.scale = Vector2(1.05, 1.05) * (float(root.size.y) / 1080.0)
	# Tick the visuals by hand at 60 fps so the poses don't depend on render speed.
	var visuals: Array[Node] = sheet.get_children().filter(func(n: Node) -> bool: return n is UnitVisual)
	for node: Node in visuals:
		node.set_process(false)
	_tick(visuals, 30)
	for visual: UnitVisual in dead:
		visual.play_state(&"dead")
	_tick(visuals, 30)
	await _frames(2)
	await _capture("figures")
	sheet.free()


func _tick(visuals: Array[Node], frames: int) -> void:
	for i: int in frames:
		for node: Node in visuals:
			node.call(&"_process", 1.0 / 60.0)


## The battlefield pauses itself when the window loses focus; keep the staged battle running.
func _frames(count: int) -> void:
	for i: int in count:
		if is_instance_valid(_battle) and paused:
			_battle.call(&"_resume")
		await process_frame


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = _out_dir.path_join(_tag + shot_name + ".png")
	var error: Error = image.save_png(path)
	print("%s -> %s (%s)" % [shot_name, ProjectSettings.globalize_path(path), error_string(error)])
