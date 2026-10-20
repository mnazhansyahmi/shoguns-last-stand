extends SceneTree
## Pixel comparison against the original per-frame stain painter. Real renderer required.
## Same random geometry, every spot retained, same fade samples and native 64-segment circles.
class OriginalStain extends Node2D:
	var source: BloodStain

	func _draw() -> void:
		var alpha: float = source.opacity()
		if alpha <= 0.0:
			return
		InkBrush.fill(self, source._blot, Color(InkPalette.BLOOD_DARK, 0.85 * alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, BloodStain.FLATTEN))
		for i: int in source._spots.size():
			draw_circle(source._spots[i] / Vector2(1.0, BloodStain.FLATTEN), source._spot_sizes[i], Color(InkPalette.BLOOD, 0.8 * alpha))
		draw_set_transform(Vector2.ZERO)


func _initialize() -> void:
	_run.call_deferred()


func _viewport() -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(512, 256)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var paper: ColorRect = ColorRect.new()
	paper.size = Vector2(viewport.size)
	paper.color = InkPalette.PAPER
	viewport.add_child(paper)
	return viewport


func _run() -> void:
	var worst: int = 0
	var changed_total: int = 0
	for size_value: float in [1.0, 2.0]:
		for direction: float in [-1.0, 1.0]:
			var actual: SubViewport = _viewport()
			var reference: SubViewport = _viewport()
			var stain: BloodStain = BloodStain.new()
			stain.setup(size_value, direction)
			stain.position = Vector2(192.0, 128.0)
			actual.add_child(stain)
			stain.set_process(false)
			var original: OriginalStain = OriginalStain.new()
			original.source = stain
			original.position = stain.position
			reference.add_child(original)
			for age_value: float in [0.0, 0.1, 0.25, 1.0, 4.0, 8.9]:
				stain.age = age_value
				stain._process(0.0)
				original.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var a: PackedByteArray = actual.get_texture().get_image().get_data()
				var b: PackedByteArray = reference.get_texture().get_image().get_data()
				var changed: int = 0
				for i: int in a.size():
					var difference: int = absi(int(a[i]) - int(b[i]))
					worst = maxi(worst, difference)
					if difference > 1:
						changed += 1
				changed_total += changed
				print("size %.0f direction %.0f age %.2f: channels differing by >1 = %d" % [size_value, direction, age_value, changed])
			actual.free()
			reference.free()
	print("Stain comparison: max channel error %d; channels differing by >1: %d" % [worst, changed_total])
	await AudioManager.shutdown_audio(self)
	quit(0 if changed_total == 0 else 1)
