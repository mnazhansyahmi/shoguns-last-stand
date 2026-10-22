extends SceneTree

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var checks: RefCounted = load("res://tests/unit/test_boss_sword_motion.gd").new()
	checks.set("tree_root", root)
	checks.call("test_every_boss_attack_keeps_both_grips_and_a_continuous_blade_arc")
	for failure: String in checks.get("failures"): print(failure)
	var failed: bool = not checks.get("failures").is_empty()
	checks.call("cleanup")
	await AudioManager.shutdown_audio(self)
	quit(1 if failed else 0)
