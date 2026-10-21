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
## --touch: show the on-screen touch controls in the battle, as on a phone.
var _touch: bool = false
## --only=samurai: render just the samurai sheets (poses, attack strip, close-up, run-and-stop strip), then quit.
var _only: String = ""
## --locked: the staged battle with no stage cleared (locked skills, fewer allies).
var _locked: bool = false
## --skills: also capture the Bow mid-draw and the War Cry mid-shout in the staged battle.
var _skills: bool = false
## --fight: also capture the samurai cutting into enemies: blood in the air, then the stains on the ground.
var _fight: bool = false
## --fireball: also film the Onmyoji's fireball (windup, flight, explosion) in the staged battle.
var _fireball: bool = false
## --cooldowns: also capture the HUD just after every skill was used (the icons' cooldown sweeps and seconds).
var _cooldowns: bool = false
## --black: the kind sheet (--only=kind:<name>) in pure black, to check the silhouette.
var _black: bool = false
## --stage=N: play the staged battle on that Region 1 stage (its own sky theme).
var _stage_number: int = 1


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
		elif arg == "--touch":
			_touch = true
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg == "--locked":
			_locked = true
		elif arg == "--skills":
			_skills = true
		elif arg == "--fight":
			_fight = true
		elif arg == "--black":
			_black = true
		elif arg == "--fireball":
			_fireball = true
		elif arg == "--cooldowns":
			_cooldowns = true
		elif arg.begins_with("--stage="):
			_stage_number = arg.trim_prefix("--stage=").to_int()
	DirAccess.make_dir_recursive_absolute(_out_dir)
	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	var settings: GameSettings = GameSettings.new()
	settings.touch_mode = GameSettings.TouchMode.ALWAYS if _touch else GameSettings.TouchMode.OFF
	SettingsStore.new(DATA_DIR + "/settings.cfg").save_settings(settings)
	DisplayServer.window_set_size(size)
	Engine.max_fps = 60
	_run.call_deferred()


func _run() -> void:
	if _only == "sheets":
		await _capture_figure_sheet("figures", Color.WHITE)
		await _capture_figure_sheet("silhouettes", Color.BLACK)
		await _capture_ally_sheet("allies", Color.WHITE)
		await _capture_ally_sheet("ally_silhouettes", Color.BLACK)
		await _capture_samurai_sheet()
		quit(0)
		return
	if _only == "crowd":
		await _capture_crowd()
		quit(0)
		return
	if _only == "menus":
		var menu: Node = MAIN_MENU.instantiate()
		menu.set("save_path", DATA_DIR + "/save.json")
		menu.set("settings_path", DATA_DIR + "/settings.cfg")
		root.add_child(menu)
		await _frames(30)
		await _capture("menu")
		menu.free()
		var credits: Node = load("res://scenes/credits/credits.tscn").instantiate()
		root.add_child(credits)
		await _frames(30)
		await _capture("credits")
		credits.free()
		quit(0)
		return
	if _only == "stages":
		await _capture_stage_select()
		quit(0)
		return
	if _only == "mainmenu":
		await _capture_main_menu()
		quit(0)
		return
	if _only == "boss":
		await _capture_boss()
		quit(0)
		return
	if _only == "playtest":
		await _capture_playtest()
		quit(0)
		return
	if _only == "allies":
		await _capture_ally_sheet("allies", Color.WHITE)
		await _capture_ally_sheet("ally_silhouettes", Color.BLACK)
		quit(0)
		return
	if _only == "upgrades":
		await _capture_upgrades()
		quit(0)
		return
	if _only.begins_with("kind:"):
		await _capture_kind_sheet(_only.trim_prefix("kind:"))
		quit(0)
		return
	if _only == "skills":
		await _capture_skill_strips()
		quit(0)
		return
	if _only == "samurai":
		await _capture_samurai_sheet()
		await _capture_samurai_strip()
		await _capture_samurai_detail()
		await _capture_samurai_run_strip()
		quit(0)
		return
	if _only != "battle":
		await _capture_sheets_and_menus()
	await _capture_battle()
	await _frames(2)
	quit(0)


func _capture_sheets_and_menus() -> void:
	await _capture_figure_sheet("figures", Color.WHITE)
	await _capture_ally_sheet("allies", Color.WHITE)
	await _capture_ally_sheet("ally_silhouettes", Color.BLACK)
	await _capture_samurai_sheet()
	await _capture_samurai_strip()
	await _capture_samurai_detail()
	await _capture_samurai_run_strip()
	# Pure black: every figure must still read from its shape alone (art bible silhouette test).
	await _capture_figure_sheet("silhouettes", Color.BLACK)
	await _capture_vfx_sheet()
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


func _capture_battle() -> void:
	# Every ally unlocked, so the battle shows the full summon bar and all six allies.
	var progress: PlayerProgress = PlayerProgress.new()
	if not _locked:
		progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	SaveManager.new(DATA_DIR + "/save.json").save_progress(progress)
	var region: RegionData = StageProgression.default_region()
	SceneRoutes.battle_stage = region.stages[clampi(_stage_number, 1, region.stages.size()) - 1]
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var player: Node2D = field.get_node("World/Player")
	energy.max_energy = 600.0
	energy.set_energy(600.0)
	for slot: int in summoner.get_slot_count():
		summoner.request_summon(slot)
		await _frames(6)
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
	if _cooldowns:
		for action: String in ["dash", "heavy_attack", "spirit_slash", "bow", "war_cry"]:
			Input.action_press(action)
			await _frames(2)
			Input.action_release(action)
			await _frames(5)
		await _capture("battle_cooldowns")
		await _frames(120)
	if _skills:
		Input.action_press("bow")
		await _frames(2)
		Input.action_release("bow")
		await _frames(10)
		await _capture("battle_bow_draw")
		await _frames(70)
		Input.action_press("war_cry")
		await _frames(2)
		Input.action_release("war_cry")
		await _frames(22)
		await _capture("battle_war_cry")
		await _frames(30)
	if _fireball:
		await _capture_fireball(field)
	if _fight:
		await _capture_fight(field, player)
	Input.action_press("spirit_slash")
	await _frames(20)
	Input.action_release("spirit_slash")
	await _frames(6)
	await _capture("battle_slash")
	# Wound the staged enemies so their health bars show (and stack where they overlap).
	for node: Node in field.get_tree().get_nodes_in_group("enemies"):
		(node.get_node("HealthComponent") as HealthComponent).take_damage(12.0)
	await _frames(120)
	await _capture("battle_later")
	if _only != "battle":
		await _capture_ultimate(field, spawner)
	field.free()


## The Onmyoji casting at a group: filmed every few frames from the windup to the explosion.
func _capture_fireball(field: Node) -> void:
	var mage: Node2D = null
	for node: Node in field.get_tree().get_nodes_in_group("allies"):
		if node is Ally and (node as Ally).data.id == "onmyoji":
			mage = node as Node2D
	if mage == null:
		return
	mage.global_position.x = 600.0
	var enemies: Array[Node] = field.get_tree().get_nodes_in_group("enemies")
	for i: int in enemies.size():
		(enemies[i] as Node2D).global_position.x = 1000.0 + float(i) * 70.0
	for i: int in 16:
		await _frames(5)
		await _capture("fireball_%02d" % i)


## The samurai in the middle of a fight: light cuts, a heavy blow and the Spirit Slash into a line of enemies, then
## the stains they leave.
func _capture_fight(field: Node, player: Node2D) -> void:
	var enemies: Array[Node] = field.get_tree().get_nodes_in_group("enemies")
	for i: int in enemies.size():
		(enemies[i] as Node2D).global_position.x = player.global_position.x + 110.0 + float(i) * 75.0
	Input.action_press("attack")
	await _frames(16)
	await _capture("fight_cut")
	await _frames(12)
	Input.action_release("attack")
	Input.action_press("heavy_attack")
	await _frames(22)
	Input.action_release("heavy_attack")
	await _capture("fight_heavy")
	await _frames(4)
	Input.action_press("spirit_slash")
	await _frames(16)
	Input.action_release("spirit_slash")
	await _capture("fight_spirit")
	await _frames(90)
	await _capture("fight_stains")


## The Ultimate: the meter filling, the glowing button/bar when ready, and the brush sweep
## frozen in the middle of the dramatic pause.
func _capture_ultimate(field: Node, spawner: EnemySpawner) -> void:
	var meter: UltimateMeter = field.get_node("World/UltimateMeter")
	var skill: UltimateSkill = field.get_node("World/UltimateSkill")
	var player: Node2D = field.get_node("World/Player")
	for node: Node in field.get_tree().get_nodes_in_group("enemies"):
		(node.get_node("HealthComponent") as HealthComponent).take_damage(100000.0)
	await _frames(60)
	player.global_position.x = 700.0
	meter.add_charge(meter.max_charge * 0.55)
	await _frames(4)
	await _capture("ultimate_charging")
	meter.add_charge(meter.max_charge)
	await _frames(30)
	await _capture("ultimate_ready")
	for i: int in 5:
		var enemy: Enemy = spawner.spawn(HOLLOW)
		if enemy != null:
			enemy.global_position.x = 1000.0 + float(i) * 150.0
	await _frames(20)
	skill.request()
	# The wind-up is 0.35 s (21 frames); the sweep lands, then the game freezes for 0.4 s.
	await _frames(24)
	await _capture("ultimate_flash")
	await _frames(8)
	await _capture("ultimate_sweep")
	await _frames(14)
	await _capture("ultimate_hold")
	await _frames(60)
	await _capture("ultimate_after")


## The Fallen Daimyo in stage 5: each phase, the phase change, and the wind-up warning of every attack.
func _capture_boss() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	SaveManager.new(DATA_DIR + "/save.json").save_progress(progress)
	SceneRoutes.battle_stage = StageProgression.default_region().stages[4]
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	_battle = field
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var player: Node2D = field.get_node("World/Player")
	(player.get_node("HealthComponent") as HealthComponent).set_invulnerable_for(9999.0)
	energy.max_energy = 3000.0
	energy.set_energy(3000.0)
	for slot: int in summoner.get_slot_count():
		summoner.request_summon(slot)
		await _frames(5)
	var data: BossData = load("res://data/enemies/fallen_daimyo.tres") as BossData
	var boss: Boss = spawner.spawn(data) as Boss
	boss.global_position.x = 1250.0
	player.global_position.x = 760.0
	var health: HealthComponent = boss.get_node("HealthComponent") as HealthComponent
	await _frames(100)
	await _capture("boss_1_phase1")
	for attack: BossAttackData in data.attacks:
		if attack.min_phase > 1:
			continue
		await _boss_windup(boss, attack, "boss_1_%s_windup" % attack.id)
	# Phase 2 at 66%: the roar, then the new attacks.
	health.take_damage(health.max_health * 0.35)
	await _frames(25)
	await _capture("boss_2_roar")
	await _frames(100)
	await _capture("boss_2_phase2")
	for attack: BossAttackData in data.attacks:
		if attack.min_phase == 2:
			await _boss_windup(boss, attack, "boss_2_%s_windup" % attack.id)
	# Phase 3 at 33%.
	health.take_damage(health.max_health * 0.33)
	await _frames(25)
	await _capture("boss_3_roar")
	await _frames(110)
	await _capture("boss_3_phase3")
	for attack: BossAttackData in data.attacks:
		if attack.min_phase == 3:
			await _boss_windup(boss, attack, "boss_3_%s_windup" % attack.id)
	field.free()


## Starts one attack and captures it near the end of its wind-up, when the warning is almost full.
func _boss_windup(boss: Boss, attack: BossAttackData, shot_name: String) -> void:
	boss.call("_cancel_attack")
	boss.call("_resume")
	boss.set("_gap_left", 0.0)
	boss.call("_begin_attack", attack)
	var seconds: float = attack.windup / boss.get_phase_data().speed_multiplier * 0.85
	await _frames(int(seconds * 60.0))
	await _capture(shot_name)
	await _frames(70)


## A crowded battle for the playtest checks: six allies at the gate, a column of soldiers, an Oni
## caught in its hit flash, and the Ultimate's slash mid-effect.
func _capture_playtest() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	SaveManager.new(DATA_DIR + "/save.json").save_progress(progress)
	var region: RegionData = StageProgression.default_region()
	SceneRoutes.battle_stage = region.stages[clampi(_stage_number, 1, region.stages.size()) - 1]
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	_battle = field
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var meter: UltimateMeter = field.get_node("World/UltimateMeter")
	var skill: UltimateSkill = field.get_node("World/UltimateSkill")
	var player: Node2D = field.get_node("World/Player")
	energy.max_energy = 3000.0
	energy.set_energy(3000.0)
	for round: int in 2:
		for slot: int in summoner.get_slot_count():
			summoner.request_summon(slot)
			await _frames(5)
	for i: int in 10:
		var enemy: Enemy = spawner.spawn(HOLLOW)
		if enemy != null:
			enemy.global_position.x -= 700.0 - float(i) * 70.0
	var oni: Enemy = spawner.spawn(ONI)
	if oni != null:
		oni.global_position.x = 1150.0
	player.global_position.x = 760.0
	await _frames(100)
	if oni != null and is_instance_valid(oni):
		(oni.get_node("HealthComponent") as HealthComponent).take_damage(30.0)
		(oni.get_node("Visual") as UnitVisual).flash_hit()
	await _frames(2)
	await _capture("playtest_oni_flash")
	await _frames(60)
	meter.add_charge(meter.max_charge)
	await _frames(10)
	skill.request()
	await _frames(24)
	await _capture("playtest_ultimate_a")
	await _frames(5)
	await _capture("playtest_ultimate_b")
	field.free()


## Every figure kind in every animation state, on the mist colour fighters stand against.
func _capture_figure_sheet(shot_name: String, tint: Color) -> void:
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
			visual.set_tint(tint)
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
	await _capture(shot_name)
	sheet.free()


## A crowded battle: twelve allies against twenty-odd enemies, two Oni among them, captured twice as
## the lines meet (to judge variation between units, ally separation and the health bars).
func _capture_crowd() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.stages_cleared = ["stage_1", "stage_2", "stage_3", "stage_4"] as Array[String]
	SaveManager.new(DATA_DIR + "/save.json").save_progress(progress)
	var region: RegionData = StageProgression.default_region()
	SceneRoutes.battle_stage = region.stages[clampi(_stage_number, 1, region.stages.size()) - 1]
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", DATA_DIR + "/save.json")
	field.set("settings_path", DATA_DIR + "/settings.cfg")
	root.add_child(field)
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var player: Node2D = field.get_node("World/Player")
	energy.max_energy = 2000.0
	energy.set_energy(2000.0)
	summoner.max_allies = 12
	_battle = field
	for round: int in 2:
		for slot: int in summoner.get_slot_count():
			summoner.tick(100.0)
			summoner.request_summon(slot)
			await _frames(4)
	player.global_position.x = 760.0
	var spawned: int = 0
	for i: int in 22:
		var enemy: Enemy = spawner.spawn(ONI if i % 11 == 5 else HOLLOW)
		if enemy != null:
			enemy.global_position.x = 760.0 + 80.0 * float(i % 12) + (i / 12) * 40.0
			spawned += 1
	await _frames(170)
	await _capture("crowd_a")
	await _frames(120)
	await _capture("crowd_b")
	field.free()


## The six allies in every animation state, each row one ally (the later four are the new ones),
## to compare silhouettes and accents. `tint` black = the silhouette test.
func _capture_ally_sheet(shot_name: String, tint: Color) -> void:
	var sheet: Node2D = Node2D.new()
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	var kinds: Array[InkFigure.Kind] = [InkFigure.Kind.ASHIGARU, InkFigure.Kind.YUMI_ARCHER, InkFigure.Kind.SHRINE_HEALER,
			InkFigure.Kind.SPEAR_GUARDIAN, InkFigure.Kind.ONMYOJI, InkFigure.Kind.HATAMOTO]
	var heights: Array[float] = [100.0, 96.0, 98.0, 108.0, 104.0, 106.0]
	var states: Array[StringName] = [&"idle", &"run", &"windup", &"strike", &"hurt", &"dead"]
	var visuals: Array[Node] = []
	var dead: Array[UnitVisual] = []
	for row: int in kinds.size():
		for column: int in states.size():
			var visual: UnitVisual = UnitVisual.new()
			visual.figure_kind = kinds[row]
			visual.figure_height = heights[row]
			visual.position = Vector2(150.0 + float(column) * 300.0, 190.0 + float(row) * 170.0)
			sheet.add_child(visual)
			visual.set_tint(tint)
			visuals.append(visual)
			if states[column] == &"dead":
				dead.append(visual)
			else:
				visual.play_state(states[column])
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	for node: Node in visuals:
		node.set_process(false)
	_tick(visuals, 30)
	for visual: UnitVisual in dead:
		visual.play_state(&"dead")
	_tick(visuals, 30)
	await _frames(2)
	await _capture(shot_name)
	sheet.free()


## The samurai close up: every attack pose at a few moments of the swing (for before/after
## comparison). Each cell plays a short sequence of [state, seconds] through a UnitVisual.
func _capture_samurai_sheet() -> void:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	var cells: Array[Dictionary] = [
		{"label": "idle", "seq": [[&"idle", 0.6]]},
		{"label": "run", "seq": [[&"run", 0.4]]},
		{"label": "cut 1 windup", "seq": [[&"windup", 0.06]]},
		{"label": "cut 1 strike", "seq": [[&"windup", 0.08], [&"strike", 0.05]]},
		{"label": "cut 1 follow", "seq": [[&"windup", 0.08], [&"strike", 0.2]]},
		{"label": "dash", "seq": [[&"dash", 0.1]]},
		{"label": "cut 2 windup", "seq": [[&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.06]]},
		{"label": "cut 2 strike", "seq": [[&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.08], [&"strike", 0.05]]},
		{"label": "cut 2 follow", "seq": [[&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.08], [&"strike", 0.2]]},
		{"label": "cut 3 windup", "seq": [[&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.08]]},
		{"label": "cut 3 strike", "seq": [[&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.14], [&"strike", 0.05]]},
		{"label": "cut 3 follow", "seq": [[&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.08], [&"strike", 0.1], [&"windup", 0.14], [&"strike", 0.25]]},
		{"label": "heavy windup", "seq": [[&"heavy_windup", 0.3]]},
		{"label": "heavy strike", "seq": [[&"heavy_windup", 0.35], [&"strike", 0.05]]},
		{"label": "heavy follow", "seq": [[&"heavy_windup", 0.35], [&"strike", 0.3]]},
		{"label": "cast", "seq": [[&"cast", 0.3]]},
		{"label": "hurt", "seq": [[&"hurt", 0.1]]},
		{"label": "dead", "seq": [[&"dead", 0.6]]},
	]
	var cell_w: float = 320.0
	var cell_h: float = 360.0
	var visuals: Array[UnitVisual] = []
	for i: int in cells.size():
		var cell: Dictionary = cells[i]
		var origin: Vector2 = Vector2(float(i % 6) * cell_w + 130.0, float(i / 6) * cell_h + 300.0)
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 180.0, origin)
		visuals.append(visual)
		var label: Label = Label.new()
		label.text = cell["label"]
		label.position = origin + Vector2(-90.0, 24.0)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", InkPalette.INK)
		sheet.add_child(label)
		for step: Array in cell["seq"]:
			visual.play_state(step[0])
			_tick_one(visual, step[1])
		# The sheet is frozen, so trails and splashes would stay at full strength: drop them.
		for child: Node in visual.get_children():
			if child is InkEffect:
				child.free()
	await _frames(2)
	await _capture("samurai_sheet")
	sheet.free()


## Three large samurai (guard, run, mid-cut) to judge the armour and proportions.
func _capture_samurai_detail() -> void:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	var states: Array[StringName] = [&"idle", &"run", &"strike"]
	for i: int in states.size():
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 640.0, Vector2(330.0 + float(i) * 640.0, 960.0))
		visual.play_state(&"idle")
		_tick_one(visual, 0.5)
		if states[i] == &"strike":
			visual.play_state(&"windup")
			_tick_one(visual, 0.08)
		visual.play_state(states[i])
		_tick_one(visual, 0.4 if states[i] == &"run" else 0.1)
		for child: Node in visual.get_children():
			if child is InkEffect:
				child.free()
	await _frames(2)
	await _capture("samurai_detail")
	sheet.free()


## One cut filmed every 1/30 s from the first press (windup) to the end of recovery: shows
## anticipation, the accelerating swing, follow-through and settle.
func _capture_samurai_strip() -> void:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	var frames: int = 18
	var visuals: Array[UnitVisual] = []
	for i: int in frames:
		var origin: Vector2 = Vector2(float(i % 9) * 213.0 + 100.0, float(i / 9) * 540.0 + 400.0)
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 150.0, origin)
		visuals.append(visual)
		var label: Label = Label.new()
		label.text = "%d ms" % roundi(float(i) * 1000.0 / 30.0)
		label.position = origin + Vector2(-40.0, 24.0)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", InkPalette.INK)
		sheet.add_child(label)
		visual.play_state(&"idle")
		_tick_one(visual, 0.5)
		# Same input timeline for every frame: press at 0, hit lands at 80 ms, back to guard at 400 ms.
		var t: float = float(i) / 30.0
		visual.play_state(&"windup")
		_tick_one(visual, minf(t, 0.08))
		if t > 0.08:
			visual.play_state(&"strike")
			_tick_one(visual, minf(t - 0.08, 0.32))
		if t > 0.4:
			visual.play_state(&"idle")
			_tick_one(visual, t - 0.4)
	await _frames(2)
	await _capture("samurai_strip")
	sheet.free()


## The Bow (reach, draw, aim, release, stow) and the War Cry (gather, shout) filmed frame by frame, then the
## War Cry's gold ring racing out over three allies.
func _capture_skill_strips() -> void:
	var sheet: Node2D = _blank_sheet()
	var bow_times: Array[float] = [0.0, 0.04, 0.08, 0.12, 0.18, 0.24, 0.3, 0.33, 0.4, 0.46, 0.5, 0.6]
	for i: int in bow_times.size():
		var origin: Vector2 = Vector2(float(i % 6) * 320.0 + 110.0, float(i / 6) * 520.0 + 400.0)
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 150.0, origin)
		visual.play_state(&"idle")
		_tick_one(visual, 0.5)
		visual.play_state(&"shoot")
		_tick_one(visual, bow_times[i])
		_label(sheet, "bow %d ms" % roundi(bow_times[i] * 1000.0), origin)
	await _frames(2)
	await _capture("skill_bow")
	sheet.free()
	sheet = _blank_sheet()
	var cry_times: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.34, 0.4, 0.5, 0.6]
	for i: int in cry_times.size():
		var origin: Vector2 = Vector2(float(i % 6) * 320.0 + 110.0, float(i / 6) * 520.0 + 400.0)
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 150.0, origin)
		visual.play_state(&"idle")
		_tick_one(visual, 0.5)
		visual.play_state(&"war_cry")
		_tick_one(visual, cry_times[i])
		_label(sheet, "war cry %d ms" % roundi(cry_times[i] * 1000.0), origin)
	await _frames(2)
	await _capture("skill_war_cry")
	sheet.free()
	# The ring at two moments, with allies at 150, 400 and 650 px flashing as it passes them.
	for age: float in [0.12, 0.3]:
		sheet = _blank_sheet()
		sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0) * 0.75
		var feet: Vector2 = Vector2(450.0, 760.0)
		var hero: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 150.0, feet)
		hero.play_state(&"war_cry")
		_tick_one(hero, 0.34)
		var ring: WarCryRing = WarCryRing.new()
		ring.setup(700.0, sheet.to_local(hero.mouth_global()) - feet, 1.0)
		ring.age = age
		ring.position = feet
		sheet.add_child(ring)
		for distance: float in [150.0, 400.0, 650.0]:
			var ally: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.ASHIGARU, 130.0, feet + Vector2(distance, 4.0))
			ally.play_state(&"idle")
			_tick_one(ally, 0.5)
			if WarCryRing.time_to_reach(distance, 700.0) < age:
				ally.flash_gold()
				_tick_one(ally, 1.0 / 60.0)
		await _frames(2)
		await _capture("skill_ring_%d" % roundi(age * 1000.0))
		sheet.free()


func _blank_sheet() -> Node2D:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	return sheet


func _label(sheet: Node2D, text: String, origin: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = origin + Vector2(-60.0, 24.0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", InkPalette.INK)
	sheet.add_child(label)


## The upgrade shop on each of its four tabs, with some gold, some levels bought and only the first two stages cleared
## (so the later allies are locked).
func _capture_upgrades() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 1280
	progress.xp = 140
	progress.stages_cleared = ["stage_1", "stage_2"] as Array[String]
	for pair: Array in [["samurai_max_health", 3], ["samurai_damage", 5], ["ashigaru_health", 2], ["spirit_regen", 1],
			["samurai_dash_cooldown", 2], ["army_command", 1], ["spirit_capacity", 4]]:
		progress.set_upgrade_level(pair[0], pair[1])
	SaveManager.new(DATA_DIR + "/upgrade_save.json").save_progress(progress)
	var menu: Node = load("res://scenes/upgrade_menu/upgrade_menu.tscn").instantiate()
	menu.set("save_path", DATA_DIR + "/upgrade_save.json")
	root.add_child(menu)
	await _frames(20)
	for tab: int in UpgradeTabs.NAMES.size():
		menu.call("select_tab", tab)
		await _frames(12)
		await _capture("upgrades_tab%d" % tab)
		if tab == UpgradeTabs.Tab.ALLIES:
			(menu.get_node("%Scroll") as ScrollContainer).scroll_vertical = 100000
			await _frames(8)
			await _capture("upgrades_tab2_locked")
	menu.free()


## The stage select with two stages cleared (so one card is open, two are locked), the boss card selected, then the
## second card selected (`--only=stages`; add --size=2341x1080 for the phone shape).
func _capture_stage_select() -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	progress.gold = 640
	progress.xp = 420
	progress.stages_cleared = ["stage_1", "stage_2"] as Array[String]
	SaveManager.new(DATA_DIR + "/stages_save.json").save_progress(progress)
	var select: Node = load("res://scenes/stage_select/stage_select.tscn").instantiate()
	select.set("save_path", DATA_DIR + "/stages_save.json")
	root.add_child(select)
	await _frames(20)
	await _capture("stages_default")
	select.get_stage_card(4).grab_focus()
	await _frames(12)
	await _capture("stages_boss_locked")
	select.get_stage_card(1).grab_focus()
	await _frames(12)
	await _capture("stages_open")
	select.free()


## The main menu on a fresh save (mid-entrance, then at rest) and on a save with two stages cleared, with a button
## focused (the crimson underline and the scale-up).
func _capture_main_menu() -> void:
	for state: String in ["fresh", "mid"]:
		var progress: PlayerProgress = PlayerProgress.new()
		progress.gold = 0 if state == "fresh" else 640
		progress.xp = 0 if state == "fresh" else 420
		if state == "mid":
			progress.stages_cleared = ["stage_1", "stage_2"] as Array[String]
			progress.last_stage_id = "stage_2"
		SaveManager.new(DATA_DIR + "/menu_save.json").save_progress(progress)
		var menu: Node = MAIN_MENU.instantiate()
		menu.set("save_path", DATA_DIR + "/menu_save.json")
		menu.set("settings_path", DATA_DIR + "/menu_settings.cfg")
		root.add_child(menu)
		if state == "fresh":
			await _frames(9)
			await _capture("mainmenu_intro")
		await _frames(50)
		if state == "mid":
			(menu.find_child("UpgradesButton", true, false) as Button).grab_focus()
			await _frames(25)
		await _capture("mainmenu_" + state)
		menu.free()


## One character kind alone in every state (`--only=kind:hatamoto`): idle, run, windup, strike (all three combo steps
## where they differ), cast, dash, hurt and dead, at 150 px, on a plain background.
func _capture_kind_sheet(kind_name: String) -> void:
	var kind: int = InkFigure.Kind.keys().find(kind_name.to_upper())
	if kind < 0:
		push_error("unknown kind '%s'" % kind_name)
		return
	var sheet: Node2D = _blank_sheet()
	var states: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"cast", &"dash", &"hurt", &"dead"]
	for i: int in states.size():
		var origin: Vector2 = Vector2(float(i % 5) * 380.0 + 190.0, float(i / 5) * 520.0 + 420.0)
		var visual: UnitVisual = _sheet_visual(sheet, kind as InkFigure.Kind, 170.0, origin)
		if _black:
			visual.set_tint(Color.BLACK)
		visual.play_state(&"idle")
		_tick_one(visual, 0.5)
		if states[i] == &"run":
			visual.play_state(&"run")
			_tick_one(visual, 0.25)
		elif states[i] != &"idle":
			visual.play_state(states[i])
			_tick_one(visual, 0.45)
		_label(sheet, "%s %s" % [kind_name, states[i]], origin)
	await _frames(2)
	await _capture("kind_" + kind_name)
	sheet.free()


## The samurai runs right for half a second at full speed, then stops dead: the scarf streams, the
## hakama and skirt swing back, and then everything overshoots forward and settles (secondary motion).
func _capture_samurai_run_strip() -> void:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	var times: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.58, 0.66, 0.74, 0.82, 0.9, 1.0]
	for i: int in times.size():
		var origin: Vector2 = Vector2(float(i % 6) * 320.0 + 110.0, float(i / 6) * 520.0 + 400.0)
		var t: float = times[i]
		# Run for 0.5 s at 210 px/s (3.5 px a frame), then stand still; it ends in its own cell.
		var run_time: float = minf(t, 0.5)
		var run_frames: int = roundi(run_time * 60.0)
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 150.0, origin - Vector2(3.5 * float(run_frames), 0.0))
		visual.play_state(&"idle")
		_tick_one(visual, 0.3)
		visual.play_state(&"run")
		for f: int in run_frames:
			visual.position.x += 3.5
			visual.call(&"_process", 1.0 / 60.0)
		if t > 0.5:
			visual.play_state(&"idle")
			_tick_one(visual, t - 0.5)
		var label: Label = Label.new()
		label.text = "%d ms" % roundi(t * 1000.0)
		label.position = origin + Vector2(-40.0, 24.0)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", InkPalette.INK)
		sheet.add_child(label)
	await _frames(2)
	await _capture("samurai_run_strip")
	sheet.free()


## Ticks a UnitVisual by `seconds` at 60 fps (it is not processed by the tree on the sheets).
func _tick_one(visual: UnitVisual, seconds: float) -> void:
	for i: int in ceili(seconds * 60.0 - 0.001):
		visual.call(&"_process", 1.0 / 60.0)


## Effects frozen at chosen moments: combo cuts and heavy slash, Oni slam, hit sparks, Spirit
## Slash, summon splash, portal smoke, death dissolve and dash afterimages.
func _capture_vfx_sheet() -> void:
	var sheet: Node2D = Node2D.new()
	sheet.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(sheet)
	var back: ColorRect = ColorRect.new()
	back.color = InkPalette.MIST.lerp(InkPalette.SKY_HORIZON, 0.5)
	back.size = Vector2(4000.0, 3000.0)
	back.position = Vector2(-100.0, -100.0)
	sheet.add_child(back)
	sheet.scale = Vector2.ONE * (float(root.size.y) / 1080.0)
	# Long setups first: combo cuts up to their final windup, the heavy and Oni windups.
	var strikers: Array[UnitVisual] = []
	for cut: int in 3:
		var visual: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 110.0, Vector2(180.0 + cut * 300.0, 330.0))
		for k: int in cut:
			visual.play_state(&"windup")
			_tick_tree(sheet, 0.12)
			visual.play_state(&"strike")
			_tick_tree(sheet, 0.12)
		strikers.append(visual)
	var heavy: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 110.0, Vector2(1080.0, 330.0))
	var oni: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.ONI_BRUTE, 190.0, Vector2(1560.0, 330.0))
	var dying: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.HOLLOW_SOLDIER, 110.0, Vector2(860.0, 980.0))
	var dasher: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.SAMURAI, 110.0, Vector2(1240.0, 980.0))
	for visual: UnitVisual in strikers:
		visual.play_state(&"windup")
	heavy.play_state(&"heavy_windup")
	oni.play_state(&"windup")
	dying.play_state(&"dead")
	_tick_tree(sheet, 0.4)
	var slash: SpiritSlashVisual = SpiritSlashVisual.new()
	slash.position = Vector2(1350.0, 600.0)
	sheet.add_child(slash)
	# Entrances need a moment to splash out.
	var ally: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.ASHIGARU, 100.0, Vector2(180.0, 980.0))
	ally.play_state(&"spawn")
	var hollow: UnitVisual = _sheet_visual(sheet, InkFigure.Kind.HOLLOW_SOLDIER, 110.0, Vector2(520.0, 980.0))
	hollow.play_state(&"spawn")
	_tick_tree(sheet, 0.1)
	# Short effects all at once, then a few frames.
	for visual: UnitVisual in strikers:
		visual.play_state(&"strike")
	heavy.play_state(&"strike")
	oni.play_state(&"strike")
	dasher.play_state(&"dash")
	var targets: Array[HitSpark.Target] = [HitSpark.Target.ENEMY, HitSpark.Target.DEFENDER, HitSpark.Target.STRUCTURE, HitSpark.Target.ENEMY]
	for i: int in targets.size():
		var spark: HitSpark = HitSpark.new()
		spark.setup(1.0 if i % 2 == 0 else -1.0, i == 1, i == 3, targets[i])
		spark.position = Vector2(180.0 + i * 260.0, 600.0)
		sheet.add_child(spark)
	for i: int in 5:
		dasher.position.x += 24.0
		_tick_tree(sheet, 1.0 / 60.0)
	await _frames(2)
	await _capture("vfx")
	sheet.free()


func _sheet_visual(sheet: Node2D, kind: InkFigure.Kind, height: float, at: Vector2) -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = kind
	visual.figure_height = height
	visual.position = at
	sheet.add_child(visual)
	return visual


## Advances every animated node under `node` by `seconds` at 60 fps (the sheet doesn't process).
func _tick_tree(node: Node, seconds: float) -> void:
	for i: int in ceili(seconds * 60.0 - 0.001):
		for child: Node in node.find_children("*", "", true, false):
			if is_instance_valid(child) and not child.is_queued_for_deletion() and child.has_method(&"_process") 					and (child is UnitVisual or child is InkEffect or child is Afterimage or child is SpiritSlashVisual):
				child.call(&"_process", 1.0 / 60.0)


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
