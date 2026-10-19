extends SceneTree
## Headless test runner:
##   godot_console --headless --path . -s res://tests/run_tests.gd
## Exit code 0 when every test passes, 1 otherwise.
## A test also fails if any engine/script error is logged while it runs, because a
## script error aborts the test function silently and would otherwise look like a pass.

const TEST_SCRIPTS: Array[String] = [
	"res://tests/unit/test_health_component.gd",
	"res://tests/unit/test_combat_components.gd",
	"res://tests/unit/test_summoning.gd",
	"res://tests/unit/test_wave_director.gd",
	"res://tests/unit/test_target_lifetime.gd",
	"res://tests/unit/test_progression.gd",
	"res://tests/unit/test_save_manager.gd",
	"res://tests/unit/test_settings.gd",
	"res://tests/unit/test_touch_controls.gd",
	"res://tests/unit/test_targeting_and_defeat.gd",
	"res://tests/unit/test_game_feel.gd",
]


## Counts errors (not warnings) logged by the engine while tests run.
class ErrorCounter extends Logger:
	var count: int = 0
	var last_message: String = ""

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		count += 1
		var message: String = rationale if not rationale.is_empty() else code
		last_message = "%s (%s:%d in %s)" % [message, file.get_file(), line, function]


var _errors: ErrorCounter = ErrorCounter.new()


func _initialize() -> void:
	OS.add_logger(_errors)
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
			var errors_before: int = _errors.count
			var test_case: RefCounted = script.new()
			test_case.set("tree_root", root)
			test_case.call(test_name)
			test_case.call("cleanup")
			var test_failures: Array[String] = test_case.get("failures")
			if _errors.count > errors_before:
				test_failures.append("%d engine/script error(s) logged, last: %s" % [
					_errors.count - errors_before, _errors.last_message])
			if test_failures.is_empty():
				print("  PASS  %s" % test_name)
			else:
				failed += 1
				print("  FAIL  %s" % test_name)
				for failure: String in test_failures:
					print("        - %s" % failure)
	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	OS.remove_logger(_errors)
	await AudioManager.shutdown_audio(self)
	quit(1 if failed > 0 else 0)
