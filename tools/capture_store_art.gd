extends SceneTree
## Store cover composed by the real renderer from the game's existing art.
var _out: String = "res://builds/store_materials/cover.png"

class Cover extends Control:
	func _draw() -> void:
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(760, 0), Vector2(760, 1000), Vector2(0, 1000)]),
				PackedColorArray([Color(InkPalette.INK, 0.95), Color(InkPalette.INK, 0.82), Color(InkPalette.INK, 0.92), Color(InkPalette.INK, 0.96)]))
		draw_polygon(PackedVector2Array([Vector2(760, 0), Vector2(1000, 0), Vector2(1000, 1000), Vector2(760, 1000)]),
				PackedColorArray([Color(InkPalette.INK, 0.82), Color(InkPalette.INK, 0.0), Color(InkPalette.INK, 0.0), Color(InkPalette.INK, 0.92)]))
		var font: Font = get_theme_font("font", "TitleLabel")
		for line: Array in [["SHOGUN'S", 290.0, 92], ["LAST", 425.0, 130], ["STAND", 560.0, 130]]:
			var at: Vector2 = Vector2(65, line[1])
			draw_string_outline(font, at, line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[2], 5, InkPalette.INK)
			draw_string(font, at, line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[2], InkPalette.GOLD_BRIGHT)
		draw_polygon(PackedVector2Array([Vector2(67, 595), Vector2(617, 590), Vector2(602, 611), Vector2(65, 615)]), PackedColorArray([InkPalette.SAMURAI_RED]))
		draw_string(get_theme_default_font(), Vector2(70, 712), "PUBLIC PLAYTEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, InkPalette.PARCHMENT)
		draw_string(get_theme_default_font(), Vector2(70, 760), "Fight. Summon. Defend.", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, InkPalette.PARCHMENT_DIM)


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="): _out = arg.trim_prefix("out=")
	DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
	DisplayServer.window_set_size(Vector2i(630, 500))
	root.content_scale_size = Vector2i(1260, 1000)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_run.call_deferred()


func _run() -> void:
	var back: ColorRect = ColorRect.new()
	back.size = Vector2(1260, 1000)
	back.color = InkPalette.INK
	root.add_child(back)
	var backdrop: RegionBackdrop = load("res://scenes/backdrops/bamboo_outskirts.tscn").instantiate() as RegionBackdrop
	backdrop.front_fog = false
	backdrop.scale = Vector2.ONE * 0.85
	backdrop.position = Vector2(-330, -30)
	root.add_child(backdrop)
	for layer: Node in backdrop.get_children():
		if layer is BackdropLayer: layer.reference_center = Vector2(630, 500)
	var rock: Sprite2D = Sprite2D.new()
	rock.texture = preload("res://assets/art/samurai/title_rock.png")
	rock.centered = false
	rock.scale = Vector2.ONE * 0.65
	rock.position = Vector2(335, 815)
	rock.modulate = Color(0.65, 0.62, 0.72)
	root.add_child(rock)
	var hero: PortraitMotion = PortraitMotion.new()
	hero.scale = Vector2.ONE * (760.0 / PortraitMotion.ART_HEIGHT)
	hero.position = Vector2(925, 938)
	root.add_child(hero)
	var cover: Cover = Cover.new()
	cover.size = Vector2(1260, 1000)
	root.add_child(cover)
	for i: int in 10: await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(_out)
	print("Store cover: %s (%s)" % [_out, error_string(error)])
	await AudioManager.shutdown_audio(self)
	quit(0 if error == OK else 1)
