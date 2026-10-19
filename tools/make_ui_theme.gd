extends SceneTree
## Regenerates the UI theme from InkPalette (see InkThemeBuilder):
##   godot_console --headless --path . -s res://tools/make_ui_theme.gd
## Then run `godot_console --headless --import` so the editor cache picks it up.


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(InkThemeBuilder.THEME_PATH.get_base_dir())
	var error: Error = ResourceSaver.save(InkThemeBuilder.build(), InkThemeBuilder.THEME_PATH)
	print("%s: %s" % [InkThemeBuilder.THEME_PATH, error_string(error)])
	quit(0 if error == OK else 1)
