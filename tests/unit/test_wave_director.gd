extends "res://tests/test_case.gd"
## WaveDirector flow and softlock protection.

const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")
const ONI_BRUTE: EnemyData = preload("res://data/enemies/oni_brute.tres")

var _container: Node2D


func _make_stage(counts: Array[int]) -> StageData:
	var stage: StageData = StageData.new()
	stage.first_wave_delay = 0.0
	stage.break_duration = 1.0
	for count: int in counts:
		var entry: WaveEntry = WaveEntry.new()
		entry.enemy = HOLLOW_SOLDIER
		entry.count = count
		entry.spawn_interval = 0.5
		var wave: WaveData = WaveData.new()
		wave.entries.append(entry)
		stage.waves.append(wave)
	return stage


func _make_director(stage: StageData) -> WaveDirector:
	_container = add_to_tree(Node2D.new())
	var spawner: EnemySpawner = EnemySpawner.new()
	spawner.container = _container
	spawner.position = Vector2(1800.0, 0.0)
	add_to_tree(spawner)
	var director: WaveDirector = WaveDirector.new()
	director.stage = stage
	director.spawner = spawner
	add_to_tree(director)
	return director


func _living_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child: Node in _container.get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and not enemy.is_dead():
			result.append(enemy)
	return result


## Starts the stage and ticks until every enemy of the current wave has spawned.
func _spawn_whole_wave(director: WaveDirector) -> void:
	director.tick(0.0)
	for i: int in 20:
		director.tick(0.5)


func test_stage_1_resource_matches_spec() -> void:
	var stage: StageData = load("res://data/stages/stage_1.tres") as StageData
	assert_true(stage != null, "stage_1.tres loads as StageData")
	if stage == null:
		return
	assert_eq(stage.waves.size(), 3, "three waves")
	assert_eq(stage.waves[0].get_enemy_count(), 6, "wave 1: 6 enemies")
	assert_eq(stage.waves[1].get_enemy_count(), 9, "wave 2: 9 enemies")
	assert_eq(stage.waves[2].get_enemy_count(), 11, "wave 3: 10 soldiers + 1 Oni Brute")
	assert_true(stage.waves[2].entries[1].enemy == ONI_BRUTE, "wave 3 ends with an Oni Brute")


func test_wave_spawns_with_interval() -> void:
	var director: WaveDirector = _make_director(_make_stage([3]))
	director.start()
	director.tick(0.0)
	assert_eq(_living_enemies().size(), 1, "first enemy spawns immediately")
	director.tick(0.4)
	assert_eq(_living_enemies().size(), 1, "second enemy waits for interval")
	director.tick(0.2)
	assert_eq(_living_enemies().size(), 2, "second enemy spawns after 0.5s")
	assert_eq(director.get_remaining_count(), 3, "remaining counts unspawned and alive")


func test_wave_completes_when_all_enemies_die() -> void:
	var director: WaveDirector = _make_director(_make_stage([3]))
	var cleared: Array[int] = []
	var stage_cleared: Array[int] = [0]
	director.wave_cleared.connect(func(number: int) -> void: cleared.append(number))
	director.stage_cleared.connect(func() -> void: stage_cleared[0] += 1)
	director.start()
	_spawn_whole_wave(director)
	var enemies: Array[Enemy] = _living_enemies()
	assert_eq(enemies.size(), 3, "all enemies spawned")
	enemies[0].get_node("HealthComponent").take_damage(1000.0)
	enemies[1].get_node("HealthComponent").take_damage(1000.0)
	assert_true(cleared.is_empty(), "wave not cleared while an enemy lives")
	assert_eq(director.get_remaining_count(), 1, "one enemy remaining")
	enemies[2].get_node("HealthComponent").take_damage(1000.0)
	assert_eq(cleared, [1], "wave 1 cleared once")
	assert_eq(stage_cleared[0], 1, "single-wave stage cleared")
	assert_true(director.is_complete(), "director complete")


func test_wave_completes_if_enemy_freed_unexpectedly() -> void:
	var director: WaveDirector = _make_director(_make_stage([2]))
	var cleared: Array[int] = []
	director.wave_cleared.connect(func(number: int) -> void: cleared.append(number))
	director.start()
	_spawn_whole_wave(director)
	var enemies: Array[Enemy] = _living_enemies()
	enemies[0].get_node("HealthComponent").take_damage(1000.0)
	# Removed without dying (e.g. deleted by another system): must not softlock the wave.
	enemies[1].free()
	assert_eq(cleared, [1], "wave cleared after an enemy was freed")
	assert_eq(director.get_remaining_count(), 0, "nothing remaining")


func test_dead_enemy_freed_later_is_not_double_counted() -> void:
	var director: WaveDirector = _make_director(_make_stage([2, 1]))
	director.start()
	_spawn_whole_wave(director)
	var enemies: Array[Enemy] = _living_enemies()
	enemies[0].get_node("HealthComponent").take_damage(1000.0)
	enemies[0].free()
	assert_eq(director.get_remaining_count(), 1, "defeat + free counted once")
	assert_true(not director.is_in_break(), "wave still running")


func test_next_wave_waits_for_clear_and_break() -> void:
	var director: WaveDirector = _make_director(_make_stage([1, 2]))
	var started: Array[int] = []
	director.wave_started.connect(func(number: int, _total: int) -> void: started.append(number))
	director.start()
	_spawn_whole_wave(director)
	assert_eq(started, [1], "only wave 1 started")
	director.tick(10.0)
	assert_eq(started, [1], "wave 2 does not start while wave 1 is alive")
	_living_enemies()[0].get_node("HealthComponent").take_damage(1000.0)
	assert_true(director.is_in_break(), "break after wave 1 is cleared")
	director.tick(0.5)
	assert_eq(started, [1], "wave 2 waits for the break")
	director.tick(0.6)
	assert_eq(started, [1, 2], "wave 2 starts after the break")
