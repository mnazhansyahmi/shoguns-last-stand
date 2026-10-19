extends "res://tests/test_case.gd"
## The Ultimate: the charge meter, the skill (area hit, dramatic pause, invulnerable samurai),
## the key and touch button, the HUD bar and the real-time brush sweep.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const TOUCH_SCENE: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const ASHIGARU: AllyData = preload("res://data/allies/ashigaru.tres")
const STEP: float = 1.0 / 60.0


func cleanup() -> void:
	Input.action_release(&"ultimate")
	Engine.time_scale = 1.0
	super.cleanup()


func _meter() -> UltimateMeter:
	var meter: UltimateMeter = add_to_tree(UltimateMeter.new()) as UltimateMeter
	return meter


func _enemy(x: float, data: EnemyData = HOLLOW_SOLDIER) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(data)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	return enemy


func _health_of(unit: Node) -> HealthComponent:
	return unit.get_node("HealthComponent") as HealthComponent


## A samurai with a full meter and a skill wired to both (no camera: it strikes 950 px each side
## of him).
func _ready_skill() -> Dictionary:
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	player.global_position = Vector2(500.0, 880.0)
	var meter: UltimateMeter = _meter()
	meter.configure(player.stats)
	var skill: UltimateSkill = add_to_tree(UltimateSkill.new()) as UltimateSkill
	skill.setup(player, null, meter)
	meter.add_charge(meter.max_charge)
	return {"player": player, "meter": meter, "skill": skill}


func _tick_player(player: Player, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		player._physics_process(STEP)


# --- Meter ----------------------------------------------------------------------

func test_meter_fills_from_damage_dealt_and_taken() -> void:
	var meter: UltimateMeter = _meter()
	assert_almost_eq(meter.get_ratio(), 0.0, "starts empty")
	meter.add_damage_dealt(100.0)
	assert_almost_eq(meter.current, 100.0 * meter.per_damage_dealt, "damage the samurai deals charges it")
	var after_dealt: float = meter.current
	meter.add_damage_taken(20.0)
	assert_almost_eq(meter.current - after_dealt, 20.0 * meter.per_damage_taken, "damage he takes charges it")
	var before_ally: float = meter.current
	meter.add_damage_dealt(100.0, true)
	assert_almost_eq(meter.current - before_ally, 100.0 * meter.per_damage_dealt * meter.ally_share, "allies' damage counts for a share")
	assert_true(meter.ally_share < 1.0 and meter.per_damage_taken > meter.per_damage_dealt,
			"taking damage is rewarded more per point than dealing it, and allies less")


func test_meter_caps_signals_ready_once_and_consumes() -> void:
	var meter: UltimateMeter = _meter()
	var ready_count: Array[int] = [0]
	var used_count: Array[int] = [0]
	meter.became_ready.connect(func() -> void: ready_count[0] += 1)
	meter.used.connect(func() -> void: used_count[0] += 1)
	meter.add_charge(meter.max_charge * 0.6)
	assert_true(not meter.is_ready() and not meter.try_consume(), "not ready at 60% and cannot be spent")
	assert_almost_eq(meter.current, meter.max_charge * 0.6, "a failed spend takes nothing")
	meter.add_charge(meter.max_charge)
	meter.add_charge(50.0)
	assert_true(meter.is_ready(), "full")
	assert_almost_eq(meter.get_ratio(), 1.0, "capped at full")
	assert_eq(ready_count[0], 1, "became_ready fires once, not on every extra hit")
	assert_true(meter.try_consume(), "a full meter can be spent")
	assert_almost_eq(meter.get_ratio(), 0.0, "and is then empty")
	assert_eq(used_count[0], 1, "used fires once")


func test_locked_meter_gains_nothing() -> void:
	var meter: UltimateMeter = _meter()
	meter.locked = true
	meter.add_damage_dealt(1000.0)
	meter.add_damage_taken(1000.0)
	assert_almost_eq(meter.current, 0.0, "a locked meter ignores damage")


func test_meter_takes_its_tuning_from_the_samurai_stats() -> void:
	var stats: PlayerStats = PlayerStats.new()
	stats.ultimate_charge_max = 50.0
	stats.ultimate_charge_per_damage_dealt = 0.5
	stats.ultimate_charge_per_damage_taken = 1.0
	stats.ultimate_ally_share = 0.2
	var meter: UltimateMeter = _meter()
	meter.configure(stats)
	meter.add_damage_dealt(10.0)
	assert_almost_eq(meter.current, 5.0, "dealt rate comes from the stats")
	meter.add_damage_dealt(10.0, true)
	assert_almost_eq(meter.current, 6.0, "ally share comes from the stats")
	meter.add_damage_taken(44.0)
	assert_true(meter.is_ready(), "50 charge is full after the stats' rates")


# --- Skill ----------------------------------------------------------------------

func test_ultimate_key_is_i() -> void:
	assert_true(InputMap.has_action(&"ultimate"), "the ultimate action exists")
	var found: bool = false
	for event: InputEvent in InputMap.action_get_events(&"ultimate"):
		var key: InputEventKey = event as InputEventKey
		if key != null and key.physical_keycode == KEY_I:
			found = true
	assert_true(found, "and is bound to I")


func test_cannot_use_ultimate_until_charged() -> void:
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	var meter: UltimateMeter = _meter()
	meter.configure(player.stats)
	var skill: UltimateSkill = add_to_tree(UltimateSkill.new()) as UltimateSkill
	skill.setup(player, null, meter)
	var reported: Array[float] = [-1.0]
	skill.not_ready.connect(func(ratio: float) -> void: reported[0] = ratio)
	meter.add_charge(meter.max_charge * 0.4)
	assert_eq(skill.request(), UltimateSkill.Result.NOT_READY, "refused at 40%")
	assert_almost_eq(reported[0], 0.4, "and says how charged it is")
	assert_eq(player.get_state_name(), "IDLE", "the samurai does nothing")
	assert_almost_eq(meter.get_ratio(), 0.4, "the charge is kept")


func test_ultimate_hits_every_enemy_in_range_once_and_empties_the_meter() -> void:
	var setup: Dictionary = _ready_skill()
	var player: Player = setup["player"]
	var meter: UltimateMeter = setup["meter"]
	var skill: UltimateSkill = setup["skill"]
	var near: Enemy = _enemy(900.0)
	var far_right: Enemy = _enemy(1400.0)
	var behind: Enemy = _enemy(150.0)
	var out_of_range: Enemy = _enemy(1700.0)
	var oni: Enemy = _enemy(1000.0, ONI_BRUTE)
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ASHIGARU, 700.0)
	add_to_tree(ally)
	ally.global_position = Vector2(700.0, 880.0)
	var hits: Array[int] = [-1]
	skill.released.connect(func(count: int) -> void: hits[0] = count)

	assert_eq(skill.request(), UltimateSkill.Result.OK, "a full meter starts the ultimate")
	assert_eq(player.get_state_name(), "ULTIMATE", "the samurai is casting")
	assert_almost_eq(meter.get_ratio(), 0.0, "the meter is emptied at once")
	assert_eq(hits[0], -1, "nothing is hit while the blade is still going up")
	assert_eq(_health_of(near).current_health, HOLLOW_SOLDIER.max_health, "enemies are untouched during the wind-up")

	_tick_player(player, player.stats.ultimate_windup + 0.02)
	assert_eq(hits[0], 4, "it hit the four enemies in range (two soldiers ahead, one behind, the Oni)")
	var damage: float = player.stats.base_damage * player.stats.ultimate_damage_multiplier
	assert_true(near.is_dead() and far_right.is_dead() and behind.is_dead(), "soldiers die to a 9x hit (%.0f damage)" % damage)
	assert_almost_eq(_health_of(oni).current_health, ONI_BRUTE.max_health - damage, "the Oni takes the same damage and survives")
	assert_eq(_health_of(out_of_range).current_health, HOLLOW_SOLDIER.max_health, "an enemy beyond the strike range is untouched")
	assert_eq(_health_of(ally).current_health, ASHIGARU.max_health, "allies are never hurt by it")
	assert_almost_eq(meter.get_ratio(), 0.0, "the sweep's own hits do not refill the meter")
	assert_true(not meter.locked, "and the meter is unlocked again afterwards")


func test_ultimate_is_a_panic_button_and_cannot_be_hurt_or_repeated() -> void:
	var setup: Dictionary = _ready_skill()
	var player: Player = setup["player"]
	var meter: UltimateMeter = setup["meter"]
	var skill: UltimateSkill = setup["skill"]
	# Mid-combo, the samurai can still call it. (Tests share one frame, so start the attack directly
	# rather than through the Input Map, whose "just pressed" state would leak between tests.)
	player.call("_start_attack", player.stats.get_combo()[0], false, 0.0)
	assert_eq(player.get_state_name(), "ATTACK", "he is mid-attack")
	assert_eq(skill.request(), UltimateSkill.Result.OK, "the ultimate cancels an attack")
	assert_true(player.get_health().is_invulnerable(), "he cannot be hurt during the move")
	var before: float = player.get_health().current_health
	assert_eq(player.get_health().take_damage(50.0), 0.0, "damage is ignored while it plays")
	assert_eq(player.get_health().current_health, before, "his health is unchanged")
	meter.add_charge(meter.max_charge)
	assert_eq(skill.request(), UltimateSkill.Result.CANNOT_ACT, "it cannot be started again while it plays")
	# Step until the move ends (not beyond: a leaked "just pressed" from another test could start an action).
	var frames: int = 0
	while player.get_state_name() == "ULTIMATE" and frames < 200:
		player._physics_process(STEP)
		frames += 1
	assert_eq(player.get_state_name(), "IDLE", "he recovers to idle afterwards")
	assert_true(float(frames) * STEP >= player.stats.ultimate_windup + player.stats.ultimate_recovery - STEP,
			"after the wind-up and the recovery (%d frames)" % frames)


func test_dead_samurai_cannot_use_the_ultimate() -> void:
	var setup: Dictionary = _ready_skill()
	var player: Player = setup["player"]
	var skill: UltimateSkill = setup["skill"]
	player.get_health().take_damage(10000.0)
	assert_eq(skill.request(), UltimateSkill.Result.CANNOT_ACT, "a fallen samurai cannot cast it")
	assert_true(setup["meter"].is_ready(), "and the charge is kept for when he is back")


func test_strike_range_follows_the_screen_when_there_is_a_camera() -> void:
	var setup: Dictionary = _ready_skill()
	var skill: UltimateSkill = setup["skill"]
	var camera: BattleCamera = add_to_tree(BattleCamera.new()) as BattleCamera
	camera.position = Vector2(1000.0, 880.0)
	skill.camera = camera
	var view: Rect2 = camera.get_view_rect()
	var span: Vector2 = skill.get_strike_range(Vector2(500.0, 880.0))
	assert_almost_eq(span.x, view.position.x - UltimateSkill.RANGE_MARGIN, "the left edge is the left edge of the screen (plus a margin)", 0.5)
	assert_almost_eq(span.y, view.end.x + UltimateSkill.RANGE_MARGIN, "the right edge is the right edge of the screen (plus a margin)", 0.5)


func test_ultimate_freezes_the_game_briefly_through_battle_feedback() -> void:
	var setup: Dictionary = _ready_skill()
	var player: Player = setup["player"]
	var skill: UltimateSkill = setup["skill"]
	var feedback: BattleFeedback = add_to_tree(BattleFeedback.new()) as BattleFeedback
	assert_true(skill.request() == UltimateSkill.Result.OK, "started")
	assert_true(not feedback.is_hit_stopped(), "the game keeps running while the blade goes up")
	_tick_player(player, player.stats.ultimate_windup + 0.02)
	assert_true(feedback.is_hit_stopped(), "the game freezes when the sweep lands (the dramatic pause)")
	assert_true(skill.pause_seconds >= 0.1 and skill.pause_seconds <= 0.3, "for a short beat")
	feedback.end_hit_stop()
	assert_eq(Engine.time_scale, 1.0, "and time returns to normal")
	var layers: int = 0
	for child: Node in skill.get_children():
		if child is CanvasLayer:
			layers += 1
	assert_eq(layers, 1, "the brush sweep is on screen")


# --- Sweep effect ---------------------------------------------------------------

func test_sweep_runs_in_real_time_during_the_freeze_then_frees_itself() -> void:
	var sweep: UltimateSweep = UltimateSweep.new()
	sweep.setup(1, 0.15, 12345)
	add_to_tree(sweep)
	Engine.time_scale = 0.02
	# At 2% speed a frame is 0.00033 game-seconds, but the sweep still advances 1/60 real second.
	for i: int in 30:
		sweep._process(STEP * Engine.time_scale)
	assert_almost_eq(sweep.get_age(), 0.5, "30 frames at 2%% speed are half a real second to the sweep", 0.02)
	assert_true(sweep.get_lifetime() <= 0.45, "the whole effect lasts about 0.4 s")
	Engine.time_scale = 1.0
	for i: int in 60:
		sweep._process(STEP)
	assert_true(sweep.is_queued_for_deletion(), "it frees itself when its lifetime is over (%.2f s)" % sweep.get_lifetime())
	assert_true(sweep.get_lifetime() < 1.0, "it never lingers")


# --- HUD and touch --------------------------------------------------------------

func test_hud_bar_shows_charge_and_pulses_when_ready() -> void:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	var bar: FillBar = hud.find_child("UltimateBar", true, false) as FillBar
	assert_true(bar != null, "the HUD has an Ultimate bar")
	hud.set_ultimate(0.42, false)
	assert_eq(bar.value_text, "42%", "it shows the percentage")
	assert_true(not bar.pulsing, "and is calm while charging")
	hud.set_ultimate(1.0, true)
	assert_true(bar.value_text.begins_with("READY"), "it says READY when full")
	assert_true(bar.pulsing, "and pulses")
	hud.set_ultimate(0.0, false)
	assert_true(not bar.pulsing, "it stops when the Ultimate is spent")


func test_touch_button_glows_when_ready_and_presses_the_action() -> void:
	var controls: TouchControls = add_to_tree(TOUCH_SCENE.instantiate()) as TouchControls
	var viewport_size: Vector2 = controls.get_viewport().get_visible_rect().size
	controls.apply_layout(viewport_size, Rect2(Vector2.ZERO, viewport_size), 1.0, false)
	controls.set_active(true)
	var button: TouchActionButton = controls.find_child("UltimateButton", true, false) as TouchActionButton
	assert_true(button != null and button.action == &"ultimate", "there is an Ultimate button on the ultimate action")
	controls.set_ultimate_charge(0.5, false)
	assert_true(not button.glowing and absf(button.charge_ratio - 0.5) < 0.001, "half charged: a ring, no glow")
	assert_eq(button.sub_caption, "50%", "it shows the percentage")
	controls.set_ultimate_charge(1.0, true)
	assert_true(button.glowing, "it glows when ready")
	assert_almost_eq(button.modulate.a, 1.0, "and is fully opaque, not faded like idle buttons")
	assert_eq(button.sub_caption, "READY", "and says so")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 3
	touch.position = controls.get_widget_rect("ultimate").get_center()
	touch.pressed = true
	assert_true(controls.handle_input(touch), "a touch on it is taken")
	assert_true(Input.is_action_pressed(&"ultimate"), "and presses the ultimate action")
	touch = InputEventScreenTouch.new()
	touch.index = 3
	touch.position = controls.get_widget_rect("ultimate").get_center()
	touch.pressed = false
	controls.handle_input(touch)


func test_ultimate_button_is_big_and_clear_of_the_other_action_buttons() -> void:
	for left_handed: bool in [false, true]:
		var rects: Dictionary = TouchLayout.action_button_rects(GameSettings.MIN_UI_SCALE, left_handed)
		var ultimate: Rect2 = rects["ultimate"]
		assert_true(ultimate.size.x >= TouchLayout.MIN_TOUCH_TARGET, "the ultimate button is at least 44 pt")
		for key: String in rects:
			if key == "ultimate":
				continue
			var other: Rect2 = rects[key]
			var distance: float = ultimate.get_center().distance_to(other.get_center())
			assert_true(distance >= (ultimate.size.x + other.size.x) * 0.5, "the ultimate circle does not overlap %s (left_handed=%s)" % [key, left_handed])
	var cluster: Vector2 = TouchLayout.ACTION_CLUSTER_SIZE
	for key: String in TouchLayout.ACTION_BUTTONS:
		var rect: Rect2 = TouchLayout.ACTION_BUTTONS[key]
		assert_true(Rect2(Vector2.ZERO, cluster).encloses(rect), "%s fits inside the action cluster" % key)


# --- Battle wiring --------------------------------------------------------------

func test_battle_hits_charge_the_meter_but_the_ultimate_does_not() -> void:
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", "user://test_saves/ultimate_save.json")
	field.set("settings_path", "user://test_saves/ultimate_settings.cfg")
	add_to_tree(field)
	var meter: UltimateMeter = field.get_node("World/UltimateMeter") as UltimateMeter
	var player: Player = field.get_node("World/Player") as Player
	var enemy: Enemy = _enemy(900.0)
	assert_almost_eq(meter.current, 0.0, "a battle starts with an empty meter")
	field.call("_on_hit_reported", enemy, HitData.new(40.0, Vector2.ZERO, player))
	assert_almost_eq(meter.current, 40.0 * meter.per_damage_dealt, "a hit the samurai lands charges it")
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ASHIGARU, 600.0)
	add_to_tree(ally)
	var before: float = meter.current
	field.call("_on_hit_reported", enemy, HitData.new(40.0, Vector2.ZERO, ally))
	assert_almost_eq(meter.current - before, 40.0 * meter.per_damage_dealt * meter.ally_share, "an ally's hit charges it less")
	before = meter.current
	field.call("_on_hit_reported", player, HitData.new(30.0, Vector2.ZERO, enemy))
	assert_almost_eq(meter.current - before, 30.0 * meter.per_damage_taken, "a hit on the samurai charges it")
	before = meter.current
	field.call("_on_hit_reported", ally, HitData.new(30.0, Vector2.ZERO, enemy))
	assert_almost_eq(meter.current, before, "a hit on an ally does not")
	meter.add_charge(meter.max_charge)
	field.call("_update_cooldown_displays")
	var bar: FillBar = field.get_node("Hud").find_child("UltimateBar", true, false) as FillBar
	assert_true(bar.pulsing, "the HUD bar pulses once the meter is full")
