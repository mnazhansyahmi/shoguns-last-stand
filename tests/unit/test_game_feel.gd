extends "res://tests/test_case.gd"
## Phase 7: sound effects, hit-stop, screen shake, damage numbers, vibration rules, balance.

const LIBRARY: SfxLibrary = preload("res://data/audio/sfx_library.tres")
const REQUIRED_SFX: Array[StringName] = [&"sword_swing", &"hit", &"heavy_hit", &"dash", &"spirit_slash",
		&"summon", &"enemy_death", &"gate_hit", &"victory", &"defeat", &"button_click"]
const STAGE_1: StageData = preload("res://data/stages/stage_1.tres")
const CATALOG: UpgradeCatalog = preload("res://data/upgrades/upgrade_catalog.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")


func cleanup() -> void:
	Engine.time_scale = 1.0
	super.cleanup()


func _audio() -> AudioManager:
	if is_instance_valid(AudioManager.instance):
		return AudioManager.instance
	return add_to_tree(AudioManager.new()) as AudioManager


func _feedback(shake: bool = true) -> BattleFeedback:
	var feedback: BattleFeedback = BattleFeedback.new()
	feedback.numbers_parent = add_to_tree(Node2D.new())
	var settings: GameSettings = GameSettings.new()
	settings.screen_shake = shake
	add_to_tree(feedback)
	feedback.configure(settings)
	return feedback


func _hit(damage: float, heavy: bool, killed: bool) -> HitData:
	var hit: HitData = HitData.new(damage, Vector2.ZERO, null)
	hit.heavy = heavy
	hit.killed = killed
	return hit


# --- Sound ------------------------------------------------------------------

func test_every_required_sound_has_a_file() -> void:
	for id: StringName in REQUIRED_SFX:
		var entry: SfxEntry = LIBRARY.find(id)
		assert_true(entry != null and entry.stream != null, "library has a stream for %s" % id)
		assert_true(FileAccess.file_exists("res://assets/audio/sfx/%s.wav" % id), "%s.wav exists" % id)


func test_audio_manager_plays_on_sfx_bus() -> void:
	var manager: AudioManager = _audio()
	assert_true(manager.play_sfx(&"victory"), "known sound plays")
	assert_eq(manager.last_played, &"victory", "last played recorded")
	for player: Node in manager.get_children():
		if player is AudioStreamPlayer:
			assert_eq((player as AudioStreamPlayer).bus, &"SFX", "players use the SFX bus (volume setting)")
	assert_true(not manager.play_sfx(&"no_such_sound"), "unknown sound rejected")
	# Earlier tests may have just played "defeat"; wait out its repeat throttle.
	OS.delay_msec(int(LIBRARY.find(&"defeat").min_interval * 1000.0) + 20)
	assert_true(AudioManager.play(&"defeat"), "static helper reaches the manager")


func test_rapid_repeats_are_throttled() -> void:
	var manager: AudioManager = _audio()
	OS.delay_msec(60)
	assert_true(manager.play_sfx(&"hit"), "first hit plays")
	assert_true(not manager.play_sfx(&"hit"), "same sound in the same instant is skipped")
	OS.delay_msec(60)
	assert_true(manager.play_sfx(&"hit"), "plays again after its minimum interval")


func test_buttons_click() -> void:
	var manager: AudioManager = _audio()
	OS.delay_msec(60)
	var button: Button = add_to_tree(Button.new()) as Button
	var before: int = manager.play_count
	button.pressed.emit()
	assert_eq(manager.last_played, &"button_click", "pressing any button plays the click")
	assert_eq(manager.play_count, before + 1, "exactly one sound")


# --- Hit-stop, shake, damage numbers ----------------------------------------

func test_heavy_hits_and_kills_trigger_hit_stop() -> void:
	var feedback: BattleFeedback = _feedback()
	var victim: Node2D = add_to_tree(Node2D.new())
	feedback.handle_hit(victim, Vector2.ZERO, _hit(20.0, false, false))
	assert_true(not feedback.is_hit_stopped() and is_equal_approx(Engine.time_scale, 1.0), "light hit: no freeze")
	feedback.handle_hit(victim, Vector2.ZERO, _hit(50.0, true, false))
	assert_true(feedback.is_hit_stopped() and Engine.time_scale < 0.1, "heavy hit freezes the game")
	feedback.end_hit_stop()
	feedback.handle_hit(victim, Vector2.ZERO, _hit(20.0, false, true))
	assert_true(feedback.is_hit_stopped(), "kill freezes the game")


func test_hit_stop_ends_after_about_50ms() -> void:
	var feedback: BattleFeedback = _feedback()
	feedback.hit_stop(BattleFeedback.HIT_STOP_SECONDS)
	feedback._process(0.0)
	assert_true(feedback.is_hit_stopped(), "still frozen immediately")
	OS.delay_msec(int(BattleFeedback.HIT_STOP_SECONDS * 1000.0) + 20)
	feedback._process(0.0)
	assert_true(not feedback.is_hit_stopped() and is_equal_approx(Engine.time_scale, 1.0), "time restored after ~50 ms")


func test_leaving_the_battle_never_keeps_the_freeze() -> void:
	var feedback: BattleFeedback = _feedback()
	feedback.hit_stop(5.0)
	feedback.free()
	assert_almost_eq(Engine.time_scale, 1.0, "freeing the feedback node restores time scale")
	assert_true(BattleFeedback.active == null, "no stale active feedback")


func test_heavy_hit_shake_respects_setting() -> void:
	var off: BattleFeedback = _feedback(false)
	off.handle_hit(add_to_tree(Node2D.new()), Vector2.ZERO, _hit(50.0, true, false))
	assert_true(not off.is_shaking(), "no shake when screen shake is off")
	off.free()
	var on: BattleFeedback = _feedback(true)
	on.handle_hit(add_to_tree(Node2D.new()), Vector2.ZERO, _hit(50.0, true, false))
	assert_true(on.is_shaking(), "heavy hit shakes when screen shake is on")


func test_damage_numbers_spawn_and_expire() -> void:
	var feedback: BattleFeedback = _feedback()
	var number: DamageNumber = feedback.spawn_damage_number(Vector2(100.0, 200.0), _hit(49.6, true, false), true)
	assert_true(number != null, "damage number spawned")
	assert_eq(number.text, "50!", "rounded damage, ! for heavy")
	assert_eq(number.color, BattleFeedback.HEAVY_DAMAGE_COLOR, "heavy hits on enemies are orange")
	var light: DamageNumber = feedback.spawn_damage_number(Vector2.ZERO, _hit(12.0, false, false), false)
	assert_eq(light.color, BattleFeedback.DEFENDER_DAMAGE_COLOR, "damage to defenders is red")
	var start_y: float = number.position.y
	number._process(DamageNumber.LIFETIME * 0.5)
	assert_true(number.position.y < start_y, "number floats up")
	number._process(DamageNumber.LIFETIME)
	assert_true(number.is_queued_for_deletion(), "number frees itself after its lifetime")


func test_hurtbox_reports_heavy_and_kill_flags() -> void:
	var feedback: BattleFeedback = _feedback()
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	var hurtbox: HurtboxComponent = enemy.get_node("Hurtbox")
	var received: Array[HitData] = []
	hurtbox.hit_received.connect(func(hit: HitData) -> void: received.append(hit))
	var hitbox: HitboxComponent = HitboxComponent.new()
	add_to_tree(hitbox)
	hitbox.activate(20.0, 0.0, 1.0, true)
	hitbox.try_hit(hurtbox)
	hitbox.activate(500.0, 0.0, 1.0, false)
	hitbox.try_hit(hurtbox)
	assert_eq(received.size(), 2, "two hits received")
	if received.size() == 2:
		assert_true(received[0].heavy and not received[0].killed, "first hit heavy, not lethal")
		assert_true(not received[1].heavy and received[1].killed, "second hit lethal")
	assert_eq(feedback.numbers_parent.get_child_count(), 2, "each hit reported to the battle feedback")


func test_vibration_needs_setting_and_phone() -> void:
	assert_true(BattleFeedback.can_vibrate(true, true), "setting on + phone: vibrate")
	assert_true(not BattleFeedback.can_vibrate(false, true), "setting off: never")
	assert_true(not BattleFeedback.can_vibrate(true, false), "desktop: never")


# --- Balance ----------------------------------------------------------------

## Simulates repeated full stage-1 clears, buying the cheapest available upgrade each time.
func test_stage_clear_buys_about_two_upgrades() -> void:
	var kills: Array[EnemyData] = []
	for i: int in 16:
		kills.append(HOLLOW_SOLDIER)
	kills.append(ONI_BRUTE)
	var clear_gold: int = RewardCalculator.calculate(kills, STAGE_1, true).gold
	var progress: PlayerProgress = PlayerProgress.new()
	var per_clear: Array[int] = []
	var total_levels: int = 0
	for upgrade: UpgradeData in CATALOG.upgrades:
		total_levels += upgrade.max_level
	while per_clear.size() < 100:
		progress.gold += clear_gold
		var bought: int = 0
		while true:
			var cheapest: UpgradeData = null
			for upgrade: UpgradeData in CATALOG.upgrades:
				var level: int = progress.get_upgrade_level(upgrade.id)
				if not upgrade.is_maxed(level) and (cheapest == null or upgrade.get_cost(level) < cheapest.get_cost(progress.get_upgrade_level(cheapest.id))):
					cheapest = upgrade
			if cheapest == null or UpgradeShop.purchase(progress, cheapest) != UpgradeShop.Result.OK:
				break
			bought += 1
		per_clear.append(bought)
		var owned: int = 0
		for upgrade: UpgradeData in CATALOG.upgrades:
			owned += progress.get_upgrade_level(upgrade.id)
		if owned >= total_levels:
			break
	var average: float = float(total_levels) / per_clear.size()
	assert_true(per_clear[0] >= 2, "first clear buys at least 2 upgrades (bought %d)" % per_clear[0])
	assert_true(average >= 1.7 and average <= 2.4,
			"about 2 upgrades per clear over the whole progression (%.2f over %d clears)" % [average, per_clear.size()])
