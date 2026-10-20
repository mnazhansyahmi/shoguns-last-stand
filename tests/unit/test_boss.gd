extends "res://tests/test_case.gd"
## Stage 5's boss, The Fallen Daimyo: his data (three phases, five telegraphed attacks), his figure, the
## phase changes, every attack's wind-up and impact, his targeting, the boss bar and the final wave.

const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/boss.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const DAIMYO: BossData = preload("res://data/enemies/fallen_daimyo.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const STAGE_5: StageData = preload("res://data/stages/stage_5.tres")
const STEP: float = 1.0 / 60.0


func _boss(x: float = 1200.0) -> Boss:
	var boss: Boss = BOSS_SCENE.instantiate() as Boss
	boss.setup(DAIMYO)
	add_to_tree(boss)
	boss.global_position = Vector2(x, 880.0)
	boss.call(&"_change_state", Enemy.State.ADVANCE)
	return boss


func _minion() -> Enemy:
	var minion: Enemy = preload("res://scenes/enemies/enemy.tscn").instantiate() as Enemy
	minion.setup(HOLLOW_SOLDIER)
	add_to_tree(minion)
	return minion


func _player(x: float) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_to_tree(player)
	player.global_position = Vector2(x, 880.0)
	return player


func _tick(boss: Boss, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		boss._physics_process(STEP)


func _attack(id: StringName) -> BossAttackData:
	for attack: BossAttackData in DAIMYO.attacks:
		if attack.id == id:
			return attack
	return null


func _telegraphs(boss: Boss) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in boss.get_parent().get_children():
		if child is AttackTelegraph and not child.is_queued_for_deletion():
			found.append(child)
	return found


# --- Data -------------------------------------------------------------------------

func test_the_boss_is_data_driven_like_other_enemies() -> void:
	assert_true(DAIMYO is EnemyData, "a BossData is an EnemyData")
	assert_eq(DAIMYO.display_name, "The Fallen Daimyo", "he has his name")
	assert_true(DAIMYO.scene != null, "his data names the scene he spawns with")
	assert_true(DAIMYO.body_size.y > ONI_BRUTE.body_size.y and DAIMYO.body_size.x > ONI_BRUTE.body_size.x, "he is bigger than the Oni")
	assert_true(DAIMYO.max_health > ONI_BRUTE.max_health * 3.0, "and has a boss's health")
	assert_true(not DAIMYO.interruptible and DAIMYO.knockback_resistance >= 0.99, "hits do not stagger him or push him")
	assert_eq(DAIMYO.figure, InkFigure.Kind.FALLEN_DAIMYO, "he is drawn as the Fallen Daimyo")
	var spawner: EnemySpawner = add_to_tree(EnemySpawner.new()) as EnemySpawner
	var spawned: Enemy = spawner.spawn(DAIMYO)
	track(spawned)
	assert_true(spawned is Boss, "the spawner makes a Boss from his data (and a plain Enemy from any other)")
	var plain: Enemy = spawner.spawn(HOLLOW_SOLDIER)
	track(plain)
	assert_true(not (plain is Boss), "other enemies stay generic")


func test_three_phases_each_faster_and_harder() -> void:
	assert_eq(DAIMYO.phases.size(), 3, "three phases")
	assert_almost_eq(DAIMYO.phases[0].start_ratio, 1.0, "phase 1 from full health")
	assert_almost_eq(DAIMYO.phases[1].start_ratio, 0.66, "phase 2 at 66%%")
	assert_almost_eq(DAIMYO.phases[2].start_ratio, 0.33, "phase 3 at 33%%")
	for i: int in range(1, 3):
		assert_true(DAIMYO.phases[i].speed_multiplier > DAIMYO.phases[i - 1].speed_multiplier, "phase %d is faster" % (i + 1))
		assert_true(DAIMYO.phases[i].damage_multiplier > DAIMYO.phases[i - 1].damage_multiplier, "phase %d hits harder" % (i + 1))
		assert_true(DAIMYO.phases[i].attack_gap < DAIMYO.phases[i - 1].attack_gap, "phase %d attacks more often" % (i + 1))
		assert_true(DAIMYO.phases[i].pause_time >= 1.0, "phase %d starts with a dramatic pause" % (i + 1))
	assert_eq(DAIMYO.phase_for_ratio(1.0), 1, "full health is phase 1")
	assert_eq(DAIMYO.phase_for_ratio(0.67), 1, "67%% is still phase 1")
	assert_eq(DAIMYO.phase_for_ratio(0.66), 2, "66%% begins phase 2")
	assert_eq(DAIMYO.phase_for_ratio(0.34), 2, "34%% is phase 2")
	assert_eq(DAIMYO.phase_for_ratio(0.33), 3, "33%% begins phase 3")
	assert_eq(DAIMYO.phase_for_ratio(0.01), 3, "and it lasts to the end")


func test_five_attack_kinds_each_with_a_readable_windup() -> void:
	var kinds: Dictionary = {}
	for attack: BossAttackData in DAIMYO.attacks:
		kinds[attack.kind] = true
		assert_true(attack.windup >= 0.9, "%s has a wind-up of at least 0.9 s (%.2f)" % [attack.id, attack.windup])
		assert_true(attack.windup / DAIMYO.phases[2].speed_multiplier >= 0.6, "and still at least 0.6 s in the last phase")
	assert_eq(kinds.size(), 5, "sweep, slam, leap, wave and summon are all there")
	var by_phase: Array[int] = [0, 0, 0]
	for attack: BossAttackData in DAIMYO.attacks:
		for phase: int in range(attack.min_phase, 4):
			by_phase[phase - 1] += 1
	assert_true(by_phase[1] > by_phase[0] and by_phase[2] > by_phase[1], "each phase unlocks new attacks (%s)" % str(by_phase))
	assert_eq(_attack(&"summon").summon_enemy, HOLLOW_SOLDIER, "he calls Hollow Soldiers")
	assert_true(_attack(&"sweep").repeats.z > _attack(&"sweep").repeats.x, "the sweep becomes a combo in the last phase")


# --- Figure -----------------------------------------------------------------------

func test_the_daimyo_figure_has_tattered_armour_one_accent_and_a_cursed_blade() -> void:
	var spec: FigureKinds.Spec = FigureKinds.spec(InkFigure.Kind.FALLEN_DAIMYO)
	assert_eq(spec.accent, InkPalette.DAIMYO_CURSE, "his one accent is the cursed green-yellow")
	assert_true(spec.is_enemy, "he is an enemy")
	assert_true(FigureTatters.has_tatters(InkFigure.Kind.FALLEN_DAIMYO), "his cloak is torn and flutters")
	assert_true(FigurePainter.layout(InkFigure.Kind.FALLEN_DAIMYO).has(&"hem"), "and is drawn")
	assert_true(not FigurePainter.is_ally_tone(InkFigure.Kind.FALLEN_DAIMYO), "he wears the enemies' dark ink")
	for part_name: StringName in FigurePainter.layout(InkFigure.Kind.FALLEN_DAIMYO):
		if part_name != &"hem":
			assert_true(FigurePainter.part(InkFigure.Kind.FALLEN_DAIMYO, part_name) != null, "his %s is painted" % part_name)
	var glows: Array[Dictionary] = FigurePainter.glows(InkFigure.Kind.FALLEN_DAIMYO)
	var parts: Dictionary = {}
	var rage_levels: Dictionary = {}
	for definition: Dictionary in glows:
		parts[definition["part"]] = true
		rage_levels[definition["rage_min"]] = true
	assert_true(parts.has(&"weapon") and parts.has(&"head") and parts.has(&"torso"), "his blade, eyes and cracks glow")
	assert_true(rage_levels.has(1) and rage_levels.has(2) and rage_levels.has(3), "and each phase shows more light")


func test_each_phase_changes_how_he_looks() -> void:
	var boss: Boss = _boss()
	var figure: InkFigure = (boss.get_node("Visual") as UnitVisual).get_figure()
	var shown: Array[int] = []
	for level: int in [1, 2, 3]:
		(boss.get_node("Visual") as UnitVisual).set_rage(level)
		figure.refresh()
		var visible_lights: int = 0
		for glow: FigurePart in figure.get("_fall_glows"):
			if glow.visible:
				visible_lights += 1
		shown.append(visible_lights)
	assert_true(shown[1] > shown[0] and shown[2] > shown[1], "more lights burn in each phase (%s)" % str(shown))
	assert_true(figure.scale.x > 1.0, "and he is a little bigger in the last phase")


# --- Phases -----------------------------------------------------------------------

func test_he_changes_phase_at_66_and_33_percent_with_a_pause() -> void:
	var boss: Boss = _boss()
	var changes: Array[int] = []
	boss.phase_changed.connect(func(phase: int, _banner: String) -> void: changes.append(phase))
	var health: HealthComponent = boss.get_health()
	health.take_damage(health.max_health * 0.30)
	assert_eq(boss.phase, 1, "at 70%% he is still in phase 1")
	health.take_damage(health.max_health * 0.06)
	assert_eq(boss.phase, 2, "below 66%% he enters phase 2")
	assert_true(boss.is_transitioning(), "and roars for a moment")
	var before: float = health.current_health
	health.take_damage(500.0)
	assert_almost_eq(health.current_health, before, "he cannot be hurt during the pause")
	_tick(boss, DAIMYO.phases[1].pause_time + 0.1)
	assert_true(not boss.is_transitioning(), "the pause ends")
	health.clear_invulnerability()
	health.take_damage(health.max_health * 0.33)
	assert_eq(boss.phase, 3, "below 33%% he enters phase 3")
	assert_eq(changes, [2, 3] as Array[int], "each change is announced once")


func test_a_phase_change_cancels_the_attack_in_progress() -> void:
	var boss: Boss = _boss()
	boss.call(&"_begin_attack", _attack(&"slam"))
	_tick(boss, 0.4)
	assert_true(not _telegraphs(boss).is_empty(), "the slam is being telegraphed")
	var health: HealthComponent = boss.get_health()
	health.take_damage(health.max_health * 0.40)
	assert_true(boss.get_current_attack() == null, "the phase change cancels it")
	assert_true(not (boss.get_node("Hitbox") as HitboxComponent).is_active(), "nothing hurts during the roar")


func test_later_phases_are_faster() -> void:
	var boss: Boss = _boss()
	var windups: Array[float] = []
	for phase: int in [1, 2, 3]:
		boss.phase = phase
		boss.call(&"_begin_attack", _attack(&"slam"))
		windups.append(float(boss.get("_step_length")))
		boss.call(&"_cancel_attack")
	assert_true(windups[1] < windups[0] and windups[2] < windups[1], "the same attack winds up faster each phase (%s)" % str(windups))


# --- Attacks ----------------------------------------------------------------------

func test_a_sweep_is_telegraphed_then_hits_in_front_of_him() -> void:
	var boss: Boss = _boss(1200.0)
	var player: Player = _player(1020.0)
	boss.call(&"_set_facing", -1)
	var health: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	boss.call(&"_begin_attack", _attack(&"sweep"))
	_tick(boss, 0.3)
	assert_eq(boss.get_state(), Enemy.State.ATTACK, "he is attacking")
	assert_true(not _telegraphs(boss).is_empty(), "a warning marks the ground")
	assert_true(not (boss.get_node("Hitbox") as HitboxComponent).is_active(), "nothing hurts during the wind-up")
	assert_almost_eq(health.current_health, health.max_health, "and the player is untouched")
	_tick(boss, _attack(&"sweep").windup + 0.1)
	var hitbox: HitboxComponent = boss.get_node("Hitbox") as HitboxComponent
	assert_true(hitbox.is_active(), "then the cut is live")
	assert_true(hitbox.try_hit(player.get_node("Hurtbox") as HurtboxComponent) or health.current_health < health.max_health,
			"and it lands on the player in front of him")
	assert_true(_telegraphs(boss).is_empty(), "and the warning goes")


func test_the_sweep_hitbox_is_in_front_of_him_not_behind() -> void:
	var boss: Boss = _boss(1200.0)
	boss.call(&"_set_facing", -1)
	boss.call(&"_begin_attack", _attack(&"sweep"))
	_tick(boss, _attack(&"sweep").windup + 0.05)
	var shape: CollisionShape2D = boss.get_node("Hitbox/CollisionShape2D") as CollisionShape2D
	assert_true(shape.global_position.x < boss.global_position.x - 100.0, "a cut facing left is on his left (%.0f)" % (shape.global_position.x - boss.global_position.x))
	boss.call(&"_cancel_attack")
	boss.call(&"_set_facing", 1)
	boss.call(&"_activate_hitbox", _attack(&"sweep"), true)
	assert_true(shape.global_position.x > boss.global_position.x + 100.0, "facing right it is on his right")


func test_the_slam_reaches_both_ways() -> void:
	var boss: Boss = _boss(1200.0)
	boss.call(&"_set_facing", -1)
	boss.call(&"_begin_attack", _attack(&"slam"))
	_tick(boss, _attack(&"slam").windup + 0.1)
	var hitbox: HitboxComponent = boss.get_node("Hitbox") as HitboxComponent
	assert_true(hitbox.is_active(), "the slam is live")
	var shape: CollisionShape2D = boss.get_node("Hitbox/CollisionShape2D") as CollisionShape2D
	var rect: RectangleShape2D = shape.shape as RectangleShape2D
	assert_true(rect.size.x >= 480.0, "its zone is wide (%.0f px)" % rect.size.x)
	assert_true(absf(shape.global_position.x - boss.global_position.x) < 5.0, "and centred on him: both sides")
	assert_eq(hitbox.knockback_direction_x, 0.0, "it pushes everyone away from him")


func test_the_leap_jumps_to_the_target_and_lands_with_a_blast() -> void:
	var boss: Boss = _boss(1500.0)
	var player: Player = _player(900.0)
	boss.phase = 2
	boss.call(&"_set_facing", -1)
	boss.set("_target", player)
	boss.call(&"_begin_attack", _attack(&"leap"))
	_tick(boss, 0.3)
	var marks: Array[Node] = _telegraphs(boss)
	assert_true(not marks.is_empty(), "the landing spot is marked")
	if not marks.is_empty():
		assert_true(absf((marks[0] as Node2D).global_position.x - 900.0) < 5.0, "right where the player stands")
	_tick(boss, _attack(&"leap").windup / boss.get_phase_data().speed_multiplier)
	assert_eq(boss.get("_step"), Boss.Step.AIR, "he leaps")
	assert_true(boss.velocity.y < 0.0 and boss.velocity.x < 0.0, "up and toward the target")


func test_the_cursed_wave_is_a_projectile_that_hits_once() -> void:
	var boss: Boss = _boss(1500.0)
	var player: Player = _player(1000.0)
	boss.phase = 2
	boss.call(&"_set_facing", -1)
	boss.call(&"_begin_attack", _attack(&"wave"))
	_tick(boss, 0.5)
	assert_true(not _telegraphs(boss).is_empty(), "the path of the wave is shown")
	_tick(boss, _attack(&"wave").windup / boss.get_phase_data().speed_multiplier)
	var waves: Array[Node] = []
	for child: Node in boss.get_parent().get_children():
		if child is CursedWave:
			waves.append(child)
	assert_eq(waves.size(), 1, "a wave is sent")
	assert_true(not waves.is_empty() and (waves[0] as Node2D).scale.x < 0.0, "toward the way he faces")
	var health: HealthComponent = player.get_node("Health" + "Component") as HealthComponent
	var wave: CursedWave = waves[0] as CursedWave
	var hitbox: HitboxComponent = wave.get_node("Hitbox") as HitboxComponent
	assert_eq(hitbox.faction, Faction.Type.ENEMIES, "it hurts the player's side")
	var hurtbox: HurtboxComponent = player.get_node("Hurtbox") as HurtboxComponent
	assert_true(hitbox.try_hit(hurtbox), "it hits")
	assert_true(not hitbox.try_hit(hurtbox), "once")
	assert_true(health.current_health < health.max_health, "for damage")


func test_the_summon_calls_hollow_soldiers_after_a_long_windup() -> void:
	var boss: Boss = _boss(1200.0)
	boss.phase = 3
	var calls: Array = []
	boss.minions_requested.connect(func(enemy_data: EnemyData, xs: PackedFloat32Array) -> void: calls.append([enemy_data, xs]))
	boss.call(&"_begin_attack", _attack(&"summon"))
	_tick(boss, 0.3)
	assert_true(_telegraphs(boss).size() >= 3, "a ring marks where each soldier will rise")
	assert_true(calls.is_empty(), "nothing rises yet")
	_tick(boss, _attack(&"summon").windup / boss.get_phase_data().speed_multiplier)
	assert_eq(calls.size(), 1, "then they are called")
	if calls.size() == 1:
		assert_eq(calls[0][0], HOLLOW_SOLDIER, "Hollow Soldiers")
		assert_eq((calls[0][1] as PackedFloat32Array).size(), _attack(&"summon").summon_count, "as many as the attack says")


func test_he_does_not_summon_while_his_minions_are_alive_or_before_phase_3() -> void:
	var boss: Boss = _boss()
	var picked: Dictionary = {}
	for i: int in 60:
		boss.set("_cooldowns", {})
		var attack: BossAttackData = boss.call(&"_choose_attack", 100.0)
		if attack != null:
			picked[attack.id] = true
	assert_true(not picked.has(&"summon") and not picked.has(&"leap") and not picked.has(&"wave"), "phase 1 uses only the sweep and the slam")
	boss.phase = 3
	for i: int in 6:
		boss.register_minion(_minion())
	picked.clear()
	for i: int in 60:
		boss.set("_cooldowns", {})
		var attack: BossAttackData = boss.call(&"_choose_attack", 100.0)
		if attack != null:
			picked[attack.id] = true
	assert_true(not picked.has(&"summon"), "he does not call more while six of them stand")


func test_attacks_fit_the_distance_to_the_target() -> void:
	var boss: Boss = _boss()
	boss.phase = 3
	var near: Dictionary = {}
	var far: Dictionary = {}
	for i: int in 80:
		boss.set("_cooldowns", {})
		var close: BossAttackData = boss.call(&"_choose_attack", 120.0)
		var distant: BossAttackData = boss.call(&"_choose_attack", 700.0)
		if close != null:
			near[close.id] = true
		if distant != null:
			far[distant.id] = true
	assert_true(near.has(&"sweep") or near.has(&"slam"), "up close he cuts or slams")
	assert_true(not near.has(&"leap") and not near.has(&"wave"), "he does not leap or send a wave at someone in his face")
	assert_true(far.has(&"leap") or far.has(&"wave"), "from afar he leaps or sends a wave")
	assert_true(not far.has(&"sweep") and not far.has(&"slam"), "and does not swing at the air")


# --- Targeting, minions and the end -------------------------------------------------

func test_he_goes_for_the_player_then_allies_then_the_gate() -> void:
	var boss: Boss = _boss(1500.0)
	assert_eq(boss.select_target(), null, "with nothing in reach he keeps walking")
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find("ashigaru"), 1000.0)
	add_to_tree(ally)
	ally.global_position = Vector2(1000.0, 880.0)
	assert_eq(boss.select_target(), ally, "he turns on an ally that comes within reach")
	var player: Player = _player(1100.0)
	assert_eq(boss.select_target(), player, "but prefers the player")


func test_his_minions_fall_with_him_and_he_hides_his_world_bar() -> void:
	var boss: Boss = _boss()
	assert_true(not (boss.get_node("HealthBar") as WorldHealthBar).visible, "his bar is at the top of the screen, not over his head")
	var minions: Array[Enemy] = []
	for i: int in 3:
		var minion: Enemy = _minion()
		minions.append(minion)
		boss.register_minion(minion)
	assert_eq(boss.get_minion_count(), 3, "three minions stand")
	var health: HealthComponent = boss.get_health()
	health.take_damage(health.max_health)
	assert_true(boss.is_dead(), "he dies")
	for minion: Enemy in minions:
		assert_true(minion.is_dead(), "and his minions die with him")


func test_the_stage_is_won_only_when_the_boss_dies() -> void:
	var stage: StageData = StageData.new()
	var wave: WaveData = WaveData.new()
	for enemy_data: EnemyData in [DAIMYO, HOLLOW_SOLDIER]:
		var entry: WaveEntry = WaveEntry.new()
		entry.enemy = enemy_data
		entry.count = 1
		entry.start_delay = 0.0
		wave.entries.append(entry)
	stage.waves = [wave] as Array[WaveData]
	stage.first_wave_delay = 0.0
	var spawner: EnemySpawner = add_to_tree(EnemySpawner.new()) as EnemySpawner
	var director: WaveDirector = add_to_tree(WaveDirector.new()) as WaveDirector
	director.stage = stage
	director.spawner = spawner
	var cleared: Array[int] = [0]
	director.stage_cleared.connect(func() -> void: cleared[0] += 1)
	var spawned: Array[Enemy] = []
	spawner.enemy_spawned.connect(func(enemy: Enemy) -> void: spawned.append(enemy))
	director.start()
	director.tick(0.1)
	director.tick(0.1)
	for enemy: Enemy in spawned:
		track(enemy)
	assert_eq(spawned.size(), 2, "the boss and a minion are spawned")
	var boss: Boss = null
	var minion: Enemy = null
	for enemy: Enemy in spawned:
		if enemy is Boss:
			boss = enemy as Boss
		else:
			minion = enemy
	var minion_health: HealthComponent = minion.get_node("HealthComponent") as HealthComponent
	minion_health.take_damage(minion_health.max_health)
	assert_eq(cleared[0], 0, "killing the minion does not win the stage")
	var boss_health: HealthComponent = boss.get_health()
	boss_health.take_damage(boss_health.max_health)
	assert_eq(cleared[0], 1, "killing the boss does")


func test_the_boss_wave_of_stage_5_is_the_last_and_has_a_few_minions() -> void:
	var last: WaveData = STAGE_5.waves[STAGE_5.waves.size() - 1]
	var boss_count: int = 0
	for entry: WaveEntry in last.entries:
		if entry.enemy is BossData:
			boss_count += entry.count
	assert_eq(boss_count, 1, "one Fallen Daimyo in the final wave")
	assert_true(last.get_enemy_count() >= 4 and last.get_enemy_count() <= 12, "with a few minions (%d in all)" % last.get_enemy_count())


# --- Boss bar -----------------------------------------------------------------------

func test_the_boss_bar_shows_his_name_and_health_at_the_top() -> void:
	var hud: GameHud = add_to_tree(HUD_SCENE.instantiate()) as GameHud
	assert_true(not hud.is_boss_bar_visible(), "there is no boss bar without a boss")
	hud.show_boss("The Fallen Daimyo")
	var bar: FillBar = hud.get_boss_bar()
	assert_true(hud.is_boss_bar_visible(), "it appears for a boss")
	assert_eq(bar.caption, "The Fallen Daimyo", "with his name")
	assert_eq(bar.segments, 3, "ticks mark the three phases")
	hud.set_boss_health(2400.0, 3600.0)
	assert_almost_eq(bar.ratio, 2.0 / 3.0, "it follows his health")
	hud.hide_boss()
	assert_true(not hud.is_boss_bar_visible(), "and goes when he dies")
