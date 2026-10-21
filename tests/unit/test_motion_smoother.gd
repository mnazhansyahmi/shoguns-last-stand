extends "res://tests/test_case.gd"
## Movement is drawn between physics ticks: the smoother puts a body's drawn children between its last two tick
## positions without moving the body itself, snaps on a teleport, and the battle camera follows the drawn position.


func _make_body() -> Node2D:
	var body: Node2D = Node2D.new()
	var visual: Node2D = Node2D.new()
	visual.name = "Visual"
	visual.position = Vector2(4.0, -7.0)
	body.add_child(visual)
	add_to_tree(body)
	return body


func test_the_drawn_position_lies_between_the_last_two_ticks() -> void:
	var body: Node2D = _make_body()
	var visual: Node2D = body.get_node("Visual")
	var smoother: MotionSmoother = MotionSmoother.attach(body, [visual] as Array[Node2D])
	body.position = Vector2(100.0, 50.0)
	smoother.snap()
	body.position.x += 10.0
	smoother._physics_process(1.0 / 60.0)
	smoother._process(1.0 / 165.0)
	var shown: Vector2 = smoother.get_display_position()
	assert_true(shown.x >= 100.0 - 0.001 and shown.x <= 110.0 + 0.001, "between the previous and the latest tick (got %s)" % shown)
	assert_almost_eq(shown.y, 50.0, "no vertical drift")
	assert_eq(body.position, Vector2(110.0, 50.0), "the body itself stays on the tick")
	assert_almost_eq(visual.global_position.x, shown.x + 4.0, "the visual is drawn at the in-between position")
	assert_almost_eq(visual.global_position.y, 43.0, "keeping its own offset")


func test_a_teleport_snaps_instead_of_sliding() -> void:
	var body: Node2D = _make_body()
	var visual: Node2D = body.get_node("Visual")
	var smoother: MotionSmoother = MotionSmoother.attach(body, [visual] as Array[Node2D])
	body.position.x += 10.0
	smoother._physics_process(1.0 / 60.0)
	smoother._process(1.0 / 165.0)
	body.position = Vector2(900.0, 0.0)
	smoother._process(1.0 / 165.0)
	assert_eq(smoother.get_display_position(), Vector2(900.0, 0.0), "moved outside physics: drawn where it is")
	assert_eq(visual.position, Vector2(4.0, -7.0), "and the visual is back on the body")
	body.position.x += 500.0
	smoother._physics_process(1.0 / 60.0)
	smoother._process(1.0 / 165.0)
	assert_eq(smoother.get_display_position(), Vector2(1400.0, 0.0), "a jump of more than SNAP_DISTANCE in one tick also snaps")


func test_a_flipped_body_gets_its_offset_in_its_own_space() -> void:
	var body: Node2D = _make_body()
	var visual: Node2D = body.get_node("Visual")
	body.scale.x = -1.0
	var smoother: MotionSmoother = MotionSmoother.attach(body, [visual] as Array[Node2D])
	body.position.x -= 12.0
	smoother._physics_process(1.0 / 60.0)
	smoother._process(1.0 / 165.0)
	assert_almost_eq(visual.global_position.x, smoother.get_display_position().x - 4.0, "a projectile flying left is drawn in-between too")


func test_the_camera_follows_where_the_player_is_drawn() -> void:
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	add_to_tree(player)
	var camera: BattleCamera = BattleCamera.new()
	add_to_tree(camera)
	camera.look_ahead = 0.0
	camera.bounds_left = -100000.0
	camera.bounds_right = 100000.0
	camera.target = player
	player.global_position = Vector2(1000.0, 880.0)
	(player.get_node("MotionSmoother") as MotionSmoother).snap()
	player.global_position.x += 3.5
	(player.get_node("MotionSmoother") as MotionSmoother)._physics_process(1.0 / 60.0)
	assert_almost_eq(camera.get_desired_x(), player.get_display_position().x, "the view aims at the drawn samurai, not the tick")
