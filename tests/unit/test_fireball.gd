extends "res://tests/test_case.gd"
## The Onmyoji's attack: a fireball launched from his staff that flies to the enemy and explodes on it (a small
## explosion that burns the group once), drawn as ink fire.

const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const STEP: float = 1.0 / 60.0


func _ally(id: String, x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find(id), x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally


func _enemy(x: float) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.setup(HOLLOW_SOLDIER)
	add_to_tree(enemy)
	enemy.global_position = Vector2(x, 880.0)
	enemy.set_physics_process(false)
	return enemy


func _health(unit: Node) -> HealthComponent:
	return unit.get_node("HealthComponent") as HealthComponent


func _fireballs() -> Array[Fireball]:
	var found: Array[Fireball] = []
	for node: Node in tree_root.get_children():
		if node is Fireball and not node.is_queued_for_deletion():
			found.append(node as Fireball)
	return found


## Fireballs and explosions are added next to the fighters, not tracked: clear them so tests do not see each other's.
func cleanup() -> void:
	for node: Node in tree_root.get_children():
		if node is Fireball or node is FireBurst:
			node.free()
	super.cleanup()


## Ticks the Onmyoji until his fireball exists.
func _until_launched(mage: Ally) -> Fireball:
	for i: int in 300:
		# There is no floor in the test: hold him on the ground line so the ball flies the way it does in a battle.
		mage.global_position.y = 880.0
		mage.velocity.y = 0.0
		mage._physics_process(STEP)
		(mage.get_node("Visual") as UnitVisual).call(&"_process", STEP)
		var balls: Array[Fireball] = _fireballs()
		if not balls.is_empty():
			return balls[0]
	return null


func test_the_onmyoji_launches_a_fireball_instead_of_an_instant_burst() -> void:
	var mage: Ally = _ally("onmyoji", 400.0)
	var enemy: Enemy = _enemy(800.0)
	var ball: Fireball = _until_launched(mage)
	assert_true(ball != null, "he launches a fireball")
	if ball == null:
		return
	assert_almost_eq(_health(enemy).current_health, HOLLOW_SOLDIER.max_health, "which has hurt nobody yet")
	assert_true(ball.global_position.x < enemy.global_position.x - 100.0, "it starts well short of the enemy")
	var start_x: float = ball.global_position.x
	for i: int in 5:
		ball._physics_process(STEP)
	assert_true(ball.global_position.x > start_x + 40.0, "and flies toward it")
	assert_true(is_instance_valid(ball) and not ball.has_exploded(), "still flying")


func test_the_fireball_leaves_from_the_tip_of_his_staff() -> void:
	var mage: Ally = _ally("onmyoji", 400.0)
	_enemy(800.0)
	var ball: Fireball = _until_launched(mage)
	assert_true(ball != null, "he launches a fireball")
	if ball == null:
		return
	var figure: InkFigure = (mage.get_node("Visual") as UnitVisual).get_figure()
	var tip: Vector2 = figure.to_global(figure.weapon_points_for(FigureKinds.pose(InkFigure.Kind.ONMYOJI, &"strike"),
			FigurePainter.ONMYOJI_STAFF_TIP, FigurePainter.ONMYOJI_STAFF_TIP)[0])
	assert_true(ball.global_position.distance_to(tip) < 60.0, "within the staff's reach of its tip (%.0f px)" % ball.global_position.distance_to(tip))
	assert_true(ball.global_position.y < mage.global_position.y - 40.0, "up at the staff, not at his feet")
	assert_true(FigurePainter.part(InkFigure.Kind.ONMYOJI, &"weapon") != null, "the staff is drawn")


func test_the_fireball_explodes_on_the_enemy_and_hurts_the_group_once() -> void:
	var data: AllyData = ROSTER.find("onmyoji")
	var mage: Ally = _ally("onmyoji", 400.0)
	var first: Enemy = _enemy(800.0)
	var beside: Enemy = _enemy(860.0)
	var far: Enemy = _enemy(800.0 + data.area_radius + 200.0)
	var friend: Ally = _ally("ashigaru", 790.0)
	var ball: Fireball = _until_launched(mage)
	assert_true(ball != null, "he launches a fireball")
	if ball == null:
		return
	for i: int in 240:
		if not is_instance_valid(ball) or ball.has_exploded():
			break
		ball._physics_process(STEP)
	var damage: float = data.attack_damage
	assert_almost_eq(_health(first).current_health, HOLLOW_SOLDIER.max_health - damage, "the target takes the blast once")
	assert_almost_eq(_health(beside).current_health, HOLLOW_SOLDIER.max_health - damage, "so does the one beside it")
	assert_eq(_health(far).current_health, HOLLOW_SOLDIER.max_health, "one outside the blast radius does not")
	assert_eq(_health(friend).current_health, ROSTER.find("ashigaru").max_health, "allies are never hurt")
	var bursts: int = 0
	for node: Node in tree_root.get_children():
		if node is FireBurst:
			bursts += 1
			track(node)
	assert_eq(bursts, 1, "a small ink-fire explosion bursts where it landed")
	assert_true(data.area_radius <= 120.0, "and it is a small one (%.0f px)" % data.area_radius)


func test_a_fireball_with_no_target_flies_on_and_burns_out() -> void:
	var mage: Ally = _ally("onmyoji", 400.0)
	var ball: Fireball = Fireball.new()
	ball.setup(mage, 10.0, 0.0, 110.0, null, Vector2(2500.0, 830.0))
	tree_root.add_child(ball)
	track(ball)
	ball.global_position = Vector2(500.0, 800.0)
	for i: int in 400:
		if not is_instance_valid(ball) or ball.is_queued_for_deletion():
			break
		ball._physics_process(STEP)
	assert_true(not is_instance_valid(ball) or ball.is_queued_for_deletion() or ball.has_exploded(), "it does not fly forever")


func test_the_fireball_and_the_explosion_are_drawn_over_the_fighters() -> void:
	var ball: Fireball = Fireball.new()
	track(ball)
	ball.setup(null, 1.0, 0.0, 100.0, null, Vector2(100.0, 0.0))
	tree_root.add_child(ball)
	assert_true(ball.z_index > 0, "the ball is drawn over the fighters")
	var burst: FireBurst = FireBurst.new()
	burst.setup(100.0)
	track(burst)
	assert_true(burst.lifetime > 0.3 and burst.lifetime < 0.8, "a short flash of an explosion (%.2f s)" % burst.lifetime)
