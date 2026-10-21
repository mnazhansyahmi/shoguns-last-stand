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
