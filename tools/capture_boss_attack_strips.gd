extends SceneTree
## Snapshot the real Boss attack driver and UnitVisual, including every combo repeat.
const OUT: String = "res://docs/boss_attack_review/attacks"
const CELL: Vector2i = Vector2i(480, 580)
const COLUMNS: int = 11
var _viewport: SubViewport


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for id: String in ["fallen_daimyo", "burning_general"]:
		var data: BossData = load("res://data/enemies/" + id + ".tres") as BossData
		for attack: BossAttackData in data.attacks:
			await _capture(id, data, attack)
	await AudioManager.shutdown_audio(self)
	quit()


func _capture(id: String, data: BossData, attack: BossAttackData) -> void:
	seed(1337)
	var source: Node2D = Node2D.new()
	source.visible = false
	source.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(source)
	var boss: Boss = load("res://scenes/enemies/boss.tscn").instantiate() as Boss
	boss.setup(data)
	source.add_child(boss)
	boss.phase = 3
	boss.call("_set_facing", 1)
	var visual: UnitVisual = boss.get_node("Visual") as UnitVisual
	visual.play_state(&"idle")
	for frame: int in 80: visual._process(1.0 / 60.0)
	var repeats: int = boss.call("_repeat_count", attack)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(CELL.x * COLUMNS, CELL.y * repeats)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	_viewport.add_child(sheet)
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.36, 0.35, 0.33)
	background.size = Vector2(_viewport.size)
	sheet.add_child(background)
	boss.call("_begin_attack", attack)
	var row: int = 0
	var column: int = 0
	var seen: Dictionary = {}
	var previous: Boss.Step = Boss.Step.WINDUP
	var elapsed: float = 0.0
	for frame: int in 2400:
		if boss.get_current_attack() == null: break
		boss.call("_process_attack", 1.0 / 60.0)
		var step: Boss.Step = boss.get("_step") as Boss.Step
		if step == Boss.Step.AIR and float(boss.get("_step_time")) >= Boss.LEAP_AIR_TIME / boss.get_phase_data().speed_multiplier:
			boss.call("_land")
			step = Boss.Step.ACTIVE
		if step == Boss.Step.WINDUP and previous == Boss.Step.RECOVER:
			row += 1
			column = 0
			seen.clear()
		previous = step
		visual._process(1.0 / 60.0)
		elapsed += 1.0 / 60.0
		var motion: BossSwordMotion = visual._boss_motion
		var fraction: float = motion._elapsed / motion._duration
		var samples: PackedFloat32Array = PackedFloat32Array([0.01, 0.55, 0.82] if motion.stage == &"windup" else [0.5] if motion.stage == &"air" else [0.01, 0.25, 0.5, 0.75, 0.99] if motion.stage == &"strike" else [0.4, 0.95])
		for sample: float in samples:
			var key: String = "%s:%.2f" % [motion.stage, sample]
			if seen.has(key) or fraction < sample or column >= COLUMNS: continue
			seen[key] = true
			var lift: float = 0.0
			if step == Boss.Step.AIR:
				var air: float = Boss.LEAP_AIR_TIME / boss.get_phase_data().speed_multiplier
				var t: float = float(boss.get("_step_time"))
				lift = 0.5 * 980.0 * t * (t - air) * 205.0 / data.body_size.y
			_snapshot(sheet, visual, Vector2(195 + column * CELL.x, 480 + row * CELL.y + lift), "%s / %s\nrepeat %d · %.2fs · %s" % [id, attack.id, row + 1, elapsed, motion.stage])
			column += 1
	if column < COLUMNS:
		for frame: int in 36: visual._process(1.0 / 60.0)
		_snapshot(sheet, visual, Vector2(195 + column * CELL.x, 480 + row * CELL.y), "%s / %s\nrepeat %d · %.2fs · settled" % [id, attack.id, row + 1, elapsed + 0.6])
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = OUT.path_join(id + "_" + String(attack.id) + ".png")
	print(path, " : ", _viewport.get_texture().get_image().save_png(path), " repeats=", repeats)
	_viewport.free()
	source.free()


func _snapshot(sheet: Node2D, visual: UnitVisual, at: Vector2, text: String) -> void:
	var original: InkFigure = visual.get_figure()
	var figure: InkFigure = InkFigure.new()
	figure.kind = original.kind
	figure.height = 205
	figure.position = at
	figure.weapon_behind_body = original.weapon_behind_body
	figure.pose.copy_from(original.pose)
	figure.clock = original.clock
	sheet.add_child(figure)
	figure.refresh()
	var label: Label = Label.new()
	label.text = text
	label.position = Vector2(at.x - 180, floorf(at.y / CELL.y) * CELL.y + 520)
	label.add_theme_font_size_override("font_size", 20)
	sheet.add_child(label)
