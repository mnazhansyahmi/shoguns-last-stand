extends SceneTree
## CPU-only attribution, not a frame-budget result. Same manual ticks per figure.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	seed(1337)
	var host: Node2D = Node2D.new()
	host.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(host)
	for kind: InkFigure.Kind in [InkFigure.Kind.HOLLOW_SOLDIER, InkFigure.Kind.ONI_BRUTE,
		InkFigure.Kind.SPECTRAL_ARCHER, InkFigure.Kind.SHIELD_BEARER, InkFigure.Kind.FLYING_SPIRIT, InkFigure.Kind.BURNING_GENERAL]:
		for no_secondary: bool in [false, true]:
			var visual: UnitVisual = UnitVisual.new()
			visual.figure_kind = kind
			visual.figure_height = 150.0
			visual.position = Vector2(500, 600)
			host.add_child(visual)
			visual.play_state(&"windup")
			if no_secondary: visual.get_figure().secondary = null
			for tick: int in 120: visual._process(1.0 / 60.0)
			var total: int = 0
			for sample: int in 3:
				var start: int = Time.get_ticks_usec()
				for tick: int in 1000: visual._process(1.0 / 60.0)
				total += Time.get_ticks_usec() - start
			print("%s secondary=%s | %.3f ms per pose | %d parts" % [InkFigure.Kind.keys()[kind], not no_secondary,
				total / 3000000.0, visual.get_figure().get_child_count()])
			visual.free()
	host.free()
	await AudioManager.shutdown_audio(self)
	quit()
