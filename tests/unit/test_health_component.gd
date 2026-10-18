extends "res://tests/test_case.gd"


func _make_health(max_hp: float = 100.0) -> HealthComponent:
	var health: HealthComponent = track(HealthComponent.new())
	health.max_health = max_hp
	return health


func test_starts_at_max_health() -> void:
	var health: HealthComponent = _make_health(200.0)
	assert_almost_eq(health.current_health, 200.0, "current health starts at max")
	assert_true(not health.is_dead(), "not dead at start")


func test_take_damage_reduces_health() -> void:
	var health: HealthComponent = _make_health(100.0)
	var applied: float = health.take_damage(30.0)
	assert_almost_eq(applied, 30.0, "returns applied damage")
	assert_almost_eq(health.current_health, 70.0, "health reduced by damage")


func test_overkill_clamps_at_zero() -> void:
	var health: HealthComponent = _make_health(50.0)
	var applied: float = health.take_damage(80.0)
	assert_almost_eq(applied, 50.0, "applied damage capped at remaining health")
	assert_almost_eq(health.current_health, 0.0, "health clamps at zero")
	assert_true(health.is_dead(), "dead at zero health")


func test_ignores_zero_and_negative_damage() -> void:
	var health: HealthComponent = _make_health(100.0)
	assert_almost_eq(health.take_damage(0.0), 0.0, "zero damage ignored")
	assert_almost_eq(health.take_damage(-25.0), 0.0, "negative damage ignored")
	assert_almost_eq(health.current_health, 100.0, "health unchanged")


func test_heal_restores_and_caps_at_max() -> void:
	var health: HealthComponent = _make_health(100.0)
	health.take_damage(40.0)
	assert_almost_eq(health.heal(15.0), 15.0, "returns applied healing")
	assert_almost_eq(health.current_health, 75.0, "health increased by heal")
	assert_almost_eq(health.heal(500.0), 25.0, "healing capped at missing health")
	assert_almost_eq(health.current_health, 100.0, "health capped at max")
	assert_almost_eq(health.heal(10.0), 0.0, "no healing at full health")


func test_cannot_heal_when_dead() -> void:
	var health: HealthComponent = _make_health(30.0)
	health.take_damage(30.0)
	assert_almost_eq(health.heal(20.0), 0.0, "dead entities cannot be healed")
	assert_true(health.is_dead(), "still dead after heal attempt")


func test_died_emitted_exactly_once() -> void:
	var health: HealthComponent = _make_health(100.0)
	var died_count: Array[int] = [0]
	health.died.connect(func() -> void: died_count[0] += 1)
	health.take_damage(60.0)
	assert_eq(died_count[0], 0, "died not emitted while alive")
	health.take_damage(60.0)
	health.take_damage(60.0)
	health.take_damage(1.0)
	assert_eq(died_count[0], 1, "died emitted exactly once")
	assert_almost_eq(health.take_damage(10.0), 0.0, "no damage applied after death")


func test_reset_revives_and_allows_dying_again() -> void:
	var health: HealthComponent = _make_health(100.0)
	var died_count: Array[int] = [0]
	health.died.connect(func() -> void: died_count[0] += 1)
	health.take_damage(100.0)
	health.reset()
	assert_true(not health.is_dead(), "alive after reset")
	assert_almost_eq(health.current_health, 100.0, "full health after reset")
	health.take_damage(100.0)
	assert_eq(died_count[0], 2, "died emitted once per life")


func test_invulnerability_blocks_damage_until_it_expires() -> void:
	var health: HealthComponent = _make_health(100.0)
	health.set_invulnerable_for(0.5)
	assert_almost_eq(health.take_damage(20.0), 0.0, "invulnerable blocks damage")
	health.tick_invulnerability(0.6)
	assert_true(not health.is_invulnerable(), "invulnerability expired")
	assert_almost_eq(health.take_damage(20.0), 20.0, "damage applies after expiry")


func test_health_changed_reports_values() -> void:
	var health: HealthComponent = _make_health(80.0)
	var last: Array[float] = [-1.0, -1.0]
	health.health_changed.connect(func(current: float, maximum: float) -> void:
		last[0] = current
		last[1] = maximum)
	health.take_damage(30.0)
	assert_almost_eq(last[0], 50.0, "health_changed current")
	assert_almost_eq(last[1], 80.0, "health_changed maximum")
