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
	assert_eq(backdrop._fire_fields.size(), 2, "two bounded batches at scenery and ground depths")
	for field: VillageFireField in backdrop._fire_fields:
		assert_true(field.visible and field.sites.size() <= 24, "village fire sites are bounded")
	var gate: GateVisual = add_to_tree(GateVisual.new()) as GateVisual
	gate.set_damage(0.7)
	gate.apply_region(true)
	assert_almost_eq(gate.get_damage(), 0.7, "changing region preserves damage")
	gate.set_destroyed()
	for flame: PaintedFlame in gate._painted_fires: assert_true(not flame.visible, "destroyed gate stops attached fire")
	theme.scenery = AtmosphereTheme.Scenery.BAMBOO_OUTSKIRTS
	backdrop.apply_theme(theme)
	for field: VillageFireField in backdrop._fire_fields: assert_true(not field.visible, "bamboo has no village blaze")
	Atmosphere.set_theme(null)


func test_village_fires_attach_to_architecture_and_vary_by_stage() -> void:
	var a: Array[Dictionary] = VillageFireField.layout("burning_market")
	var b: Array[Dictionary] = VillageFireField.layout("ash_road")
	assert_true(a != b and a == VillageFireField.layout("burning_market"), "per-stage layout is varied and repeatable")
	var phases: Dictionary = {}
	var sizes: Dictionary = {}
	var theme: AtmosphereTheme = AtmosphereTheme.new()
	theme.scenery = AtmosphereTheme.Scenery.BURNING_VILLAGE
	for site: Dictionary in a:
		var rect: Rect2 = PaintedWorld.tile_rect(2, site.tile, theme)
		var uv: Vector2 = VillageFireField.ANCHORS[site.anchor]
		if posmod(site.tile, 2) == 1: uv.x = 1.0 - uv.x
		assert_true((site.position as Vector2).is_equal_approx(rect.position + uv * rect.size), "fire root stays on its painted roof/window/fence even on mirrored tiles")
		phases[site.phase] = true
		sizes[site.size] = true
	assert_eq(phases.size(), a.size(), "fires never share a phase")
	assert_eq(sizes.size(), a.size(), "fire sizes vary")
	for site: Dictionary in VillageFireField.layout("burning_market", true):
		assert_true(site.position.y >= 880 and site.size.y <= 55, "ground fires stay small and at ground depth")
