extends "res://tests/test_case.gd"
## Hitbox/hurtbox rules: faction checks, one hit per target per attack, invulnerability.


func _make_target(faction: Faction.Type, max_hp: float = 100.0) -> HurtboxComponent:
	var owner_node: Node2D = add_to_tree(Node2D.new())
	var health: HealthComponent = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = max_hp
	owner_node.add_child(health)
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.faction = faction
	hurtbox.health_component = health
	owner_node.add_child(hurtbox)
	return hurtbox


func _make_hitbox(faction: Faction.Type) -> HitboxComponent:
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.faction = faction
	add_to_tree(hitbox)
	return hitbox


func test_hit_damages_hostile_target() -> void:
	var hurtbox: HurtboxComponent = _make_target(Faction.Type.ENEMIES)
	var hitbox: HitboxComponent = _make_hitbox(Faction.Type.DEFENDERS)
	hitbox.activate(20.0, 0.0, 1.0)
	assert_true(hitbox.try_hit(hurtbox), "hostile hit lands")
	assert_almost_eq(hurtbox.health_component.current_health, 80.0, "damage applied")


func test_one_hit_per_target_per_activation() -> void:
	var hurtbox: HurtboxComponent = _make_target(Faction.Type.ENEMIES)
	var hitbox: HitboxComponent = _make_hitbox(Faction.Type.DEFENDERS)
	hitbox.activate(20.0, 0.0, 1.0)
	hitbox.try_hit(hurtbox)
	assert_true(not hitbox.try_hit(hurtbox), "second hit in same attack rejected")
	assert_almost_eq(hurtbox.health_component.current_health, 80.0, "damage applied once")
	hitbox.activate(20.0, 0.0, 1.0)
	assert_true(hitbox.try_hit(hurtbox), "new attack instance can hit again")
	assert_almost_eq(hurtbox.health_component.current_health, 60.0, "second attack applied")


func test_no_friendly_fire() -> void:
	var hurtbox: HurtboxComponent = _make_target(Faction.Type.DEFENDERS)
	var hitbox: HitboxComponent = _make_hitbox(Faction.Type.DEFENDERS)
	hitbox.activate(20.0, 0.0, 1.0)
	assert_true(not hitbox.try_hit(hurtbox), "same-faction hit rejected")
	assert_almost_eq(hurtbox.health_component.current_health, 100.0, "no damage to allies")


func test_inactive_hitbox_deals_no_damage() -> void:
	var hurtbox: HurtboxComponent = _make_target(Faction.Type.ENEMIES)
	var hitbox: HitboxComponent = _make_hitbox(Faction.Type.DEFENDERS)
	assert_true(not hitbox.try_hit(hurtbox), "inactive hitbox cannot hit")
	hitbox.activate(20.0, 0.0, 1.0)
	hitbox.deactivate()
	assert_true(not hitbox.try_hit(hurtbox), "deactivated hitbox cannot hit")
	assert_almost_eq(hurtbox.health_component.current_health, 100.0, "no damage")


func test_invulnerable_target_is_not_hit() -> void:
	var hurtbox: HurtboxComponent = _make_target(Faction.Type.ENEMIES)
	hurtbox.health_component.set_invulnerable_for(1.0)
	var hitbox: HitboxComponent = _make_hitbox(Faction.Type.DEFENDERS)
	hitbox.activate(20.0, 0.0, 1.0)
	assert_true(not hitbox.try_hit(hurtbox), "invulnerable target ignored")
	assert_almost_eq(hurtbox.health_component.current_health, 100.0, "no damage while invulnerable")


func test_knockback_uses_fixed_direction() -> void:
	var hurtbox: HurtboxComponent = _make_target(Faction.Type.ENEMIES)
	var received: Array[HitData] = []
	hurtbox.hit_received.connect(func(hit: HitData) -> void: received.append(hit))
	var hitbox: HitboxComponent = _make_hitbox(Faction.Type.DEFENDERS)
	hitbox.knockback_direction_x = -1.0
	hitbox.activate(10.0, 300.0, 1.0)
	hitbox.try_hit(hurtbox)
	assert_eq(received.size(), 1, "hit_received emitted once")
	if received.size() == 1:
		assert_almost_eq(received[0].knockback.x, -300.0, "knockback follows fixed direction")


func test_faction_layers_only_see_hostile_hurtboxes() -> void:
	assert_eq(Faction.hostile_hurtbox_mask(Faction.Type.DEFENDERS), Faction.hurtbox_layer(Faction.Type.ENEMIES), "defender hitbox masks enemy hurtboxes")
	assert_eq(Faction.hostile_hurtbox_mask(Faction.Type.ENEMIES), Faction.hurtbox_layer(Faction.Type.DEFENDERS), "enemy hitbox masks defender hurtboxes")


func test_cooldown_component() -> void:
	var cooldown: CooldownComponent = track(CooldownComponent.new())
	cooldown.duration = 3.0
	var finished: Array[int] = [0]
	cooldown.cooldown_finished.connect(func() -> void: finished[0] += 1)
	assert_true(cooldown.is_available(), "available before start")
	cooldown.start()
	cooldown.tick(2.9)
	assert_true(not cooldown.is_available(), "still cooling down at 2.9s")
	cooldown.tick(0.2)
	assert_true(cooldown.is_available(), "available after 3s")
	cooldown.tick(1.0)
	assert_eq(finished[0], 1, "cooldown_finished emitted once")
