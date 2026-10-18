extends "res://tests/test_case.gd"
## Units must survive their target (or a projectile's source) being freed mid-fight.

const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ASHIGARU: AllyData = preload("res://data/allies/ashigaru.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const STEP: float = 1.0 / 60.0


func _make_ally(x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ASHIGARU, x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 0.0)
	return ally


func _make_enemy(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 0.0)
	return enemy


## Drives a unit's state machine directly; no physics frames run during tests.
func _tick(unit: CharacterBody2D, seconds: float) -> void:
	for i: int in ceili(seconds / STEP):
		unit._physics_process(STEP)


## Ticks until the unit reports `state_name` (or gives up after `max_seconds`).
func _tick_until_state(unit: CharacterBody2D, state_name: String, max_seconds: float = 3.0) -> bool:
	for i: int in ceili(max_seconds / STEP):
		if unit.get_state_name() == state_name:
			return true
		unit._physics_process(STEP)
	return unit.get_state_name() == state_name


func test_ally_target_freed_mid_fight_picks_new_target() -> void:
	var ally: Ally = _make_ally(400.0)
	var first: Enemy = _make_enemy(460.0)
	var second: Enemy = _make_enemy(700.0)
	assert_true(_tick_until_state(ally, "RECOVER"), "ally attacks the nearby enemy and recovers")
	assert_true(ally.get_target() == first, "ally targeted the nearest enemy")
	first.free()
	_tick(ally, 1.0)
	assert_true(ally.get_state_name() == "ADVANCE" or ally.get_state_name() == "ATTACK",
			"ally re-engages instead of getting stuck (state %s)" % ally.get_state_name())
	assert_true(ally.get_target() == second, "ally picked the remaining enemy")


func test_ally_target_freed_with_no_enemies_left_idles() -> void:
	var ally: Ally = _make_ally(400.0)
	var only: Enemy = _make_enemy(700.0)
	assert_true(_tick_until_state(ally, "ADVANCE"), "ally advances toward the enemy")
	only.free()
	_tick(ally, 0.5)
	assert_eq(ally.get_state_name(), "IDLE", "ally idles when its only target is gone")
	assert_true(ally.get_target() == null, "freed target cleared")


func test_enemy_target_freed_mid_fight_resumes_advance() -> void:
	var enemy: Enemy = _make_enemy(600.0)
	var target: Node2D = add_to_tree(Node2D.new())
	target.add_to_group("allies")
	target.global_position = Vector2(550.0, 0.0)
	assert_true(_tick_until_state(enemy, "RECOVER"), "enemy attacks the target and recovers")
	target.free()
	_tick(enemy, 1.0)
	assert_eq(enemy.get_state_name(), "ADVANCE", "enemy resumes advancing")
	assert_true(enemy.get_target() == null, "freed target cleared")


func test_hit_from_freed_source_still_applies() -> void:
	var owner_node: Node2D = add_to_tree(Node2D.new())
	var health: HealthComponent = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100.0
	owner_node.add_child(health)
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.faction = Faction.Type.ENEMIES
	owner_node.add_child(hurtbox)
	var received: Array[HitData] = []
	hurtbox.hit_received.connect(func(hit: HitData) -> void: received.append(hit))

	var shooter: Node2D = Node2D.new()
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.faction = Faction.Type.DEFENDERS
	hitbox.source = shooter
	add_to_tree(hitbox)
	hitbox.activate(12.0, 80.0, 1.0)
	shooter.free()  # e.g. the archer died while its arrow was in flight

	assert_true(hitbox.try_hit(hurtbox), "hit still lands")
	assert_almost_eq(health.current_health, 88.0, "damage applied")
	assert_eq(received.size(), 1, "hit_received emitted")
	if received.size() == 1:
		assert_true(received[0].source == null, "freed source reported as null")
