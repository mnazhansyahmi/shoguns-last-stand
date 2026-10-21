extends "res://tests/test_case.gd"
## Painted layers must follow the existing skeleton, share cached resources, and leave
## unrelated characters and gameplay equipment intact.


func test_painted_limb_anchors_match_the_skeleton_joints() -> void:
	for part_name: StringName in SamuraiSpriteArt.JOINTS:
		var anchors: Array = SamuraiSpriteArt.JOINTS[part_name]
		var frame: Transform2D = SamuraiSpriteArt.frame(part_name)
		assert_true((frame * (anchors[0] as Vector2)).length() < 0.001, "%s starts at its bone origin" % part_name)
		assert_true((frame * (anchors[1] as Vector2)).distance_to(Vector2(float(anchors[2]), 0.0)) < 0.001,
				"%s ends at its actual bone length" % part_name)


func test_painted_parts_are_cached_and_atlas_regions_stay_in_the_source() -> void:
	var source: Image = Image.load_from_file("res://assets/art/samurai/slim_parts.png")
	var full: Rect2 = Rect2(Vector2.ZERO, Vector2(source.get_size()))
	for part_name: StringName in SamuraiSpriteArt.SOURCES:
		assert_true(full.encloses(SamuraiSpriteArt.SOURCES[part_name]), "%s is inside the atlas" % part_name)
		assert_true(SamuraiSpriteArt.texture(part_name) == SamuraiSpriteArt.texture(part_name), "%s shares one texture" % part_name)
		assert_true(SamuraiSpriteArt.texture(part_name).filter_clip, "%s cannot sample its neighbour" % part_name)


func test_painted_characters_keep_their_distinct_equipment() -> void:
	for kind: InkFigure.Kind in [InkFigure.Kind.SAMURAI, InkFigure.Kind.HATAMOTO]:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		add_to_tree(figure)
		var torso: FigurePart = figure.get_node("torso") as FigurePart
		assert_true(torso.art != null, "the approved painted theme covers the hero and his retainer")
		if kind == InkFigure.Kind.SAMURAI:
			assert_true(not figure.has_node("pauldron_front") and figure.has_node("mane"), "hair and light clothing replace shoulder armour")
			assert_true(figure.spec.has_back_bow and figure.has_node("bow"), "Bow retains its rig and equipment")
			assert_true(figure.get_node("foot_f").get("art") != null, "sandals use the independent planted-foot frame")


func test_original_art_has_transparent_backgrounds_and_solid_character_pixels() -> void:
	for path: String in ["res://assets/art/samurai/slim_parts.png", "res://assets/art/samurai/slim_menu.png"]:
		var image: Image = Image.load_from_file(path)
		assert_true(image != null and not image.is_empty(), "%s loads" % path)
		if image == null or image.is_empty():
			continue
		assert_true(image.get_pixel(0, 0).a == 0.0, "the corner is alpha, not painted paper")
		var opaque: bool = false
		for y: int in range(0, image.get_height(), 24):
			for x: int in range(0, image.get_width(), 24):
				if image.get_pixel(x, y).a > 0.95:
					opaque = true
		assert_true(opaque, "the character's ink has a solid core")


func test_every_ally_and_enemy_has_its_own_cached_painted_body() -> void:
	var seen: Dictionary = {}
	for kind: InkFigure.Kind in RosterSpriteArt.NAMES:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		add_to_tree(figure)
		for name: StringName in [&"head", &"torso", &"thigh_f", &"shin_f", &"foot_f", &"upper_f", &"fore_f"]:
			var part: FigurePart = figure.get_node(NodePath(name)) as FigurePart
			assert_true(part.art != null, "%s %s uses painted art" % [kind, name])
			assert_true(part.art == RosterSpriteArt.texture(kind, name), "instances share each registered layer")
			assert_true(not RosterSpriteArt.bounds(kind, name).is_empty(), "opaque silhouette is available for ground checks")
		assert_true(not seen.has(RosterSpriteArt.atlas(kind)), "each costume has distinct art")
		seen[RosterSpriteArt.atlas(kind)] = true


func test_roster_limb_joint_registration_preserves_every_bone_length() -> void:
	for kind: InkFigure.Kind in RosterSpriteArt.NAMES:
		var spec: FigureKinds.Spec = FigureKinds.spec(kind)
		for name: StringName in [&"thigh_f", &"shin_f", &"upper_f", &"fore_f", &"thigh_b", &"shin_b"]:
			var source: Rect2 = RosterSpriteArt.region(kind, RosterSpriteArt.CELLS[name])
			var transform: Transform2D = RosterSpriteArt.frame(kind, name)
			var start: Vector2 = transform * (source.size * Vector2(0.12, 0.5))
			var end: Vector2 = transform * (source.size * Vector2(0.88, 0.5))
			if kind == InkFigure.Kind.ONI_BRUTE and String(name).begins_with("upper"):
				start = transform * (source.size * Vector2(0.15, 0.32))
				end = transform * (source.size * Vector2(0.88, 0.70))
			var length: float = spec.thigh if String(name).begins_with("thigh") else spec.shin
			if String(name).begins_with("upper"): length = spec.upper_arm
			if String(name).begins_with("fore"): length = spec.fore_arm
			assert_true(start.length() < 0.001, "painted limb starts at the solved joint")
			assert_almost_eq(end.x, length, "painted limb ends at the solved joint", 0.001)
			assert_almost_eq(end.y, 0.0, "registration does not introduce a diagonal offset", 0.001)


func test_painted_shoulders_have_no_open_sockets() -> void:
	for kind: InkFigure.Kind in RosterSpriteArt.NAMES:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		add_to_tree(figure)
		var torso_region: Rect2 = RosterSpriteArt.region(kind, RosterSpriteArt.CELLS[&"torso"])
		var atlas_size: Vector2 = RosterSpriteArt.atlas(kind).get_size()
		var torso: FigurePart = figure.get_node("torso") as FigurePart
		# The Hollow Soldier's torso is a torn rag with no armhole to close (and he is most of every battle).
		assert_eq(not torso.art_patch.is_empty(), RosterSpriteArt.ARMHOLES.has(kind), "%s: an open armhole is closed" % kind)
		if RosterSpriteArt.ARMHOLES.has(kind):
			for uv: Vector2 in (torso.art_patch[3] as PackedVector2Array):
				assert_true(Rect2(torso_region.position / atlas_size, torso_region.size / atlas_size).grow(0.0001).has_point(uv),
						"%s: the patch only samples the torso's own paint" % kind)
			var order: Array[StringName] = FigurePainter.layout(kind)
			assert_true(order.find(&"upper_f") < order.find(&"shoulder_f") and order.find(&"shoulder_f") < order.find(&"fore_f"),
					"%s: the shoulder cap covers the upper arm's root but not the forearm" % kind)
			assert_true(not (figure.get_node("shoulder_f") as FigurePart).art_patch.is_empty(), "%s: the cap is painted torso" % kind)
		for arm: StringName in [&"upper_f", &"upper_b"]:
			var trim: float = (figure.get_node(NodePath(arm)) as FigurePart).art_trim
			var width: float = RosterSpriteArt.region(kind, RosterSpriteArt.CELLS[arm]).size.x
			assert_true(trim > width * 0.12 and trim < width * 0.25, "%s %s is drawn from its shoulder joint, without its open sleeve end" % [kind, arm])
		for pauldron: String in ["pauldron_front", "pauldron_back"]:
			if figure.has_node(pauldron):
				assert_true(not (figure.get_node(pauldron) as CanvasItem).visible, "%s: no second sleeve tube on the shoulder" % kind)


func test_the_samurai_holds_the_hilt_and_has_no_flat_coat_tail() -> void:
	var order: Array[StringName] = FigurePainter.layout(InkFigure.Kind.SAMURAI)
	assert_true(order.find(&"weapon") < order.find(&"fore_f"), "the front hand closes over the hilt")
	var figure: InkFigure = InkFigure.new()
	add_to_tree(figure)
	assert_true(not (figure.get_node("hem") as CanvasItem).visible, "his painted skirt has its own torn hem")
	assert_true(not (figure.get_node("skirt") as FigurePart).art_mesh.is_empty(), "the skirt is drawn through its own outline")


func test_the_ponytail_never_folds_into_a_blot() -> void:
	# A chain bunched up by a sudden stop: it doubles back on itself.
	var bunched: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(-6, 2), Vector2(-9, 7), Vector2(-5, 9),
			Vector2(-1, 6), Vector2(-3, 2)])
	var length: float = 0.0
	for i: int in range(1, bunched.size()):
		length += bunched[i].distance_to(bunched[i - 1])
	var spine: PackedVector2Array = SamuraiSpriteArt.hair_spine(bunched)
	var axis: Vector2 = (spine[-1] - spine[0]).normalized()
	assert_true(spine[0].distance_to(spine[-1]) >= length * SamuraiSpriteArt.HAIR_MIN_SPAN - 0.001, "it keeps its length")
	for i: int in range(1, spine.size()):
		assert_true((spine[i] - spine[i - 1]).dot(axis) > 0.0, "it never turns back on itself (point %d)" % i)
	assert_eq(spine[0], bunched[0], "it still grows from the hair tie")


func test_bows_are_slim_painted_wood() -> void:
	assert_true(FigurePainter.BOW_LIMB_WIDTH.x <= 4.0 and FigurePainter.BOW_LIMB_WIDTH.y < FigurePainter.BOW_LIMB_WIDTH.x,
			"a yumi limb is slim and tapers to its tip")
	var figure: InkFigure = InkFigure.new()
	figure.kind = InkFigure.Kind.HATAMOTO
	add_to_tree(figure)
	assert_true(figure.has_node("banner") and figure.has_node("hem"), "the sashimono keeps its pole and its painted flag")


func test_every_head_stays_on_its_body_in_every_pose() -> void:
	var states: Array[StringName] = [&"idle", &"run", &"windup", &"heavy_windup", &"strike", &"cast", &"dash", &"hurt", &"dead"]
	for kind: int in InkFigure.Kind.size():
		for state: StringName in states:
			var visual: UnitVisual = UnitVisual.new()
			add_to_tree(visual)
			visual.configure(kind as InkFigure.Kind, 100.0)
			visual.set_process(false)
			visual.play_state(&"idle")
			for i: int in 20: visual._process(1.0 / 60.0)
			visual.play_state(state)
			for i: int in 20: visual._process(1.0 / 60.0)
			var figure: InkFigure = visual.get_figure()
			var head: Node2D = figure.get_node("head")
			var torso: Node2D = figure.get_node("torso")
			var painted: bool = kind == InkFigure.Kind.SAMURAI
			var head_shape: PackedVector2Array = SamuraiSpriteArt.bounds(&"head") if painted else RosterSpriteArt.bounds(kind as InkFigure.Kind, &"head")
			var torso_shape: PackedVector2Array = SamuraiSpriteArt.bounds(&"torso") if painted else RosterSpriteArt.bounds(kind as InkFigure.Kind, &"torso")
			var on_torso: PackedVector2Array = (torso.transform.affine_inverse() * head.transform) * head_shape
			var overlap: float = 0.0
			for shared: PackedVector2Array in Geometry2D.intersect_polygons(on_torso, torso_shape):
				overlap += absf(SamuraiSpriteArt._area(shared))
			assert_true(overlap >= 4.0, "%s %s: the head sits on the body (%.1f units² overlap)" % [InkFigure.Kind.keys()[kind], state, overlap])


func test_gripping_hands_draw_over_their_weapons() -> void:
	var states: Array[StringName] = [&"idle", &"run", &"windup", &"strike", &"cast", &"hurt"]
	for kind: int in InkFigure.Kind.size():
		for state: StringName in states:
			var visual: UnitVisual = UnitVisual.new()
			add_to_tree(visual)
			visual.configure(kind as InkFigure.Kind, 100.0)
			visual.set_process(false)
			visual.play_state(state)
			for i: int in 12: visual._process(1.0 / 60.0)
			var figure: InkFigure = visual.get_figure()
			var name: String = "%s %s" % [InkFigure.Kind.keys()[kind], state]
			var front: int = figure.get_node("fore_f").get_index()
			for held: String in ["weapon", "bow"]:
				if figure.has_node(held):
					assert_true(front > figure.get_node(held).get_index(), "%s: the front hand's fingers are over the %s" % [name, held])
			if not is_nan(figure.spec.back_hand_on_weapon.x):
				assert_true(figure.has_node("grip_b"), "%s: a two-handed grip draws its back hand over the hilt" % name)
				var grip: FigurePart = figure.get_node("grip_b") as FigurePart
				assert_true(grip.get_index() > figure.get_node("weapon").get_index(), "%s: the back hand wraps the hilt" % name)
				assert_true(grip.art != null and grip.art_trim > 0.0, "%s: only the painted fist is drawn again" % name)
