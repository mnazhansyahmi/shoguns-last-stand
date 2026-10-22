extends "res://tests/test_case.gd"

const ONI: EnemyData = preload("res://data/enemies/oni_brute.tres")
const ENEMY: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const ALLY: PackedScene = preload("res://scenes/allies/ally.tscn")


func _oni() -> Enemy:
	var enemy: Enemy = ENEMY.instantiate()
	enemy.setup(ONI)
	add_to_tree(enemy)
	enemy.call("_change_state", Enemy.State.ATTACK)
	(enemy.get_node("Hitbox") as HitboxComponent).activate(65.0, 100.0)
	return enemy


func _hit(source: Node, heavy: bool = false, spirit: bool = false) -> HitboxComponent:
	var box: HitboxComponent = track(HitboxComponent.new()) as HitboxComponent
	box.source = source
	box.spirit = spirit
	box.faction = Faction.Type.DEFENDERS
	box.knockback_direction_x = 1.0
	box.activate(10, 300, -1.0, heavy)
	return box


func test_light_and_allied_hits_damage_without_stopping_oni_attacks() -> void:
	var player: Player = track(PLAYER.instantiate()) as Player
	var ally: Ally = track(ALLY.instantiate()) as Ally
	for box: HitboxComponent in [_hit(player), _hit(ally), _hit(ally, true), _hit(ally, false, true)]:
		var oni: Enemy = _oni()
		oni.velocity.x = -20.0
		assert_true(oni.get_hurtbox().receive_hit(box), "armour does not block damage")
		assert_almost_eq((oni.get_node("HealthComponent") as HealthComponent).current_health, ONI.max_health - 10.0, "damage still lands")
		assert_eq(oni.get_state(), Enemy.State.ATTACK, "attack is not interrupted")
		assert_true((oni.get_node("Hitbox") as HitboxComponent).is_active(), "active swing continues")
		assert_almost_eq(oni.velocity.x, -20.0, "repeated hits cannot push him back or stall his walk")


func test_player_heavy_and_spirit_hits_pierce_oni_armour() -> void:
	var player: Player = track(PLAYER.instantiate()) as Player
	for box: HitboxComponent in [_hit(player, true), _hit(player, false, true)]:
		var oni: Enemy = _oni()
		assert_true(oni.get_hurtbox().receive_hit(box), "special hit lands")
		assert_eq(oni.get_state(), Enemy.State.HURT, "player heavy/Ultimate or Spirit Slash staggers")
		assert_true(not (oni.get_node("Hitbox") as HitboxComponent).is_active(), "stagger cancels the swing")
		assert_true(oni.velocity.x > 0, "special hit applies resisted knockback")


func test_freed_source_does_not_bypass_armour_or_raise_errors() -> void:
	var source: Node = Node.new()
	var box: HitboxComponent = _hit(source, true)
	source.free()
	var oni: Enemy = _oni()
	assert_true(oni.get_hurtbox().receive_hit(box), "orphaned projectile still deals damage")
	assert_eq(oni.get_state(), Enemy.State.ATTACK, "unknown source is not promoted to a player special")


func test_oni_keeps_his_telegraph_with_faster_approach_and_recovery() -> void:
	assert_almost_eq(ONI.move_speed, 52.0 * 1.25, "walk speed is exactly 25% faster")
	assert_almost_eq(ONI.attack.windup, 0.8, "the readable warning is preserved")
	assert_true(ONI.attack.recovery < 0.9 and ONI.attack.cooldown < 1.0, "less waiting between attacks")
