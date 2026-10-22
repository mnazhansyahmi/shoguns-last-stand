extends SceneTree
## Live posed rigs, one sheet per wielder. No player save or gameplay state.
const STATES: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"cast", &"hurt", &"dead"]
var _out: String = "res://docs/combat_polish/part2"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
	seed(1337)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2000, 1120)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for kind: int in InkFigure.Kind.values():
		if kind == InkFigure.Kind.FLYING_SPIRIT: continue
		var sheet: Node2D = Node2D.new()
		sheet.process_mode = Node.PROCESS_MODE_DISABLED
		viewport.add_child(sheet)
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0.43, 0.42, 0.4)
		bg.size = Vector2(viewport.size)
		sheet.add_child(bg)
		for column: int in STATES.size():
			var visual: UnitVisual = UnitVisual.new()
			visual.figure_kind = kind as InkFigure.Kind
			visual.figure_height = 205
			visual.position = Vector2(170 + (column % 4) * 500, 480 + (column / 4) * 560)
			sheet.add_child(visual)
			if kind == InkFigure.Kind.SHIELD_BEARER:
				var prop: EnemyProp = EnemyProp.new()
				prop.setup(EnemyProp.Kind.SHIELD, visual, visual.figure_height)
				visual.add_child(prop)
			visual.play_state(STATES[column])
			for frame: int in (12 if STATES[column] == &"strike" else 28): visual._process(1.0 / 60.0)
			for child: Node in visual.get_children():
				if child is InkEffect: child.free()
			var label: Label = Label.new()
			label.text = "%s — %s" % [InkFigure.Kind.keys()[kind], STATES[column]]
			label.position = Vector2((column % 4) * 500 + 15, 520 + (column / 4) * 560)
			label.add_theme_font_size_override("font_size", 20)
			sheet.add_child(label)
		await process_frame
		await RenderingServer.frame_post_draw
		var name: String = InkFigure.Kind.keys()[kind].to_lower()
		print(name, " ", viewport.get_texture().get_image().save_png(_out.path_join(name + ".png")))
		sheet.free()
	viewport.free()
	await AudioManager.shutdown_audio(self)
	quit()
