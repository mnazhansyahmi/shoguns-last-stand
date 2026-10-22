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
	assert_eq(aura._flames.size(), 3, "shoulder/weapon flames have a fixed count")
	assert_eq(aura._embers.amount, 16, "embers are bounded")


func test_boss_bar_never_intersects_player_bars_at_large_ui_scales() -> void:
	var hud: GameHud = add_to_tree(load("res://scenes/ui/game_hud.tscn").instantiate()) as GameHud
	for scale: float in [0.8, 1.0, 1.25, 1.4]:
		hud.apply_layout(Rect2(0, 0, 1920, 1080), Vector2(1920,1080), scale)
		hud.show_boss("The Burning General")
		assert_true(hud.get_boss_bar().position.y >= hud.block_bottom(hud.get_node("%TopLeft") as Control), "boss bar clears player cluster")
