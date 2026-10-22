extends "res://tests/test_case.gd"
const BOSSES: Array[BossData] = [preload("res://data/enemies/fallen_daimyo.tres"), preload("res://data/enemies/burning_general.tres")]
const MAX_DEGREES_PER_60HZ_FRAME: float = 24.0


func test_every_boss_attack_keeps_both_grips_and_a_continuous_blade_arc() -> void:
	var maximum: float = 0.0
	var cases: int = 0
	for data: BossData in BOSSES:
		for phase: int in [1, 2, 3]:
			for facing: int in [-1, 1]:
				for attack: BossAttackData in data.attacks:
					var boss: Boss = load("res://scenes/enemies/boss.tscn").instantiate() as Boss
					boss.setup(data)
					var holder: Node2D = add_to_tree(Node2D.new()) as Node2D
					holder.add_child(boss)
					boss.set_physics_process(false)
					boss.phase = phase
					boss.call("_set_facing", facing)
					var visual: UnitVisual = boss.get_node("Visual") as UnitVisual
					visual.set_process(false)
					boss.call("_begin_attack", attack)
					var figure: InkFigure = visual.get_figure()
					var last_angle: float = figure.weapon_xf.get_rotation()
					var steps_seen: Dictionary = {}
					var frames: int = 0
					var worst: float = 0.0
					var worst_attachment: float = 0.0
					var clearance_turn: float = 0.0
					var reach_error: float = 0.0
					var order_valid: bool = true
					while boss.get_current_attack() != null and frames < 2400:
						boss.call("_process_attack", 1.0 / 60.0)
						if boss.get("_step") == Boss.Step.AIR and float(boss.get("_step_time")) >= Boss.LEAP_AIR_TIME / boss.get_phase_data().speed_multiplier:
							boss.call("_land")
						visual._process(1.0 / 60.0)
						steps_seen[boss.get("_step")] = true
						var angle: float = figure.weapon_xf.get_rotation()
						worst = maxf(worst, absf(rad_to_deg(angle_difference(last_angle, angle))))
						last_angle = angle
						worst_attachment = maxf(worst_attachment, (figure.torso_xf * figure.front_hand).distance_to(figure.weapon_xf.origin))
						worst_attachment = maxf(worst_attachment, (figure.torso_xf * figure.back_hand).distance_to(figure.weapon_xf * figure.spec.back_hand_on_weapon))
						clearance_turn = maxf(clearance_turn, absf(angle_difference(figure.pose.blade, figure.weapon_local.get_rotation())))
						var reach: float = figure.spec.upper_arm + figure.spec.fore_arm
						reach_error = maxf(reach_error, figure.spec.shoulder_front.distance_to(figure.front_hand) - reach)
						reach_error = maxf(reach_error, figure.spec.shoulder_back.distance_to(figure.back_hand) - reach)
						if figure.weapon_behind_body:
							order_valid = order_valid and figure.get_node("weapon").get_index() < figure.get_node("torso").get_index()
						order_valid = order_valid and figure.front_elbow.x >= figure.spec.shoulder_front.x - 0.1 and figure.back_elbow.x >= figure.spec.shoulder_back.x - 0.1
						frames += 1
					var label: String = "%s %s phase %d facing %d" % [data.display_name, attack.id, phase, facing]
					maximum = maxf(maximum, worst)
					cases += 1
					assert_true(worst <= MAX_DEGREES_PER_60HZ_FRAME, "%s maximum angle jump %.2f degrees (limit 24)" % [label, worst])
					assert_true(worst_attachment < 0.01, label + " both wrists remain on the hilt")
					assert_true(clearance_turn < 0.001, "%s clearance correction %.3f degrees" % [label, rad_to_deg(clearance_turn)])
					assert_true(reach_error < 0.01, label + " both grips remain within unscaled arm reach")
					assert_true(order_valid, label + " elbows stay on their forward pole and the raised blade sits behind the torso")
					assert_true(steps_seen.has(Boss.Step.RECOVER) and frames < 2400, label + " completes all combo repeats and recovers")
					holder.free()
	print("Boss sword regression: %d complete attacks/combos, max %.3f degrees per 60-Hz frame (limit 24)." % [cases, maximum])


func test_sword_motion_has_the_same_speed_limit_at_30_and_120_fps() -> void:
	for fps: float in [30, 120]:
		var pose: FigurePose = BossSwordMotion.key_pose(&"recover", BossAttackData.Kind.SLAM)
		var motion: BossSwordMotion = BossSwordMotion.new()
		for stage: StringName in [&"windup", &"strike", &"recover"]:
			motion.begin(stage, BossAttackData.Kind.SLAM, 0.3, pose)
			for frame: int in int(fps):
				var before: float = pose.blade
				motion.step(pose, 1.0 / fps)
				assert_true(absf(pose.blade - before) <= BossSwordMotion.MAX_ANGULAR_SPEED / fps + 0.001, "angular rate is bounded independent of refresh rate")
