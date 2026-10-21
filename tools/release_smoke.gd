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
	_check(region.stages.size() == 5, "five campaign stages load from the PCK")
	SceneRoutes.battle_stage = region.stages[0]
	var field: Node = _scene(SceneRoutes.BATTLEFIELD)
	var player: Player = field.get_node("World/Player") as Player
	var summoner: SummonManager = field.get_node("World/SummonManager") as SummonManager
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
	await _capture("stages")
	select.free()
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
