extends SceneTree
## Frozen live-rig poses, with original alpha preserved. Uses no player saves.

const NAMES: Array[String] = ["spectral_archer", "shield_bearer", "flying_spirit", "burning_general"]
const STATES: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"cast", &"hurt", &"dead"]


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	_run.call_deferred()


func _run() -> void:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.61, 0.53, 0.51)
	background.size = Vector2(1920, 1080)
	sheet.add_child(background)
	for row: int in NAMES.size():
		var data: EnemyData = load("res://data/enemies/%s.tres" % NAMES[row])
		for column: int in STATES.size():
			var origin: Vector2 = Vector2(110.0 + column * 238.0, 230.0 + row * 265.0)
			var visual: UnitVisual = UnitVisual.new()
			visual.figure_kind = data.figure
			visual.figure_height = 150.0
			visual.position = origin
			sheet.add_child(visual)
			if data.flying: visual.get_figure().position.y = -20.0
			if data.prop != EnemyProp.Kind.NONE:
				var prop: EnemyProp = EnemyProp.new()
				prop.setup(data.prop, visual, 150.0, 20.0 if data.flying else 0.0)
				visual.add_child(prop)
			visual.play_state(STATES[column])
			for frame: int in 30: visual._process(1.0 / 60.0)
			for effect: Node in visual.get_children():
				if effect is InkEffect: effect.free()
			var line: Line2D = Line2D.new()
			line.points = PackedVector2Array([origin + Vector2(-95, 2), origin + Vector2(100, 2)])
			line.width = 1.0
			line.default_color = Color(0.25, 0.21, 0.22)
			sheet.add_child(line)
			var label: Label = Label.new()
			label.text = "%s\n%s" % [NAMES[row].replace("_", " "), STATES[column]]
			label.position = origin + Vector2(-94, 7)
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Color(0.08, 0.07, 0.09))
			sheet.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var out: String = "res://docs/v0_2/part_2/poses.png"
	DirAccess.make_dir_recursive_absolute("res://docs/v0_2/part_2")
	var error: Error = root.get_texture().get_image().save_png(out)
	print("Region 2 pose sheet: ", error_string(error))
	sheet.free()
	await AudioManager.shutdown_audio(self)
	quit(error)
