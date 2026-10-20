extends SceneTree
## Real mixer ownership regression, separate from the synchronous unit runner.
## Does not read or write player saves/settings. Works headless and with a real renderer.
var _failed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for paused_music: bool in [false, true]:
		var manager: AudioManager = AudioManager.new()
		root.add_child(manager)
		_check(manager.play_music_track(&"menu", 0.0), "menu MP3 starts")
		var menu_stream: WeakRef = weakref(manager.get_music_player().stream)
		var menu_playback: WeakRef = weakref(manager.get_music_player().get_stream_playback())
		_check(manager.play_music_track(&"boss", 1.6), "crossfade and ambience start")
		manager.get_music_player().stream_paused = paused_music
		manager.get_ambience_player().stream_paused = paused_music
		manager.play_sfx(&"button_click")
		manager.stop_all()
		manager.stop_all()
		manager.free() # The fallback must drain even after stop_all already cleared its players.
		for frame: int in 3:
			await process_frame
		_check(menu_stream.get_ref() == null, "menu resource released (paused=%s)" % paused_music)
		_check(menu_playback.get_ref() == null, "mixer playback released (paused=%s)" % paused_music)
	var audio: AudioManager = AudioManager.instance
	_check(audio.play_music_track(&"menu", 0.0), "autoload menu starts")
	var final_stream: WeakRef = weakref(audio.get_music_player().stream)
	var final_playback: WeakRef = weakref(audio.get_music_player().get_stream_playback())
	await AudioManager.shutdown_audio(self)
	_check(final_stream.get_ref() == null and final_playback.get_ref() == null, "async shutdown releases stream and playback")
	_check(not AudioManager.play_music(&"menu") and not AudioManager.play(&"button_click"), "shutdown rejects late playback")
	print("Audio shutdown ownership: %s" % ("FAIL" if _failed else "PASS"))
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	print("%s: %s" % ["PASS" if condition else "FAIL", message])
	_failed = _failed or not condition
