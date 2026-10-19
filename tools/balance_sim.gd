extends SceneTree
## Headless balance simulator: plays real battles with a scripted player and reports outcomes.
##   godot_console --headless --path . --fixed-fps 60 -s res://tools/balance_sim.gd -- <args>
## Args (after "--"):
##   stage=res://data/stages/stage_1.tres   stage to play (repeatable)
##   mode=bot|allies                          bot: scripted player fights + summons
##                                            allies: player stands still, only summons
##   runs=3                                   battles per stage/mode
##   upgrades=samurai_damage:2,ashigaru_health:1   upgrade levels for the run
##   curve      economy curve: plays every Region 1 stage in order with one persistent save,
##              retrying until a win (max `runs` attempts), replaying each cleared stage once,
##              and buying the cheapest upgrades after every battle
##   zero       plays every Region 1 stage once with no upgrades (difficulty spread)
## Uses its own save/settings under user://balance_sim (never the player's real save).
## The bot is a proxy for a reasonable player, not a perfect one: treat results as trends.

const SAVE_PATH: String = "user://balance_sim/save.json"
const SETTINGS_PATH: String = "user://balance_sim/settings.cfg"
const BATTLEFIELD: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const MAX_GAME_SECONDS: float = 900.0
const ENGAGE_LIMIT_X: float = 1450.0
const HOME_X: float = 450.0
const TAP_ACTIONS: Array[StringName] = [&"attack", &"heavy_attack", &"spirit_slash"]
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")


## Accumulates scaled game time (pauses with the world).
class Clock extends Node:
	var seconds: float = 0.0

	func _physics_process(delta: float) -> void:
		seconds += delta


var _pressed: Dictionary = {}
var _taps_this_frame: Array[StringName] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var stages: Array[String] = []
	var mode: String = "bot"
	var runs: int = 3
	var upgrades: Dictionary = {}
	var special: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("stage="):
			stages.append(arg.substr(6))
		elif arg.begins_with("mode="):
			mode = arg.substr(5)
		elif arg.begins_with("runs="):
			runs = int(arg.substr(5))
		elif arg.begins_with("upgrades="):
			for pair: String in arg.substr(9).split(",", false):
				var parts: PackedStringArray = pair.split(":")
				upgrades[parts[0]] = int(parts[1])
		elif arg == "curve" or arg == "zero":
			special = arg
	if special == "curve":
		await _run_curve(runs)
	elif special == "zero":
		for stage: StageData in StageProgression.default_region().stages:
			var result: Dictionary = await run_battle(stage, "bot", PlayerProgress.new())
			_print_summary(stage, "bot", {}, [result])
	if not special.is_empty():
		_cleanup_files()
		await AudioManager.shutdown_audio(self)
		quit()
		return
	if stages.is_empty():
		stages.append("res://data/stages/stage_1.tres")
	for stage_path: String in stages:
		var stage: StageData = load(stage_path) as StageData
		var results: Array[Dictionary] = []
		var start: PlayerProgress = PlayerProgress.new()
		for id: String in upgrades:
			start.set_upgrade_level(id, upgrades[id])
		for r: int in runs:
			results.append(await run_battle(stage, mode, start))
		_print_summary(stage, mode, upgrades, results)
	_cleanup_files()
	await AudioManager.shutdown_audio(self)
	quit()


## Plays one battle to the end starting from `progress` (written to the sim save first).
## Returns outcome metrics; "progress" holds the save after the battle (rewards, clears).
func run_battle(stage: StageData, mode: String, progress: PlayerProgress) -> Dictionary:
	SaveManager.new(SAVE_PATH).save_progress(progress)
	var settings: GameSettings = GameSettings.new()
	settings.touch_mode = GameSettings.TouchMode.OFF
	settings.screen_shake = false
	SettingsStore.new(SETTINGS_PATH).save_settings(settings)

	SceneRoutes.battle_stage = stage
	var field: Node = BATTLEFIELD.instantiate()
	field.set("save_path", SAVE_PATH)
	field.set("settings_path", SETTINGS_PATH)
	(field.get_node("World/WaveDirector") as WaveDirector).stage = stage
	var clock: Clock = Clock.new()
	field.get_node("World").add_child(clock)
	root.add_child(field)
	await process_frame

	var player: Player = field.get_node("World/Player")
	var gate: VillageGate = field.get_node("World/VillageGate")
	var summoner: SummonManager = field.get_node("World/SummonManager")
	var energy: SpiritEnergy = field.get_node("World/SpiritEnergy")
	var result_screen: ResultScreen = field.get_node("ResultScreen")
	var stats: Dictionary = {"player_deaths": 0, "allies_summoned": 0, "allies_lost": 0}
	player.died.connect(func() -> void: stats["player_deaths"] += 1)
	summoner.ally_summoned.connect(func(ally: Ally, _slot: int) -> void:
		stats["allies_summoned"] += 1
		ally.defeated.connect(func(_a: Ally) -> void: stats["allies_lost"] += 1))

	_pressed.clear()
	while not result_screen.visible and clock.seconds < MAX_GAME_SECONDS:
		await physics_frame
		if paused:
			continue
		_summon_policy(summoner, energy)
		if mode == "bot":
			_bot_step(player)
		_end_frame_inputs()
	_release_all()
	var outcome: Dictionary = {
		"victory": result_screen.visible and not gate.is_destroyed(),
		"timeout": not result_screen.visible,
		"seconds": clock.seconds,
		"gate_hp": gate.get_health().current_health / gate.get_health().max_health,
		"player_deaths": stats["player_deaths"],
		"allies_summoned": stats["allies_summoned"],
		"allies_lost": stats["allies_lost"],
	}
	var after: PlayerProgress = SaveManager.new(SAVE_PATH).load_progress()
	outcome["gold"] = after.gold - progress.gold
	outcome["progress"] = after
	field.free()
	paused = false
	Engine.time_scale = 1.0
	await process_frame
	return outcome


# --- Scripted player --------------------------------------------------------

## Summons whenever affordable, keeping roughly one archer per ashigaru.
func _summon_policy(summoner: SummonManager, energy: SpiritEnergy) -> void:
	var archers: int = 0
	var melee: int = 0
	for node: Node in get_nodes_in_group("allies"):
		var ally: Ally = node as Ally
		if ally != null:
			if ally.data.is_ranged:
				archers += 1
			else:
				melee += 1
	if energy.current >= 45.0 and archers < melee:
		summoner.request_summon(1)
	elif energy.current >= 30.0:
		summoner.request_summon(0)


## Walk to the nearest enemy, combo it, heavy attack Oni Brutes, Spirit Slash groups.
func _bot_step(player: Player) -> void:
	if player.is_dead():
		return
	var target: Enemy = null
	var best: float = INF
	var nearby: int = 0
	for node: Node in get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or enemy.is_dead() or enemy.global_position.x > ENGAGE_LIMIT_X:
			continue
		var distance: float = absf(enemy.global_position.x - player.global_position.x)
		if distance < 650.0:
			nearby += 1
		if distance < best:
			best = distance
			target = enemy
	var dx: float = (target.global_position.x if target != null else HOME_X) - player.global_position.x
	var toward: StringName = &"move_right" if dx > 0.0 else &"move_left"
	var away: StringName = &"move_left" if dx > 0.0 else &"move_right"
	_hold(away, false)
	if target == null:
		_hold(toward, absf(dx) > 30.0)
		return
	var facing_ok: bool = (dx > 0.0) == (player.facing > 0)
	_hold(toward, absf(dx) > 60.0 or not facing_ok)
	var cooldowns: Dictionary = player.get_ability_cooldowns()
	var is_oni: bool = target.data.headgear == UnitRig.Headgear.HORNS
	if best < 110.0 and facing_ok:
		if (cooldowns["heavy"] as Vector2).x <= 0.0 and (is_oni or randf() < 0.02):
			_tap(&"heavy_attack")
		elif Engine.get_physics_frames() % 6 == 0:
			_tap(&"attack")
	if facing_ok and (cooldowns["slash"] as Vector2).x <= 0.0 and (nearby >= 3 or (is_oni and best < 650.0)):
		_tap(&"spirit_slash")


func _hold(action: StringName, down: bool) -> void:
	if down and not _pressed.get(action, false):
		Input.action_press(action)
		_pressed[action] = true
	elif not down and _pressed.get(action, false):
		Input.action_release(action)
		_pressed[action] = false


## A tap is held for exactly one physics frame.
func _tap(action: StringName) -> void:
	if not _pressed.get(action, false):
		Input.action_press(action)
		_pressed[action] = true
		_taps_this_frame.append(action)


func _end_frame_inputs() -> void:
	for action: StringName in TAP_ACTIONS:
		if _pressed.get(action, false) and not _taps_this_frame.has(action):
			Input.action_release(action)
			_pressed[action] = false
	_taps_this_frame.clear()


func _release_all() -> void:
	for action: StringName in _pressed:
		Input.action_release(action)
	_pressed.clear()
	_taps_this_frame.clear()


# --- Economy curve ----------------------------------------------------------

func _run_curve(max_attempts: int) -> void:
	var progress: PlayerProgress = PlayerProgress.new()
	print("stage    | try | result  | gate | deaths | gold earned | upgrades bought | levels owned | gold left")
	for stage: StageData in StageProgression.default_region().stages:
		var attempts: int = 0
		var replayed: bool = false
		while attempts < max_attempts:
			attempts += 1
			var result: Dictionary = await run_battle(stage, "bot", progress)
			progress = result["progress"]
			var bought: int = _buy_cheapest(progress)
			print("%-8s | %3d | %-7s | %3.0f%% | %6d | %11d | %15d | %12d | %d" % [stage.stage_id, attempts,
					"WIN" if result["victory"] else ("TIMEOUT" if result["timeout"] else "LOSS"),
					result["gate_hp"] * 100.0, result["player_deaths"], result["gold"], bought, _owned(progress), progress.gold])
			if result["victory"]:
				if replayed:
					break
				replayed = true
		if not progress.is_stage_cleared(stage.stage_id):
			print("  stuck on %s after %d attempts" % [stage.stage_id, max_attempts])
			return


func _buy_cheapest(progress: PlayerProgress) -> int:
	var bought: int = 0
	while true:
		var cheapest: UpgradeData = null
		for upgrade: UpgradeData in CATALOG.upgrades:
			var level: int = progress.get_upgrade_level(upgrade.id)
			if upgrade.is_maxed(level):
				continue
			if cheapest == null or upgrade.get_cost(level) < cheapest.get_cost(progress.get_upgrade_level(cheapest.id)):
				cheapest = upgrade
		if cheapest == null or UpgradeShop.purchase(progress, cheapest) != UpgradeShop.Result.OK:
			return bought
		bought += 1
	return bought


func _owned(progress: PlayerProgress) -> int:
	var total: int = 0
	for upgrade: UpgradeData in CATALOG.upgrades:
		total += progress.get_upgrade_level(upgrade.id)
	return total


# --- Output -----------------------------------------------------------------

func _print_summary(stage: StageData, mode: String, upgrades: Dictionary, results: Array[Dictionary]) -> void:
	var wins: int = 0
	var gate: float = 0.0
	var seconds: float = 0.0
	var deaths: float = 0.0
	var summoned: float = 0.0
	var lost: float = 0.0
	for r: Dictionary in results:
		wins += 1 if r["victory"] else 0
		gate += r["gate_hp"]
		seconds += r["seconds"]
		deaths += r["player_deaths"]
		summoned += r["allies_summoned"]
		lost += r["allies_lost"]
	var n: float = results.size()
	print("%s | mode=%s | upgrades=%s | wins %d/%d | gate left avg %3.0f%% | time avg %3.0fs | player deaths avg %.1f | allies summoned %.1f, lost %.1f" % [
		stage.stage_id, mode, str(upgrades) if not upgrades.is_empty() else "none", wins, results.size(),
		gate / n * 100.0, seconds / n, deaths / n, summoned / n, lost / n])
	for r: Dictionary in results:
		print("    %s gate %3.0f%%  %3.0fs  deaths %d  allies lost %d/%d" % [
			"WIN " if r["victory"] else ("TIME" if r["timeout"] else "LOSS"), r["gate_hp"] * 100.0, r["seconds"],
			r["player_deaths"], r["allies_lost"], r["allies_summoned"]])


func _cleanup_files() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp", SETTINGS_PATH, SETTINGS_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://balance_sim"))
