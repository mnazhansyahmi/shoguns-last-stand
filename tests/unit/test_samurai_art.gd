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


func test_only_the_samurai_uses_the_new_skin_and_keeps_his_bow() -> void:
	for kind: InkFigure.Kind in [InkFigure.Kind.SAMURAI, InkFigure.Kind.HATAMOTO]:
		var figure: InkFigure = InkFigure.new()
		figure.kind = kind
		add_to_tree(figure)
		var torso: FigurePart = figure.get_node("torso") as FigurePart
		assert_true((torso.art != null) == (kind == InkFigure.Kind.SAMURAI), "the skin is scoped to its approved hero")
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
