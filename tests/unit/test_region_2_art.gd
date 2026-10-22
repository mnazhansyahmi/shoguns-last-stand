extends "res://tests/test_case.gd"

const ENEMY: PackedScene = preload("res://scenes/enemies/enemy.tscn")


func test_region_two_enemies_use_distinct_painted_kinds_without_body_tints() -> void:
	var seen: Dictionary = {}
	for name: String in ["spectral_archer", "shield_bearer", "flying_spirit", "burning_general"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % name)
		assert_eq(RosterSpriteArt.NAMES[data.figure], name, "data uses its own painted atlas")
		assert_eq(data.tint, Color.WHITE, "the new body is not a tinted substitute")
		assert_true(not seen.has(data.figure), "each new enemy has a distinct kind")
		seen[data.figure] = true
		var atlas: Texture2D = RosterSpriteArt.atlas(data.figure)
		assert_true(atlas.get_width() >= 1200, "painting has roster detail resolution")
		assert_eq(RosterAtlasRegions.REGIONS[data.figure].size(), 16, "same atlas contract")


func test_flying_spirit_has_a_visible_painted_body_and_no_leg_nodes() -> void:
	var enemy: Enemy = ENEMY.instantiate()
	enemy.setup(load("res://data/enemies/flying_spirit.tres") as EnemyData)
	add_to_tree(enemy)
	var figure: InkFigure = (enemy.get_node("Visual") as UnitVisual).get_figure()
	assert_true(figure.visible and (figure.get_node("head") as FigurePart).art != null, "painted onryo replaces the hidden placeholder")
	for part: String in ["thigh_f", "thigh_b", "shin_f", "shin_b", "foot_f", "foot_b", "weapon"]:
		assert_true(not figure.has_node(NodePath(part)), "the onryo has no " + part)
	assert_almost_eq(figure.position.y, -enemy.data.hover_height, "paint floats with the air hurtbox", 0.01)


func test_shield_break_keeps_the_bearers_painted_body_and_hands() -> void:
	var enemy: Enemy = ENEMY.instantiate()
	enemy.setup(load("res://data/enemies/shield_bearer.tres") as EnemyData)
	add_to_tree(enemy)
	var figure: InkFigure = (enemy.get_node("Visual") as UnitVisual).get_figure()
	var prop: EnemyProp = enemy.get("_prop") as EnemyProp
	assert_true(prop.is_shield_up(), "painted tate starts intact")
	enemy.call(&"_break_shield")
	assert_true(not prop.is_shield_up(), "break animation follows real shield state")
	assert_true((figure.get_node("torso") as FigurePart).art != null, "breaking the shield leaves the body visible")
	assert_true(figure.get_node("fore_f").get_index() > figure.get_node("weapon").get_index(), "closed sword hand covers its hilt")
