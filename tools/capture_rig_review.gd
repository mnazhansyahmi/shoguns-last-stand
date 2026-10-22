extends SceneTree
## Frozen live-rig samples. Only writes to the requested local evidence directory.

const KINDS: Array[InkFigure.Kind] = [InkFigure.Kind.ONI_BRUTE, InkFigure.Kind.FALLEN_DAIMYO,
	InkFigure.Kind.BURNING_GENERAL, InkFigure.Kind.YUMI_ARCHER, InkFigure.Kind.SPECTRAL_ARCHER]
const STATES: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"cast", &"hurt", &"dead"]


func _initialize() -> void:
	seed(1337)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_run.call_deferred()


func _run() -> void:
	var output: String = "res://builds/v0_2_polish/part_1/motion_before.png"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2000, 1550)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(sheet)
	var background: ColorRect = ColorRect.new()
	background.size = Vector2(2000, 1550)
	background.color = Color(0.63, 0.55, 0.51)
	sheet.add_child(background)
	for row: int in KINDS.size():
		for column: int in STATES.size():
			var point: Vector2 = Vector2(115 + column * 248, 270 + row * 300)
			var visual: UnitVisual = UnitVisual.new()
			visual.figure_kind = KINDS[row]
			visual.figure_height = 150.0
			visual.position = point
			sheet.add_child(visual)
			visual.play_state(STATES[column])
			for frame: int in 30: visual._process(1.0 / 60.0)
			for effect: Node in visual.get_children():
				if effect is InkEffect: effect.free()
			var label: Label = Label.new()
			label.text = "%s\n%s" % [InkFigure.Kind.keys()[KINDS[row]].to_lower(), STATES[column]]
			label.position = point + Vector2(-100, 15)
			label.add_theme_font_size_override("font_size", 17)
			label.add_theme_color_override("font_color", Color(0.1, 0.07, 0.06))
			sheet.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = viewport.get_texture().get_image().save_png(output)
	print("Motion sheet: ", error_string(error), " ", output)
	viewport.free()
	await AudioManager.shutdown_audio(self)
	quit(error)
