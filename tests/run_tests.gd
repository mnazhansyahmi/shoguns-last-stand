extends SceneTree
## Headless test runner:
##   godot_console --headless --path . -s res://tests/run_tests.gd
## Exit code 0 when every test passes, 1 otherwise.

const TEST_SCRIPTS: Array[String] = [
	"res://tests/unit/test_health_component.gd",
	"res://tests/unit/test_combat_components.gd",
	"res://tests/unit/test_summoning.gd",
	"res://tests/unit/test_wave_director.gd",
]


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	# Wait one frame so the root is inside the tree and added nodes get _ready().
	await process_frame
	var total: int = 0
	var failed: int = 0
	for path: String in TEST_SCRIPTS:
		var script: GDScript = load(path) as GDScript
		if script == null:
			print("FAIL  could not load %s" % path)
			failed += 1
			continue
		print("%s" % path.get_file())
		for method: Dictionary in script.get_script_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			total += 1
			var test_case: RefCounted = script.new()
			test_case.set("tree_root", root)
			test_case.call(test_name)
			test_case.call("cleanup")
			var test_failures: Array[String] = test_case.get("failures")
			if test_failures.is_empty():
				print("  PASS  %s" % test_name)
			else:
				failed += 1
				print("  FAIL  %s" % test_name)
				for failure: String in test_failures:
					print("        - %s" % failure)
	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)
