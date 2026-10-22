extends "res://tests/test_case.gd"


func test_regions_use_different_painted_scenery_and_transparent_layers() -> void:
	assert_true(PaintedWorld.BAMBOO != PaintedWorld.VILLAGE, "region identity is separate artwork")
	for region: Array[Texture2D] in [PaintedWorld.BAMBOO, PaintedWorld.VILLAGE]:
		assert_eq(region.size(), 5, "separate sky, mountains, scenery, earth and grass")
		for index: int in region.size():
			assert_true(PaintedWorld.texels_per_screen_pixel(index) >= 1.0, "native texel density at 1080p and 1.5 zoom, layer %d" % index)
			var first: Rect2 = PaintedWorld.tile_rect(index, 0)
			var next: Rect2 = PaintedWorld.tile_rect(index, 1)
			assert_almost_eq(first.end.x, next.position.x, "neighboring tiles meet without a gap")
		var sky: Image = region[0].get_image()
		assert_true(sky.get_pixelv(sky.get_size() / 2).a > 0.9, "sky is opaque")
		var grass: Image = region[4].get_image()
		assert_true(grass.get_pixelv(Vector2i(grass.get_width() / 2, 20)).a < 0.1, "grass has clean empty space above it")


func test_region_fire_is_bounded_and_damage_switch_preserves_gate_state() -> void:
	var backdrop: RegionBackdrop = add_to_tree(load("res://scenes/backdrops/bamboo_outskirts.tscn").instantiate()) as RegionBackdrop
	var theme: AtmosphereTheme = AtmosphereTheme.new()
	theme.scenery = AtmosphereTheme.Scenery.BURNING_VILLAGE
	backdrop.apply_theme(theme)
	assert_eq(backdrop._painted_fires.size(), 6, "fire quads have a fixed limit")
	for flame: PaintedFlame in backdrop._painted_fires:
		assert_true(flame.visible and flame.texture is AtlasTexture, "burning village uses painted fire")
	var gate: GateVisual = add_to_tree(GateVisual.new()) as GateVisual
	gate.set_damage(0.7)
	gate.apply_region(true)
	assert_almost_eq(gate.get_damage(), 0.7, "changing region preserves damage")
	gate.set_destroyed()
	for flame: PaintedFlame in gate._painted_fires: assert_true(not flame.visible, "destroyed gate stops attached fire")
	theme.scenery = AtmosphereTheme.Scenery.BAMBOO_OUTSKIRTS
	backdrop.apply_theme(theme)
	for flame: PaintedFlame in backdrop._painted_fires: assert_true(not flame.visible, "bamboo has no village blaze")
	Atmosphere.set_theme(null)
