extends "res://tests/test_case.gd"


func test_living_scene_keeps_face_hands_feet_and_rock_rigid() -> void:
	for point: Vector2 in [Vector2(0.80, 0.15), Vector2(0.74, 0.46), Vector2(0.86, 0.44), Vector2(0.77, 0.92), Vector2(0.878, 0.94), Vector2(0.9, 0.92)]:
		var weights: Color = LivingMenuPainting.motion_weights(point)
		assert_true(weights.r == 0 and weights.g == 0 and weights.b == 0, "anatomy/contact is pinned in the scene")
	assert_true(LivingMenuPainting.motion_weights(Vector2(0.92, 0.07)).r > 0.9, "ponytail tips move")
	assert_true(LivingMenuPainting.motion_weights(Vector2(0.97, 0.48)).g > 0.9, "free sash moves")
	assert_true(LivingMenuPainting.motion_weights(Vector2(0.96, 0.73)).b > 0.9, "free robe hem moves")


func test_reduced_motion_reaches_the_unified_scene_shader() -> void:
	var painting: LivingMenuPainting = add_to_tree(LivingMenuPainting.new()) as LivingMenuPainting
	painting.set_time(2.0)
	assert_true(painting.material == null, "the static landscape has no deformation material")
	assert_almost_eq((painting._character.material as ShaderMaterial).get_shader_parameter("motion_time"), 2.0, "character time advances")
	painting.reduced_motion = true
	painting.set_time(3.0)
	assert_almost_eq((painting._character.material as ShaderMaterial).get_shader_parameter("motion_amount"), 0.15, "reduced character motion")
	var cutout: Image = LivingMenuPainting.CHARACTER.get_image()
	assert_true(cutout.get_pixel(500, 200).a < 0.01, "background is absent from character texture")
	assert_true(cutout.get_pixel(1360, 300).a > 0.9, "character torso is solid")
	assert_eq(painting._character.get_child_count(), 0, "no limb rig on menu")
	assert_almost_eq(painting._character.scale.x, painting._character.scale.y, "cutout retains its painted proportions")
