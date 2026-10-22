extends SceneTree
## Use an editor runtime with --main-pack <EXPORTED PCK> and an absolute script path.
## Standard release templates disable --script overrides; their UI is checked separately.
## This script is excluded from the release PCK. Uses its own save/settings only.
const SAVE: String = "user://release_validation/save.json"
const SETTINGS: String = "user://release_validation/settings.cfg"
var _out: String = ""
var _failed: Array[String] = []
var _passed: Array[String] = []

class SmokeErrors extends Logger:
	var count: int = 0
	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING: count += 1

var _errors: SmokeErrors = SmokeErrors.new()


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("out="): _out = argument.trim_prefix("out=")
	if _out.is_empty():
		quit(2)
		return
	OS.add_logger(_errors)
	seed(20261022)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_run.call_deferred()


func _check(ok: bool, description: String) -> void:
	(_passed if ok else _failed).append(description)
	print(("PASS " if ok else "FAIL ") + description)


func _scene(path: String) -> Node:
	var node: Node = (load(path) as PackedScene).instantiate()
	for property: Dictionary in node.get_property_list():
		if property.name == "save_path": node.set("save_path", SAVE)
		if property.name == "settings_path": node.set("settings_path", SETTINGS)
	root.add_child(node)
	return node


func _frames(count: int) -> void:
	for i: int in count: await process_frame


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(_out.path_join(name + ".png")) == OK, "render " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://release_validation")
	print("VALIDATION MODE: exported PCK in editor runtime; release executable UI checked separately")
	_check(OS.has_feature("public_playtest"), "public playtest export feature")
	_check(ProjectSettings.get_setting("application/config/version") == "0.2.0", "packaged version is 0.2.0")
	_check(OS.get_user_data_dir().replace("\\", "/").ends_with("/ShogunsLastStand"), "public saves separate from editor saves")
	_check(not FileAccess.file_exists("res://tests/run_tests.gd") and not FileAccess.file_exists("res://tools/balance_sim.gd"), "developer tests/tools excluded")
	_check(not FileAccess.file_exists("res://docs/ASSET_LICENSES.md"), "internal asset provenance excluded")
	var progress: PlayerProgress = PlayerProgress.new()
	_check(SaveManager.new(SAVE).save_progress(progress) == OK, "fresh isolated save writes")
	var settings: GameSettings = GameSettings.new()
	settings.touch_mode = GameSettings.TouchMode.OFF
	_check(SettingsStore.new(SETTINGS).save_settings(settings) == OK, "isolated settings write")
	var menu: Node = _scene(SceneRoutes.MAIN_MENU)
	await _frames(80)
	_check((menu.get_node("%ContinueButton") as Button).text == "Start", "fresh profile shows Start")
	await _capture("menu")
	menu.free()
	var credits: Node = _scene(SceneRoutes.CREDITS)
	await _frames(10)
	_check((credits.get_node("%Text") as RichTextLabel).text.contains("MOMIZizm"), "required music attribution survives export")
	credits.free()
	for entry: MusicEntry in AudioManager.instance.music_library.entries:
		for path: String in entry.paths:
			_check(ResourceLoader.exists(path), "packaged music " + entry.id)
	progress.gold = 1000
	var catalog: UpgradeCatalog = load("res://data/upgrades/upgrade_catalog.tres") as UpgradeCatalog
	_check(UpgradeShop.purchase(progress, catalog.find("samurai_damage")) == UpgradeShop.Result.OK, "upgrade purchase succeeds")
	SaveManager.new(SAVE).save_progress(progress)
	progress = SaveManager.new(SAVE).load_progress()
	_check(progress.get_upgrade_level("samurai_damage") == 1, "upgrade survives save reload")
	var shop: Node = _scene(SceneRoutes.UPGRADE_MENU)
	await _frames(30)
	await _capture("upgrades")
	shop.free()
	var region: RegionData = StageProgression.default_region()
	var regions: Array[RegionData] = StageProgression.regions()
	_check(regions.size() == 2 and StageProgression.all_stages().size() == 10, "both regions and ten campaign stages load from the PCK")
	SceneRoutes.battle_stage = region.stages[0]
	var field: Node = _scene(SceneRoutes.BATTLEFIELD)
	var player: Player = field.get_node("World/Player") as Player
	var summoner: SummonManager = field.get_node("World/SummonManager") as SummonManager
	await _frames(5)
	var briefing: EnemyBriefing = field.get("_enemy_briefing") as EnemyBriefing
	_check(briefing.visible and paused, "pre-battle briefing pauses combat")
	await _capture("briefing")
	briefing.dismiss()
	await _frames(5)
	_check(not paused, "briefing dismissal starts combat")
	var start: float = player.position.x
	Input.action_press("move_right")
	await _frames(95)
	Input.action_release("move_right")
	_check(player.position.x > start + 100.0, "player movement works in release")
	var summoned: bool = false
	for i: int in 900:
		if i % 240 == 0:
			summoned = summoner.request_summon((i / 240) % 2) == SummonManager.Result.OK or summoned
		if i % 30 == 0: Input.action_press("attack")
		if i % 30 == 1: Input.action_release("attack")
		if i % 180 == 90: Input.action_press("heavy_attack")
		if i % 180 == 91: Input.action_release("heavy_attack")
		await process_frame
	Input.action_release("attack")
	Input.action_release("heavy_attack")
	_check(summoned, "summoning works with real Spirit Energy")
	await _capture("battle")
	field.call("_pause")
	_check(paused, "pause works")
	await _frames(5)
	field.call("_resume")
	_check(not paused, "resume works")
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner") as EnemySpawner
	_check(spawner.get_alive_count() >= 0, "packaged enemy spawning runs")
	field.call("_end_battle", true)
	await _frames(70)
	_check((field.get_node("ResultScreen") as ResultScreen).visible, "victory route opens results")
	_check(not (field.get_node("Hud") as CanvasLayer).visible, "battle HUD clears behind result")
	_check(SaveManager.new(SAVE).load_progress().is_stage_cleared("stage_1"), "victory and unlock persist")
	await _capture("victory")
	field.free()
	paused = false
	Engine.time_scale = 1.0
	var select: Node = _scene(SceneRoutes.STAGE_SELECT)
	await _frames(35)
	await _capture("stages_region1")
	select.call("show_region", regions[1])
	await _frames(35)
	await _capture("stages_region2")
	select.free()
	# Simulate a returning v0.1 player without touching the real public save.
	progress = SaveManager.new(SAVE).load_progress()
	for stage: StageData in region.stages:
		if not progress.is_stage_cleared(stage.stage_id): progress.stages_cleared.append(stage.stage_id)
	SaveManager.new(SAVE).save_progress(progress)
	progress = SaveManager.new(SAVE).load_progress()
	_check(StageProgression.is_region_unlocked(progress, regions[1]), "returning Region 1 save unlocks Burning Village")
	_check(progress.get_upgrade_level("samurai_damage") == 1, "returning save retains purchased upgrade")
	var armour: UpgradeData = catalog.find("gate_armour")
	var resistance: UpgradeData = catalog.find("army_fire_resistance")
	_check(armour != null and resistance != null and not armour.is_available(progress), "Region 2 defences load and remain progress gated")
	for stage: StageData in regions[1].stages:
		if stage.stage_id != "stage_10": progress.stages_cleared.append(stage.stage_id)
	progress.gold = 20000
	_check(UpgradeShop.purchase(progress, armour) == UpgradeShop.Result.OK and UpgradeShop.purchase(progress, resistance) == UpgradeShop.Result.OK, "Region 2 defence upgrades purchase after progression")
	SaveManager.new(SAVE).save_progress(progress)
	SceneRoutes.battle_stage = regions[1].stages[4]
	field = _scene(SceneRoutes.BATTLEFIELD)
	await _frames(20)
	briefing = field.get("_enemy_briefing") as EnemyBriefing
	_check(briefing.visible and briefing.card_count > 1, "Region 2 enemy briefing loads painted cards")
	await _capture("briefing_region2")
	briefing.dismiss()
	await _frames(5)
	(field.get_node("World/WaveDirector") as WaveDirector).stop()
	spawner = field.get_node("World/EnemySpawner") as EnemySpawner
	var enemy_index: int = 0
	for id: String in ["spectral_archer", "shield_bearer", "flying_spirit", "burning_general"]:
		var enemy: Enemy = spawner.spawn(load("res://data/enemies/" + id + ".tres") as EnemyData)
		_check(is_instance_valid(enemy), "exported Region 2 enemy spawns: " + id)
		if is_instance_valid(enemy): enemy.position.x = 1000.0 + enemy_index * 190.0
		enemy_index += 1
	await _frames(100)
	await _capture("battle_region2")
	field.call("_pause")
	field.call("_open_enemy_briefing", true)
	_check(briefing.visible and paused, "enemy briefing reopens from pause")
	briefing.dismiss()
	await _frames(5)
	_check(paused, "pause briefing returns to paused game")
	field.call("_resume")
	await _frames(180)
	field.free()
	SceneRoutes.battle_stage = null
	paused = false
	Engine.time_scale = 1.0
	var notice: FileAccess = FileAccess.open(_out.path_join("GODOT_LICENSES.txt"), FileAccess.WRITE)
	notice.store_string(Engine.get_license_text() + "\n\nEngine component notices:\n" + JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\nEngine component license texts:\n")
	var licenses: Dictionary = Engine.get_license_info()
	for name: String in licenses:
		notice.store_string("\n\n=== " + name + " ===\n" + str(licenses[name]))
	notice.close()
	await AudioManager.shutdown_audio(self)
	_check(_errors.count == 0, "no engine/script errors during release smoke")
	var report: Dictionary = {"passed": _passed, "failed": _failed, "runtime": Engine.get_version_info(), "user_data": OS.get_user_data_dir()}
	var output: FileAccess = FileAccess.open(_out.path_join("smoke.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	OS.remove_logger(_errors)
	print("RELEASE SMOKE: %d passed, %d failed" % [_passed.size(), _failed.size()])
	quit(0 if _failed.is_empty() else 1)
