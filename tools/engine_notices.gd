extends SceneTree
## Preserve the engine and bundled component notices beside the Windows executable.
func _initialize() -> void:
	var path: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="): path = arg.trim_prefix("out=")
	if path.is_empty():
		quit(2)
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(Engine.get_license_text() + "\n\nEngine component notices:\n" + JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\nComponent license texts:\n")
	var licenses: Dictionary = Engine.get_license_info()
	for name: String in licenses:
		file.store_string("\n\n=== " + name + " ===\n" + str(licenses[name]))
	file.close()
	quit(0)
