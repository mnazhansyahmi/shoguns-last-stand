extends "res://tests/test_case.gd"


func test_onryo_is_a_full_human_sized_floating_painting_with_ground_shadow() -> void:
	var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate() as Enemy
	enemy.setup(load("res://data/enemies/flying_spirit.tres") as EnemyData)
	add_to_tree(enemy)
	var fig: InkFigure = (enemy.get_node("Visual") as UnitVisual).get_figure()
	assert_true(fig.has_node("OnryoPainting"), "complete onryo body is rendered")
	assert_true(fig.height >= 120, "body reads at human size")
	assert_almost_eq(fig.position.y, -80, "robe floats eighty pixels over ground")
	assert_true(fig.secondary == null, "painted robe uses shader follow-through instead of hidden cloth simulation")
	assert_true((enemy.get("_prop") as EnemyProp)._shadow != null, "shadow stays under the airborne figure")
	assert_true(not (fig.get_node("torso") as FigurePart).visible, "old segmented body does not double over painting")


func test_general_is_taller_than_oni_and_has_bounded_attached_fire() -> void:
	var data: BossData = load("res://data/enemies/burning_general.tres") as BossData
	var oni: EnemyData = load("res://data/enemies/oni_brute.tres") as EnemyData
	assert_true(data.body_size.y > oni.body_size.y * 1.5, "final boss towers above Oni")
	var boss: Boss = load("res://scenes/enemies/boss.tscn").instantiate() as Boss
	boss.setup(data)
	add_to_tree(boss)
	var aura: BurningGeneralVisual = (boss.get("_prop") as EnemyProp)._painted_aura
	assert_true(aura != null, "painted boss aura exists")
	assert_eq(aura._flames.size(), 4, "two shoulder and two blade flames have a fixed count")
	assert_eq(aura._embers.amount, 16, "embers are bounded")


func test_boss_legs_support_the_body_and_contact_steps_are_distance_driven() -> void:
	for kind: InkFigure.Kind in [InkFigure.Kind.FALLEN_DAIMYO, InkFigure.Kind.BURNING_GENERAL]:
		var visual: UnitVisual = UnitVisual.new()
		visual.figure_kind = kind
		add_to_tree(visual)
		visual.set_process(false)
		var spec: FigureKinds.Spec = visual.get_figure().spec
		assert_true(spec.hip_y >= 50 and spec.shin_w.x >= 13, "long, armoured legs support the boss")
		var steps: Array[Vector2] = []
		visual.heavy_step.connect(func(at: Vector2) -> void: steps.append(at))
		visual.play_state(&"run")
		for frame: int in 180:
			visual.position.x += 1.1
			visual._process(1.0 / 60.0)
		assert_true(steps.size() >= 3 and steps.size() < 15, "walking emits bounded contact steps")
		for at: Vector2 in steps: assert_almost_eq(at.y, 0.0, "dust roots at the planted sole")
		visual.play_state(&"idle")
		for frame: int in 60: visual._process(1.0 / 60.0)
		var count: int = steps.size()
		for frame: int in 60: visual._process(1.0 / 60.0)
		assert_eq(steps.size(), count, "stopped bosses do not emit timed footsteps")


func test_boss_bar_never_intersects_player_bars_at_large_ui_scales() -> void:
	var hud: GameHud = add_to_tree(load("res://scenes/ui/game_hud.tscn").instantiate()) as GameHud
	for scale: float in [0.8, 1.0, 1.25, 1.4]:
		hud.apply_layout(Rect2(0, 0, 1920, 1080), Vector2(1920,1080), scale)
		hud.show_boss("The Burning General")
		assert_true(hud.get_boss_bar().position.y >= hud.block_bottom(hud.get_node("%TopLeft") as Control), "boss bar clears player cluster")


func test_boss_bar_holds_damage_then_drains_and_resets_for_the_next_boss() -> void:
	var bar: BossHealthBar = add_to_tree(BossHealthBar.new()) as BossHealthBar
	bar.set_ratio_text(0.6, "60%")
	assert_almost_eq(bar.ghost_ratio, 1.0, "damage leaves a visible drain trail")
	bar._process(0.1)
	assert_almost_eq(bar.ghost_ratio, 1.0, "trail holds briefly")
	bar._process(0.8)
	assert_almost_eq(bar.ghost_ratio, 0.6, "trail catches up")
	bar.set_phase(2)
	assert_true(bar._phase_flash > 0.0, "phase changes trigger feedback")
	bar.reset_health()
	assert_true(bar.phase == 1 and bar.ghost_ratio == 1.0 and bar.ratio == 1.0, "a new boss starts clean")
