extends "res://tests/test_case.gd"
## Playtest feedback, part 1: the Bow and the War Cry look right. The samurai carries a yumi on his back and takes it
## out for the shot (reach, draw, aim, release, stow in half a second, the arrow leaving from the string); the War
## Cry plants his feet, throws the katana up and shouts, a gold ring shows the range and rallied allies flash gold.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const ROSTER: AllyRoster = preload("res://data/allies/roster.tres")
const SFX: SfxLibrary = preload("res://data/audio/sfx_library.tres")
const SAVE_DIR: String = "user://test_saves/"
const FRAME: float = 1.0 / 60.0


func _visual() -> UnitVisual:
	var visual: UnitVisual = UnitVisual.new()
	visual.figure_kind = InkFigure.Kind.SAMURAI
	visual.figure_height = 110.0
	add_to_tree(visual)
	visual.set_process(false)
	return visual


func _tick(visual: UnitVisual, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME - 0.001):
		visual.call(&"_process", FRAME)


func _part(visual: UnitVisual, part_name: String) -> FigurePart:
	return visual.get_figure().get_node(part_name) as FigurePart


func _player() -> Player:
	for action: StringName in [&"attack", &"heavy_attack", &"dash", &"spirit_slash", &"bow", &"war_cry", &"ultimate", &"stance"]:
		Input.action_release(action)
	var player: Player = add_to_tree(PLAYER_SCENE.instantiate()) as Player
	player.global_position = Vector2(500.0, 880.0)
	player.read_input = false
	player.bow_unlocked = true
	player.war_cry_unlocked = true
	return player


func _tick_player(player: Player, seconds: float) -> void:
	for i: int in ceili(seconds / FRAME):
		player._physics_process(FRAME)


func test_the_samurai_carries_a_yumi_on_his_back() -> void:
	var visual: UnitVisual = _visual()
	_tick(visual, 0.3)
	assert_true(visual.get_figure().spec.has_back_bow, "the samurai is the one who carries a yumi")
	assert_true(_part(visual, "yumi_back").visible, "the yumi is slung on his back")
	assert_true(not _part(visual, "bow").visible, "no bow in his hand")
	assert_true(_part(visual, "weapon").visible, "the katana is in his hand")
	assert_true(FigurePainter.part(InkFigure.Kind.SAMURAI, &"yumi_back") != null, "and it is drawn")
	var archer: InkFigure = add_to_tree(InkFigure.new()) as InkFigure
	archer.kind = InkFigure.Kind.YUMI_ARCHER
	assert_true(not archer.spec.has_back_bow, "the archer holds his bow, it is not stowed")


func test_the_bow_shot_takes_the_yumi_out_and_puts_it_back_in_half_a_second() -> void:
	var visual: UnitVisual = _visual()
	_tick(visual, 0.3)
	visual.play_state(&"shoot")
	_tick(visual, 0.2)
	assert_true(_part(visual, "bow").visible, "mid-draw the yumi is in his hand")
	assert_true(not _part(visual, "yumi_back").visible, "and no longer on his back")
	assert_true(not _part(visual, "weapon").visible, "the katana is sheathed")
	assert_true(visual.get_figure().pose.bow_draw > 0.3, "the string is being drawn")
	_tick(visual, 0.4)
	assert_true(not _part(visual, "bow").visible, "after half a second the bow is stowed again")
	assert_true(_part(visual, "yumi_back").visible, "on his back")
	assert_true(_part(visual, "weapon").visible, "and the katana is back in his hand")


func test_the_shot_is_keyed_to_the_players_timing() -> void:
	var stats: PlayerStats = PlayerStats.new()
	assert_almost_eq(stats.bow_windup, FigureKinds.SHOOT_RELEASE_TIME, "the arrow leaves when the string is released")
	assert_almost_eq(stats.bow_windup + stats.bow_recovery, FigureKinds.SHOOT_TIME, "the whole shot is the animation")
	assert_almost_eq(FigureKinds.SHOOT_TIME, 0.5, "about half a second")
	assert_almost_eq(FigureKinds.samurai_shoot(FigureKinds.SHOOT_RELEASE_TIME).bow_draw, 1.0, "fully drawn at the release")
	assert_true(FigureKinds.samurai_shoot(FigureKinds.SHOOT_RELEASE_TIME + 0.05).bow_draw < 0.1, "the string snaps forward just after")
	var previous: float = -1.0
	for step: int in 8:
		var draw: float = FigureKinds.samurai_shoot(0.14 + 0.02 * float(step)).bow_draw
		assert_true(draw >= previous, "the draw only grows (%.2f at step %d)" % [draw, step])
		previous = draw
	assert_almost_eq(FigureKinds.samurai_shoot(0.0).sheathed, 0.0, "he starts with the katana in hand")
	assert_almost_eq(FigureKinds.samurai_shoot(FigureKinds.SHOOT_TIME).sheathed, 0.0, "and ends with it")


func test_his_arms_never_stretch_during_the_bow_or_the_war_cry() -> void:
	var visual: UnitVisual = _visual()
	var figure: InkFigure = visual.get_figure()
	var reach: float = figure.spec.upper_arm + figure.spec.fore_arm
	var poses: Array[FigurePose] = [FigureKinds.samurai_war_cry_gather(), FigureKinds.pose(InkFigure.Kind.SAMURAI, &"war_cry")]
	for step: int in 31:
		poses.append(FigureKinds.samurai_shoot(0.02 * float(step)))
	for pose: FigurePose in poses:
		figure.pose.copy_from(pose)
		figure.refresh()
		assert_true(figure.spec.shoulder_front.distance_to(figure.front_hand) <= reach + 0.05, "front arm reaches (%.1f)" % figure.spec.shoulder_front.distance_to(figure.front_hand))
		assert_true(figure.spec.shoulder_back.distance_to(figure.back_hand) <= reach + 0.05, "back arm reaches (%.1f)" % figure.spec.shoulder_back.distance_to(figure.back_hand))


func test_the_war_cry_katana_stays_clear_of_his_body() -> void:
	var figure: InkFigure = _visual().get_figure()
	for pose: FigurePose in [FigureKinds.samurai_war_cry_gather(), FigureKinds.pose(InkFigure.Kind.SAMURAI, &"war_cry")]:
		figure.pose.copy_from(pose)
		figure.refresh()
		var zones: Array[PackedVector2Array] = FigureKinds.samurai_body_zones(pose)
		var inside: int = 0
		var along: float = 6.0
		while along <= FigurePainter.KATANA_LENGTH:
			var point: Vector2 = figure.root_xf.affine_inverse() * figure.get_weapon_point(along)
			for zone: PackedVector2Array in zones:
				if Geometry2D.is_point_in_polygon(point, zone):
					inside += 1
					break
			along += 2.0
		assert_eq(inside, 0, "the katana is clear of him in the War Cry")


func test_the_arrow_leaves_from_the_bow_string() -> void:
	var player: Player = _player()
	var start: Vector2 = player.global_position
	player.use_skill(&"bow")
	var arrows: Array[Arrow] = []
	for frame: int in 60:
		# There is no floor in the test: hold him still so the nock is where the arrow started.
		player.global_position = start
		player.velocity = Vector2.ZERO
		player._physics_process(FRAME)
		for child: Node in player.get_parent().get_children():
			if child is Arrow and not arrows.has(child):
				arrows.append(child as Arrow)
				track(child)
		if not arrows.is_empty():
			break
	assert_eq(arrows.size(), 1, "one arrow flew")
	if arrows.size() != 1:
		return
	player.global_position = start
	var visual: UnitVisual = player.get("_visual") as UnitVisual
	var nock: Vector2 = visual.bow_nock_global()
	# The arrow's tail (26 px behind its origin) is on the string, in front of him and about at his shoulder.
	var tail: Vector2 = arrows[0].spawn_position - Vector2(26.0 * float(player.facing), 0.0)
	assert_true(tail.distance_to(nock) < 1.0, "the tail of the arrow starts at the nock (%s against %s)" % [str(tail), str(nock)])
	assert_true(absf(nock.x - start.x) < 60.0, "close to the samurai, not out in front of him")
	assert_true(nock.y < start.y - 60.0 and nock.y > start.y - 130.0, "at shoulder height (%.0f above the feet)" % (start.y - nock.y))


func test_the_war_cry_has_its_own_pose_and_the_shout_sound() -> void:
	var player: Player = _player()
	player.use_skill(&"war_cry")
	player._physics_process(FRAME)
	var visual: UnitVisual = player.get("_visual") as UnitVisual
	assert_eq(visual.get_state(), &"war_cry", "the samurai plays the War Cry animation, not the Ultimate's cast")
	var figure: InkFigure = visual.get_figure()
	_tick(visual, 0.2)
	assert_true(figure.pose.blade > 0.3 and figure.pose.crouch > 5.0, "first he gathers: crouched, katana low")
	_tick(visual, 0.3)
	assert_true(figure.pose.blade < -1.2, "then the katana is raised high (blade %.2f)" % figure.pose.blade)
	assert_true(figure.pose.spread > 1.7, "his feet planted wide")
	assert_true(figure.pose.head_tilt < -0.1, "his head thrown back to shout")
	assert_true(SFX.find(&"war_cry") != null, "the shout has its own sound")
	assert_true(SFX.find(&"war_cry").stream != null, "which exists")


func test_the_ring_reaches_the_full_range_and_allies_flash_gold_as_it_passes() -> void:
	var ring: WarCryRing = WarCryRing.new()
	ring.setup(700.0, Vector2(30.0, -90.0), 1.0)
	track(ring)
	ring.age = WarCryRing.EXPAND_TIME
	assert_almost_eq(ring.reach(), 700.0, "the ring grows out to the 700 px range of the cry", 0.01)
	ring.age = WarCryRing.EXPAND_TIME * 0.5
	assert_true(ring.reach() > 350.0 and ring.reach() < 700.0, "bursting out fast")
	assert_true(WarCryRing.time_to_reach(100.0, 700.0) < WarCryRing.time_to_reach(500.0, 700.0), "near allies are reached first")
	assert_almost_eq(WarCryRing.time_to_reach(700.0, 700.0), WarCryRing.EXPAND_TIME, "the far edge at the end of the burst")
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path: String = SAVE_DIR + "war_cry_anim_save.json"
	SaveManager.new(path).save_progress(PlayerProgress.new())
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", path)
	field.set("settings_path", SAVE_DIR + "war_cry_anim_settings.cfg")
	add_to_tree(field)
	var at_him: Ally = _ally(500.0)
	var far: Ally = _ally(1100.0)
	field.call(&"_on_war_cry_released", Vector2(500.0, 880.0))
	var rings: int = 0
	for node: Node in field.find_children("*", "", true, false):
		if node is WarCryRing:
			rings += 1
	assert_eq(rings, 1, "a gold ring bursts out")
	assert_almost_eq((at_him.get_node("Visual") as UnitVisual).get_figure().gold_flash, 1.0, "an ally at his side flashes gold at once")
	var far_figure: InkFigure = (far.get_node("Visual") as UnitVisual).get_figure()
	assert_almost_eq(far_figure.gold_flash, 0.0, "a distant one waits for the ring")
	for i: int in 40:
		far._tick_war_cry(FRAME)
	assert_true(far_figure.gold_flash > 0.9, "and flashes when it arrives")
	var visual: UnitVisual = far.get_node("Visual") as UnitVisual
	visual.set_process(false)
	_tick(visual, UnitVisual.GOLD_FLASH_TIME + 0.1)
	assert_almost_eq(far_figure.gold_flash, 0.0, "the flash is brief")


func _ally(x: float) -> Ally:
	var ally: Ally = ALLY_SCENE.instantiate() as Ally
	ally.setup(ROSTER.find("ashigaru"), x)
	add_to_tree(ally)
	ally.global_position = Vector2(x, 880.0)
	return ally
