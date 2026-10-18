extends "res://tests/test_case.gd"
## SpiritEnergy and SummonManager validation.

const ASHIGARU: AllyData = preload("res://data/allies/ashigaru.tres")
const ARCHER: AllyData = preload("res://data/allies/yumi_archer.tres")


func _make_energy(amount: float) -> SpiritEnergy:
	var energy: SpiritEnergy = SpiritEnergy.new()
	energy.starting_energy = amount
	add_to_tree(energy)
	return energy


func _make_summoner(energy: SpiritEnergy, max_allies: int = 6) -> SummonManager:
	var container: Node2D = add_to_tree(Node2D.new())
	var summoner: SummonManager = SummonManager.new()
	summoner.ally_slots = [ASHIGARU, ARCHER]
	summoner.energy = energy
	summoner.container = container
	summoner.max_allies = max_allies
	summoner.position = Vector2(400.0, 0.0)
	add_to_tree(summoner)
	return summoner


func test_ally_data_matches_spec() -> void:
	assert_almost_eq(ASHIGARU.max_health, 120.0, "Ashigaru health")
	assert_almost_eq(ASHIGARU.attack_damage, 14.0, "Ashigaru damage")
	assert_almost_eq(ASHIGARU.cost, 30.0, "Ashigaru cost")
	assert_true(not ASHIGARU.is_ranged, "Ashigaru is melee")
	assert_almost_eq(ARCHER.max_health, 70.0, "Archer health")
	assert_almost_eq(ARCHER.attack_damage, 12.0, "Archer damage")
	assert_almost_eq(ARCHER.cost, 45.0, "Archer cost")
	assert_true(ARCHER.is_ranged, "Archer is ranged")


func test_energy_regenerates_and_caps_at_max() -> void:
	var energy: SpiritEnergy = _make_energy(0.0)
	assert_almost_eq(energy.max_energy, 150.0, "max energy is 150")
	energy.tick(2.0)
	assert_almost_eq(energy.current, 10.0, "regenerates 5 per second")
	energy.tick(100.0)
	assert_almost_eq(energy.current, 150.0, "capped at max")


func test_summon_consumes_energy() -> void:
	var energy: SpiritEnergy = _make_energy(100.0)
	var summoner: SummonManager = _make_summoner(energy)
	var result: SummonManager.Result = summoner.request_summon(0)
	assert_eq(result, SummonManager.Result.OK, "Ashigaru summon succeeds")
	assert_almost_eq(energy.current, 70.0, "30 energy consumed")
	assert_eq(summoner.get_ally_count(), 1, "one ally on the field")
	result = summoner.request_summon(1)
	assert_eq(result, SummonManager.Result.OK, "Archer summon succeeds")
	assert_almost_eq(energy.current, 25.0, "45 more energy consumed")
	assert_eq(summoner.get_ally_count(), 2, "two allies on the field")


func test_summon_rejected_without_enough_energy() -> void:
	var energy: SpiritEnergy = _make_energy(20.0)
	var summoner: SummonManager = _make_summoner(energy)
	var failures_seen: Array[int] = []
	summoner.summon_failed.connect(func(_slot: int, result: SummonManager.Result) -> void: failures_seen.append(result))
	var result: SummonManager.Result = summoner.request_summon(0)
	assert_eq(result, SummonManager.Result.NOT_ENOUGH_ENERGY, "rejected for energy")
	assert_almost_eq(energy.current, 20.0, "no energy spent on rejection")
	assert_eq(summoner.get_ally_count(), 0, "no ally spawned")
	assert_eq(failures_seen, [SummonManager.Result.NOT_ENOUGH_ENERGY], "summon_failed emitted once")


func test_summon_respects_cooldown() -> void:
	var energy: SpiritEnergy = _make_energy(150.0)
	var summoner: SummonManager = _make_summoner(energy)
	summoner.request_summon(0)
	assert_eq(summoner.request_summon(0), SummonManager.Result.ON_COOLDOWN, "second summon blocked by cooldown")
	assert_almost_eq(energy.current, 120.0, "no energy spent while on cooldown")
	summoner.tick(ASHIGARU.summon_cooldown + 0.01)
	assert_eq(summoner.request_summon(0), SummonManager.Result.OK, "summon allowed after cooldown")


func test_summon_respects_max_units() -> void:
	var energy: SpiritEnergy = _make_energy(150.0)
	var summoner: SummonManager = _make_summoner(energy, 1)
	summoner.request_summon(0)
	assert_eq(summoner.request_summon(1), SummonManager.Result.MAX_UNITS, "unit cap enforced")
	assert_almost_eq(energy.current, 120.0, "no energy spent at cap")


func test_dead_ally_frees_a_unit_slot() -> void:
	var energy: SpiritEnergy = _make_energy(150.0)
	var summoner: SummonManager = _make_summoner(energy, 1)
	var allies: Array[Ally] = []
	summoner.ally_summoned.connect(func(ally: Ally, _slot: int) -> void: allies.append(ally))
	summoner.request_summon(0)
	allies[0].get_health().take_damage(1000.0)
	assert_eq(summoner.get_ally_count(), 0, "dead ally no longer counted")
	assert_eq(summoner.request_summon(1), SummonManager.Result.OK, "can summon again after a death")


func test_invalid_slot_rejected() -> void:
	var summoner: SummonManager = _make_summoner(_make_energy(150.0))
	assert_eq(summoner.request_summon(5), SummonManager.Result.INVALID_SLOT, "unknown slot rejected")
	assert_eq(summoner.request_summon(-1), SummonManager.Result.INVALID_SLOT, "negative slot rejected")
