extends SceneTree
## Deterministic comparison renders. Real renderer required. -- --tag=before|after
## Output is review evidence under docs/leg_review, never runtime art.
const KINDS: Array[InkFigure.Kind] = [InkFigure.Kind.SAMURAI, InkFigure.Kind.HATAMOTO,
		InkFigure.Kind.ONI_BRUTE, InkFigure.Kind.HOLLOW_SOLDIER]
const STEP: float = 1.0 / 120.0
var _tag: String = "after"
var _sheet: Node2D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	root.size = Vector2i(1920, 1080)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/leg_review")
	for mode: String in ["characters", "walk"]:
		_sheet = Node2D.new()
		root.add_child(_sheet)
		var paper: ColorRect = ColorRect.new()
		paper.size = Vector2(1920, 1080)
		paper.color = InkPalette.PAPER
		_sheet.add_child(paper)
		for row: int in KINDS.size():
			var kind: InkFigure.Kind = KINDS[row]
			_label(InkFigure.Kind.keys()[kind], Vector2(24.0, 14.0 + row * 262.0))
			for column: int in 8:
				var visual: UnitVisual = UnitVisual.new()
				visual.figure_kind = kind
				visual.figure_height = (110.0 if kind != InkFigure.Kind.ONI_BRUTE else 135.0) if mode == "characters" else (145.0 if kind != InkFigure.Kind.ONI_BRUTE else 190.0)
				var at: Vector2 = Vector2(105.0 + column * 238.0, 238.0 + row * 262.0)
				visual.position = at
				_sheet.add_child(visual)
				visual.set_process(false)
				visual.set("_breath_phase", 0.0)
				visual.set("_time", 0.0)
				if mode == "characters":
					var states: Array[StringName] = [&"idle", &"run", &"windup", &"strike", &"heavy_windup", &"cast", &"hurt", &"dash"]
					visual.play_state(states[column])
					if column == 1:
						visual.position.x -= 80.0 * STEP * 120.0
					for frame: int in 80:
						if column == 1:
							visual.position.x += STEP * 120.0
						visual._process(STEP)
					_label(String(states[column]), at + Vector2(-55.0, 12.0))
				else:
					visual.play_state(&"run")
					# The same harness works on the old animator and the distance-driven gait.
					var spec: FigureKinds.Spec = visual.get_figure().spec
					var speed: float = 85.0 if kind == InkFigure.Kind.ONI_BRUTE else (55.0 if kind == InkFigure.Kind.HOLLOW_SOLDIER else 120.0)
					var cycle: float = 4.0 * spec.stride_len * visual.get_figure().get_unit_scale() / speed
					if visual.get_figure().get("gait") == null:
						cycle = TAU / spec.cadence
					else:
						var local_speed: float = speed / visual.get_figure().get_unit_scale()
						var weight: float = 0.0 if spec.get("heavy_gait") or spec.get("limp") else smoothstep(spec.get("run_speed") * 0.7, spec.get("run_speed") * 1.2, local_speed)
						var extent: float = spec.stride_len * lerpf(0.65, 1.2, clampf(local_speed / spec.get("run_speed"), 0.0, 1.0))
						cycle = 2.0 * extent / lerpf(0.64, 0.43, weight) / local_speed
					var seconds: float = cycle * (2.0 + float(column) / 8.0)
					visual.position.x -= speed * seconds
					for frame: int in ceili(seconds / STEP):
						visual.position.x += speed * STEP
						visual._process(STEP)
					_label("%d / 8" % (column + 1), at + Vector2(-25.0, 12.0))
				visual.call(&"_apply")
				for child: Node in visual.get_children():
					if child != visual.get_figure():
						child.queue_free()
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://docs/leg_review/%s_%s.png" % [_tag, mode]
		var error: Error = root.get_texture().get_image().save_png(path)
		print("%s: %s" % [path, error_string(error)])
		_sheet.free()
	await AudioManager.shutdown_audio(self)
	quit()


func _label(text: String, at: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.add_theme_color_override("font_color", InkPalette.INK)
	label.add_theme_font_size_override("font_size", 18)
	_sheet.add_child(label)
