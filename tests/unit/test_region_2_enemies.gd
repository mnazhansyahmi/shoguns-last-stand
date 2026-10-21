extends "res://tests/test_case.gd"
## Region 2's enemies: the Spectral Archer (stays at range, shoots allies first), the Shield Bearer (blocks frontal hits
## until a heavy blow or a hit from behind), the Flying Spirit (only arrows and the Onmyoji's fire reach it) and the stage
## 10 boss, The Burning General (the Daimyo's body on fire, pillars of fire and a wall of flame, three phases). Each reuses
## an existing painted body with a tint and a prop.

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/boss.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ARCHER: EnemyData = preload("res://data/enemies/spectral_archer.tres")
const SHIELD: EnemyData = preload("res://data/enemies/shield_bearer.tres")
const SPIRIT: EnemyData = preload("res://data/enemies/flying_spirit.tres")
const GENERAL: BossData = preload("res://data/enemies/burning_general.tres")
const DAIMYO: BossData = preload("res://data/enemies/fallen_daimyo.tres")
const ASHIGARU: AllyData = preload("res://data/allies/ashigaru.tres")
const YUMI: AllyData = preload("res://data/allies/yumi_archer.tres")
const ONMYOJI: AllyData = preload("res://data/allies/onmyoji.tres")
const STAGE_10: StageData = preload("res://data/stages/stage_10.tres")
const STEP: float = 1.0 / 60.0


func _enemy(data: EnemyData, x: float = 1200.0) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(data)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	return enemy


func _ally(data: AllyData, x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(data, x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally


## A defenders' hitbox, live, as a blade or an arrow: `push` is the way it knocks (1 = toward +x).
func _blade(push: float, heavy: bool = false, reaches_air: bool = false) -> HitboxComponent:
	var hitbox: HitboxComponent = add_to_tree(HitboxComponent.new()) as HitboxComponent
	hitbox.faction = Faction.Type.DEFENDERS
	hitbox.reaches_air = reaches_air
	hitbox.knockback_direction_x = push
	hitbox.activate(30.0, 100.0, -1.0, heavy)
	return hitbox


func _health(enemy: Enemy) -> HealthComponent:
	return enemy.get_node("HealthComponent") as HealthComponent


func _tick(enemy: Enemy, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		enemy._physics_process(STEP)


# --- Data -------------------------------------------------------------------------

func test_each_new_enemy_reuses_a_painted_body_with_a_tint_and_a_prop() -> void:
	for data: EnemyData in [ARCHER, SHIELD, SPIRIT]:
		assert_eq(data.figure, InkFigure.Kind.HOLLOW_SOLDIER, "%s reuses the Hollow Soldier's body" % data.display_name)
		assert_true(data.prop != EnemyProp.Kind.NONE, "%s carries its own weapon or effect" % data.display_name)
		assert_true(not data.counter_hint.is_empty(), "%s says how to beat it" % data.display_name)
	assert_true(ARCHER.tint.b > ARCHER.tint.r, "the archer is ghostly blue")
	assert_eq(ARCHER.prop, EnemyProp.Kind.BOW, "with a bow")
	assert_eq(SHIELD.prop, EnemyProp.Kind.SHIELD, "the Shield Bearer has a shield")
	assert_eq(SPIRIT.prop, EnemyProp.Kind.WISP, "the spirit is an ink wisp")
	assert_eq(GENERAL.figure, InkFigure.Kind.FALLEN_DAIMYO, "the General is the Daimyo's body")
	assert_true(GENERAL.tint.r > 1.0 and GENERAL.tint.b < 1.0, "burning")
	assert_eq(GENERAL.prop, EnemyProp.Kind.FIRE_AURA, "wreathed in fire")


func test_the_spectral_archer_stays_at_range_and_hunts_allies_first() -> void:
	assert_true(ARCHER.ranged and ARCHER.attack_range >= 350.0 and ARCHER.keep_distance > 0.0, "it shoots from range")
	assert_eq(ARCHER.target_priorities[0], EnemyData.TargetKind.ALLY, "allies first")
	var archer: Enemy = _enemy(ARCHER, 1200.0)
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_to_tree(player)
	player.global_position = Vector2(1100.0, 880.0)
	var ally: Ally = _ally(ASHIGARU, 900.0)
	assert_true(archer.select_target() == ally, "it picks the ally even with the samurai closer")
	archer.call(&"_change_state", Enemy.State.ACQUIRE_TARGET)
	_tick(archer, 1.2)
	var arrows: Array[Arrow] = []
	for child: Node in archer.get_parent().get_children():
		if child is Arrow:
			arrows.append(child as Arrow)
	assert_eq(arrows.size(), 1, "it looses an arrow without walking up")
	assert_true(absf(archer.global_position.x - 1200.0) < 60.0, "from where it stood")
	if not arrows.is_empty():
		var hitbox: HitboxComponent = arrows[0].get_node("Hitbox") as HitboxComponent
		assert_eq(hitbox.faction, Faction.Type.ENEMIES, "the arrow is the enemies'")
		var health: HealthComponent = ally.get_node("HealthComponent") as HealthComponent
		assert_true(hitbox.try_hit(ally.get_node("Hurtbox") as HurtboxComponent) and health.current_health < health.max_health, "and wounds the ally")


func test_the_spectral_archer_backs_off_from_a_close_target_between_shots() -> void:
	var archer: Enemy = _enemy(ARCHER, 1200.0)
	var ally: Ally = _ally(ASHIGARU, 1120.0)
	archer.call(&"_change_state", Enemy.State.ACQUIRE_TARGET)
	archer.set("_target", ally)
	archer.set("_attack_cooldown_left", 2.0)
	_tick(archer, 0.5)
	assert_true(archer.global_position.x > 1200.0, "it steps back from an ally in its face (%.0f)" % archer.global_position.x)


func test_the_shield_blocks_frontal_hits_but_not_hits_from_behind() -> void:
	var bearer: Enemy = _enemy(SHIELD)
	bearer.call(&"_set_facing", -1)
	var health: HealthComponent = _health(bearer)
	var hurtbox: HurtboxComponent = bearer.get_hurtbox()
	assert_true(bearer.is_shield_up(), "the shield is up")
	var front: HitboxComponent = _blade(1.0)
	var blocked: Array[HurtboxComponent] = []
	front.hit_blocked.connect(func(box: HurtboxComponent) -> void: blocked.append(box))
	assert_true(not front.try_hit(hurtbox), "a cut from in front is stopped")
	assert_almost_eq(health.current_health, health.max_health, "for no damage")
	assert_eq(blocked.size(), 1, "the blade knows it hit the shield")
	assert_true(not front.try_hit(hurtbox) and blocked.size() == 1, "and counts it as its one hit on him")
	var behind: HitboxComponent = _blade(-1.0)
	assert_true(behind.try_hit(hurtbox), "a cut from behind lands")
	assert_true(health.current_health < health.max_health, "and hurts")
	assert_true(bearer.is_shield_up(), "the shield is still whole")


func test_a_heavy_blow_breaks_the_shield_for_good() -> void:
	var bearer: Enemy = _enemy(SHIELD)
	bearer.call(&"_set_facing", -1)
	var health: HealthComponent = _health(bearer)
	assert_true(_blade(1.0, true).try_hit(bearer.get_hurtbox()), "a heavy blow from in front lands")
	assert_true(not bearer.is_shield_up(), "and breaks the shield")
	var after: float = health.current_health
	assert_true(after < health.max_health, "it hurts too")
	assert_true(_blade(1.0).try_hit(bearer.get_hurtbox()) and health.current_health < after, "then ordinary cuts from in front land")


func test_arrows_stop_on_the_shield() -> void:
	var bearer: Enemy = _enemy(SHIELD, 1200.0)
	bearer.call(&"_set_facing", -1)
	var arrow: Arrow = preload("res://scenes/allies/arrow.tscn").instantiate() as Arrow
	arrow.setup(1.0, 20.0, 900.0, 700.0, 50.0, null, Vector2(1000.0, 820.0))
	add_to_tree(arrow)
	var hitbox: HitboxComponent = arrow.get_node("Hitbox") as HitboxComponent
	assert_true(not hitbox.try_hit(bearer.get_hurtbox()), "the arrow does not wound him")
	assert_true(arrow.is_queued_for_deletion(), "it breaks on the shield")
	assert_almost_eq(_health(bearer).current_health, SHIELD.max_health, "no damage")


func test_only_arrows_and_fire_reach_the_flying_spirit() -> void:
	var spirit: Enemy = _enemy(SPIRIT)
	assert_true(spirit.is_flying(), "it flies")
	var health: HealthComponent = _health(spirit)
	var blade: HitboxComponent = _blade(1.0, true)
	assert_true(not blade.try_hit(spirit.get_hurtbox()), "a blade passes under it, even a heavy one")
	assert_almost_eq(health.current_health, health.max_health, "untouched")
	assert_true(blade.try_hit(spirit.get_hurtbox()) == false, "it is not counted as blocked either (it simply is not there)")
	assert_true(_blade(1.0, false, true).try_hit(spirit.get_hurtbox()), "an arrow reaches it")
	assert_true(health.current_health < health.max_health, "and hurts it")
	var arrow: Arrow = preload("res://scenes/allies/arrow.tscn").instantiate() as Arrow
	arrow.setup(1.0, 20.0, 900.0, 700.0, 50.0, null, Vector2.ZERO)
	add_to_tree(arrow)
	assert_true((arrow.get_node("Hitbox") as HitboxComponent).reaches_air, "the Bow's and the archers' arrows reach the air")
	var hurtbox_top: float = (spirit.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D).position.y
	assert_true(hurtbox_top < -SPIRIT.body_size.y * 0.5 - SPIRIT.hover_height * 0.9, "its body floats above the ground")


func test_only_archers_and_the_onmyoji_go_after_a_spirit() -> void:
	var spirit: Enemy = _enemy(SPIRIT, 1000.0)
	var ashigaru: Ally = _ally(ASHIGARU, 900.0)
	var yumi: Ally = _ally(YUMI, 800.0)
	var onmyoji: Ally = _ally(ONMYOJI, 820.0)
	assert_true(ashigaru.select_target() == null, "a spearman leaves it alone")
	assert_true(yumi.select_target() == spirit, "an archer aims at it")
	assert_true(onmyoji.select_target() == spirit, "the Onmyoji casts at it")
	assert_true(YUMI.can_hit_air() and ONMYOJI.can_hit_air() and not ASHIGARU.can_hit_air(), "who can reach the air")


func test_flyers_do_not_hold_up_the_marching_line() -> void:
	var spirit: Enemy = _enemy(SPIRIT, 1000.0)
	var soldier: Enemy = _enemy(preload("res://data/enemies/hollow_soldier.tres"), 1010.0)
	assert_true(not soldier.call(&"_is_blocked_by_other_enemy", -1), "a soldier walks under a spirit")
	assert_true(not spirit.call(&"_is_blocked_by_other_enemy", 1), "and a spirit over a soldier")


func test_props_replace_the_body_weapon_and_the_wisp_hides_the_body() -> void:
	var archer: Enemy = _enemy(ARCHER)
	var prop: EnemyProp = archer.get_node("Visual/Prop") as EnemyProp
	assert_true(prop != null and prop.kind == EnemyProp.Kind.BOW, "the archer holds a bow")
	var figure: InkFigure = (archer.get_node("Visual") as UnitVisual).get_figure()
	for node: Node in figure.find_children("*", "", true, false):
		var part: FigurePart = node as FigurePart
		if part != null and part.part_name == &"weapon":
			assert_true(not part.visible, "instead of the soldier's own blade")
	var spirit: Enemy = _enemy(SPIRIT)
	assert_true(not (spirit.get_node("Visual") as UnitVisual).get_figure().visible, "the spirit shows only its wisp")
	var bearer: Enemy = _enemy(SHIELD)
	_blade(1.0, true).try_hit(bearer.get_hurtbox())
	assert_true(not (bearer.get_node("Visual/Prop") as EnemyProp).is_shield_up(), "a broken shield falls away")


# --- The Burning General ------------------------------------------------------------

func _general(x: float = 1200.0) -> Boss:
	var boss: Boss = BOSS_SCENE.instantiate() as Boss
	boss.setup(GENERAL)
	add_to_tree(boss)
	boss.global_position = Vector2(x, 880.0)
	boss.call(&"_change_state", Enemy.State.ADVANCE)
	return boss


func _attack(id: StringName) -> BossAttackData:
	for attack: BossAttackData in GENERAL.attacks:
		if attack.id == id:
			return attack
	return null


func test_the_burning_general_has_fire_attacks_and_three_phases() -> void:
	assert_eq(GENERAL.display_name, "The Burning General", "he is named")
	assert_eq(GENERAL.phases.size(), 3, "three phases")
	assert_true(not GENERAL.phases[1].banner.is_empty() and not GENERAL.phases[2].banner.is_empty(), "each announced")
	assert_true(GENERAL.max_health > DAIMYO.max_health, "tougher than the Daimyo")
	assert_true(_attack(&"eruption") != null and _attack(&"eruption").kind == BossAttackData.Kind.ERUPTION, "pillars of fire")
	assert_true(_attack(&"wave") != null and _attack(&"wave").fire, "a wall of flame")
	assert_eq(_attack(&"summon").summon_enemy, ARCHER, "he calls Spectral Archers")
	for attack: BossAttackData in GENERAL.attacks:
		assert_true(attack.windup / GENERAL.phases[2].speed_multiplier >= 0.6, "%s stays readable in the last phase" % attack.id)
	assert_eq(STAGE_10.boss_name(), "The Burning General", "stage 10 ends with him")
	var last: WaveData = STAGE_10.waves[STAGE_10.waves.size() - 1]
	var bosses: int = 0
	for wave: WaveData in STAGE_10.waves:
		for entry: WaveEntry in wave.entries:
			if entry.enemy is BossData:
				bosses += entry.count
				assert_true(wave == last, "only in the final wave")
	assert_eq(bosses, 1, "once")


func test_pillars_of_fire_burst_where_the_warnings_burned() -> void:
	var boss: Boss = _general(1300.0)
	var player: Player = PLAYER_SCENE.instantiate() as Player
	add_to_tree(player)
	player.global_position = Vector2(1000.0, 880.0)
	boss.call(&"_set_facing", -1)
	boss.set("_target", player)
	boss.call(&"_begin_attack", _attack(&"eruption"))
	var warnings: int = 0
	for child: Node in boss.get_parent().get_children():
		if child is AttackTelegraph and not child.is_queued_for_deletion():
			warnings += 1
	assert_eq(warnings, _attack(&"eruption").pillar_count, "a warning for every pillar")
	for i: int in ceili((_attack(&"eruption").windup + 0.05) / STEP):
		boss._physics_process(STEP)
	var pillars: Array[FirePillar] = []
	for child: Node in boss.get_parent().get_children():
		if child is FirePillar:
			pillars.append(child as FirePillar)
	assert_eq(pillars.size(), _attack(&"eruption").pillar_count, "then the pillars rise")
	var nearest: float = INF
	for pillar: FirePillar in pillars:
		nearest = minf(nearest, absf(pillar.global_position.x - player.global_position.x))
		assert_true(pillar.is_burning(), "burning")
	assert_true(nearest < 1.0, "one right under the player")
	var hurtbox: HurtboxComponent = player.get_node("Hurtbox") as HurtboxComponent
	var health: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	for pillar: FirePillar in pillars:
		(pillar.get_node("Hitbox") as HitboxComponent).try_hit(hurtbox)
	assert_true(health.current_health < health.max_health, "and it burns")


func test_the_wall_of_flame_is_a_fire_wave() -> void:
	var boss: Boss = _general(1500.0)
	boss.phase = 2
	boss.call(&"_set_facing", -1)
	boss.call(&"_begin_attack", _attack(&"wave"))
	for i: int in ceili((_attack(&"wave").windup / boss.get_phase_data().speed_multiplier + 0.05) / STEP):
		boss._physics_process(STEP)
	var fire_waves: int = 0
	for child: Node in boss.get_parent().get_children():
		if child is CursedWave and (child as CursedWave).fire:
			fire_waves += 1
	assert_eq(fire_waves, 1, "a wall of flame rolls out")
