extends "res://tests/test_case.gd"
## Music, recorded sound effects and credits: the four music slots and the crossfade, the recorded sounds that
## replace the generated ones (with the generated ones as the fallback), the Credits screen (the creator line and the
## music credit only), and the rule that every third-party asset in the project is recorded in docs/ASSET_LICENSES.md.

const MUSIC_LIBRARY: MusicLibrary = preload("res://data/audio/music_library.tres")
const SFX_LIBRARY: SfxLibrary = preload("res://data/audio/sfx_library.tres")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main_menu/main_menu.tscn")
const STAGE_SELECT_SCENE: PackedScene = preload("res://scenes/stage_select/stage_select.tscn")
const CREDITS_SCENE: PackedScene = preload("res://scenes/credits/credits.tscn")
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/battlefield/battlefield.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ALLY_SCENE: PackedScene = preload("res://scenes/allies/ally.tscn")
const DAIMYO: BossData = preload("res://data/enemies/fallen_daimyo.tres")
const KENNEY_DIR: String = "res://assets/audio/sfx_kenney/"
const REQUIRED_CREDIT: String = "Free Music : MOMIZizm MUSiC - https://music.storyinvention.com/en/"
const SAVE_DIR: String = "user://test_saves/"
## The sounds that now come from Kenney: how many takes each has.
const RECORDED: Dictionary = {&"hit": 4, &"heavy_hit": 3, &"gate_hit": 3, &"button_click": 3, &"summon": 1}
const GORE_DIR: String = "res://assets/audio/sfx_gore/"
## The Pixabay gore sounds: sound id -> how many takes (picked at random) it has.
const GORE: Dictionary = {&"sword_swing": 2, &"flesh_hit": 3, &"flesh_heavy": 1, &"spirit_slash": 1, &"spirit_flesh": 2,
		&"enemy_death": 6}
const SONNISS_DIR: String = "res://assets/audio/sfx_sonniss/"
## The Sonniss sounds: sound id -> how many takes it has, and the generated sound each falls back to.
const SONNISS: Dictionary = {&"roar": 1, &"slam": 2, &"stone_hit": 2, &"explosion": 1, &"gate_destroyed": 1,
		&"boss_summon": 1, &"spirit_whoosh": 1, &"ultimate_ready": 1}


func _manager() -> AudioManager:
	var manager: AudioManager = AudioManager.new()
	add_to_tree(manager)
	return manager


func test_stop_all_releases_players_and_fades_and_is_reusable() -> void:
	var manager: AudioManager = _manager()
	manager.play_music_track(&"menu", 0.0)
	manager.play_music_track(&"boss", 1.6)
	manager.play_sfx(&"button_click")
	manager.stop_all()
	manager.stop_all()
	assert_eq(manager.current_music, &"", "no current music after cleanup")
	assert_true(manager.get("_music_tween") == null and manager.get("_ambience_tween") == null, "fade callbacks are released")
	for node: Node in manager.find_children("*", "AudioStreamPlayer", true, false):
		var player: AudioStreamPlayer = node as AudioStreamPlayer
		assert_true(not player.playing and player.stream == null and not player.has_stream_playback(), "%s drops its stream and playback" % player.name)
	assert_true(manager.play_music_track(&"menu", 0.0), "stop_all is reusable during the game; shutdown is terminal")


# --- Music ----------------------------------------------------------------------------

func test_there_are_four_music_slots_and_each_has_a_real_track() -> void:
	for slot: StringName in [&"menu", &"stage_select", &"battle", &"boss"]:
		var entry: MusicEntry = MUSIC_LIBRARY.find(slot)
		assert_true(entry != null, "there is a %s slot" % slot)
		if entry == null:
			continue
		var path: String = entry.resolve_path()
		assert_true(not path.is_empty(), "%s has a file that exists" % slot)
		assert_true(path.begins_with("res://assets/audio/music/"), "%s plays something from the music folder" % slot)
		assert_true(load(path) is AudioStream, "%s loads as audio" % slot)
		assert_true(entry.volume_db <= -6.0, "%s is quieter than the sound effects (%.0f dB)" % [slot, entry.volume_db])
	var paths: Dictionary = {}
	for slot: StringName in [&"menu", &"stage_select", &"battle", &"boss"]:
		paths[MUSIC_LIBRARY.find(slot).resolve_path()] = true
	assert_eq(paths.size(), 4, "each slot has its own track")


func test_the_stage_select_prefers_the_tokaido_track_when_it_is_there() -> void:
	var entry: MusicEntry = MUSIC_LIBRARY.find(&"stage_select")
	assert_eq(entry.prefer_keyword, "tokaido", "it asks for the Tokaido track")
	var has_tokaido: bool = false
	for file: String in DirAccess.get_files_at(MusicEntry.MUSIC_DIR):
		has_tokaido = has_tokaido or file.to_lower().contains("tokaido")
	if has_tokaido:
		assert_true(entry.resolve_path().to_lower().contains("tokaido"), "so it plays it")
	else:
		assert_true(entry.resolve_path().contains("Honobono"), "without it the teahouse track plays")
	var probe: MusicEntry = MusicEntry.new()
	probe.prefer_keyword = "honobono"
	probe.paths = PackedStringArray(["res://assets/audio/music/does_not_exist.ogg"])
	assert_true(probe.resolve_path().ends_with("Honobono Teahouse_Loop.ogg"), "a keyword finds a track, a looping .ogg first")
	probe.prefer_keyword = "no_such_track_xyz"
	assert_eq(probe.resolve_path(), "", "no keyword match and no file: no music, not an error")


func test_the_music_loops_and_plays_on_the_music_bus() -> void:
	var manager: AudioManager = _manager()
	assert_true(manager.play_music_track(&"battle", 0.0), "the battle track starts")
	assert_eq(manager.current_music, &"battle", "it is the current slot")
	assert_true(manager.is_music_playing(), "and is playing")
	var player: AudioStreamPlayer = manager.get_music_player()
	assert_eq(player.bus, AudioManager.MUSIC_BUS, "on the Music bus (the Music volume slider)")
	assert_almost_eq(player.volume_db, MUSIC_LIBRARY.find(&"battle").volume_db, "at the slot's volume")
	assert_true((player.stream as AudioStreamOggVorbis).loop, "and loops")
	manager.play_music_track(&"menu", 0.0)
	assert_true((manager.get_music_player().stream as AudioStreamMP3).loop, "an mp3 track loops too")


func test_changing_the_slot_crossfades_and_the_same_slot_does_nothing() -> void:
	var manager: AudioManager = _manager()
	manager.play_music_track(&"battle", 0.0)
	var first: AudioStreamPlayer = manager.get_music_player()
	assert_true(manager.play_music_track(&"battle", 1.6), "asking for the same slot again is fine")
	assert_true(manager.get_music_player() == first, "and does not restart it")
	manager.play_music_track(&"boss", AudioManager.MUSIC_FADE_TIME)
	var second: AudioStreamPlayer = manager.get_music_player()
	assert_true(second != first, "the boss track plays on the other player")
	assert_true(first.playing and second.playing, "both play during the fade: a crossfade")
	assert_almost_eq(second.volume_db, AudioManager.MUSIC_SILENT_DB, "the new track starts silent and fades in", 0.5)
	assert_eq(manager.current_music, &"boss", "the boss slot is current")
	assert_true(AudioManager.MUSIC_FADE_TIME >= 1.0, "the fade is long enough to hear (%.1f s)" % AudioManager.MUSIC_FADE_TIME)
	manager.play_music_track(&"menu", 0.0)
	assert_true(manager.get_music_player().playing, "a hard cut leaves the new track playing")
	assert_true(not manager.play_music_track(&"no_such_slot", 0.0), "an unknown slot plays nothing")
	assert_eq(manager.current_music, &"menu", "and the music stays as it was")
	manager.stop_music(0.0)
	assert_true(not manager.is_music_playing(), "stop_music stops it")


func test_music_follows_the_scenes() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var audio: AudioManager = AudioManager.instance
	if audio == null:
		return
	var menu: Node = MAIN_MENU_SCENE.instantiate()
	menu.set("save_path", SAVE_DIR + "music_menu_save.json")
	menu.set("settings_path", SAVE_DIR + "music_menu_settings.cfg")
	add_to_tree(menu)
	assert_eq(audio.current_music, &"menu", "the main menu plays the calm track")
	var select: Node = STAGE_SELECT_SCENE.instantiate()
	if "save_path" in select:
		select.set("save_path", SAVE_DIR + "music_select_save.json")
	add_to_tree(select)
	assert_eq(audio.current_music, &"stage_select", "the stage select plays its own")
	var field: Node = BATTLEFIELD_SCENE.instantiate()
	field.set("save_path", SAVE_DIR + "music_field_save.json")
	field.set("settings_path", SAVE_DIR + "music_field_settings.cfg")
	add_to_tree(field)
	assert_eq(audio.current_music, &"battle", "a battle plays the battle track")
	var spawner: EnemySpawner = field.get_node("World/EnemySpawner") as EnemySpawner
	var boss: Enemy = spawner.spawn(DAIMYO)
	track(boss)
	assert_eq(audio.current_music, &"boss", "the boss's arrival switches to the most intense track")
	var credits: Node = CREDITS_SCENE.instantiate()
	add_to_tree(credits)
	assert_eq(audio.current_music, &"menu", "the credits screen goes back to the calm track")


func test_the_music_volume_setting_drives_the_music_bus() -> void:
	var bus: int = AudioServer.get_bus_index(GameSettings.MUSIC_BUS)
	assert_true(bus >= 0, "there is a Music bus")
	var settings: GameSettings = GameSettings.new()
	settings.music_volume = 0.5
	settings.apply_audio()
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), "the slider's half is -6 dB on the Music bus", 0.05)
	settings.music_volume = 0.0
	settings.apply_audio()
	assert_true(AudioServer.get_bus_volume_db(bus) <= -60.0 or AudioServer.is_bus_mute(bus), "all the way down is silent")
	settings.music_volume = 0.8
	settings.apply_audio()


# --- Sound effects -----------------------------------------------------------------------

func test_the_weak_generated_sounds_are_replaced_by_kenney_sounds() -> void:
	var manager: AudioManager = _manager()
	for id: StringName in RECORDED:
		assert_true(manager.uses_recorded_sfx(id), "%s plays a recorded sound" % id)
		assert_eq(manager.get_sfx_variant_count(id), RECORDED[id], "%s has %d takes" % [id, RECORDED[id]])
		assert_true(manager.play_sfx(id), "%s plays" % id)
		var entry: SfxEntry = SFX_LIBRARY.find(id)
		assert_true(entry.stream != null, "%s still has its generated sound as the fallback" % id)
	for id: StringName in [&"dash", &"victory", &"defeat", &"ultimate", &"heal", &"magic_burst", &"war_cry"]:
		assert_true(not manager.uses_recorded_sfx(id), "%s keeps its generated sound" % id)
		assert_eq(manager.get_sfx_variant_count(id), 1, "%s has one sound" % id)


func test_the_sonniss_sounds_replace_the_generated_ones_and_keep_them_as_the_fallback() -> void:
	var manager: AudioManager = _manager()
	for id: StringName in SONNISS:
		var entry: SfxEntry = SFX_LIBRARY.find(id)
		assert_true(entry != null, "%s is in the library" % id)
		if entry == null:
			continue
		assert_true(manager.uses_recorded_sfx(id), "%s plays a recorded sound" % id)
		assert_eq(manager.get_sfx_variant_count(id), SONNISS[id], "%s has %d takes" % [id, SONNISS[id]])
		assert_true(entry.stream != null, "%s keeps a generated sound as the fallback" % id)
		for path: String in entry.override_paths:
			assert_true(path.begins_with(SONNISS_DIR) and path.get_extension() == "ogg" and ResourceLoader.exists(path), "%s is a Sonniss .ogg that exists" % path.get_file())
			var stream: AudioStream = load(path) as AudioStream
			assert_true(stream != null and stream.get_length() < 4.0, "%s is trimmed to a short sound" % path.get_file())
		assert_true(manager.play_sfx(id), "%s plays" % id)


func test_no_large_original_recording_is_left_in_the_project() -> void:
	for dir: String in [SONNISS_DIR, GORE_DIR]:
		for file: String in DirAccess.get_files_at(dir):
			var name: String = file.trim_suffix(".import")
			assert_true(name.get_extension() != "wav", "%s: large .wav files are converted to .ogg" % name)
			assert_true(not name.begins_with("zombie") or name.begins_with("zombie_groan"), "%s: the long zombie recordings are cut up, not kept" % name)
	for dir: String in [SONNISS_DIR, GORE_DIR]:
		for file: String in DirAccess.get_files_at(dir):
			if file.get_extension() == "ogg" or file.get_extension() == "mp3":
				assert_true(FileAccess.get_file_as_bytes(dir + file).size() < 1024 * 1024, "%s is under 1 MB" % file)


func test_death_groans_are_randomized_and_the_oni_and_boss_are_pitched_down() -> void:
	var soldier: EnemyData = load("res://data/enemies/hollow_soldier.tres") as EnemyData
	var oni: EnemyData = load("res://data/enemies/oni_brute.tres") as EnemyData
	assert_almost_eq(CombatSounds.death_pitch(soldier), 1.0, "a soldier groans at its own pitch")
	assert_true(CombatSounds.death_pitch(oni) < 0.8, "an Oni groans lower")
	assert_true(CombatSounds.death_pitch(DAIMYO) < CombatSounds.death_pitch(oni), "the boss lowest of all")
	assert_almost_eq(CombatSounds.death_pitch(null), 1.0, "no data, no change")
	assert_true(CombatSounds.is_big(oni) and CombatSounds.is_big(DAIMYO) and not CombatSounds.is_big(soldier), "the Oni and the boss are the big ones")
	assert_true(CombatSounds.roar_pitch(DAIMYO) < CombatSounds.roar_pitch(oni), "the boss roars lower than an Oni")
	assert_eq(SFX_LIBRARY.find(&"enemy_death").override_paths.size(), 6, "six groans to pick from")


func test_the_boss_music_has_a_quiet_eerie_loop_under_it() -> void:
	var entry: MusicEntry = MUSIC_LIBRARY.find(&"boss")
	assert_eq(entry.ambience_paths.size(), 2, "two eerie beds to pick from")
	assert_true(entry.ambience_db <= -10.0, "it sits quietly under the music")
	for slot: StringName in [&"menu", &"stage_select", &"battle"]:
		assert_true(MUSIC_LIBRARY.find(slot).ambience_paths.is_empty(), "%s has no bed" % slot)
	var manager: AudioManager = _manager()
	manager.play_music_track(&"battle", 0.0)
	assert_true(not manager.get_ambience_player().playing, "no bed in battle")
	manager.play_music_track(&"boss", 0.0)
	var bed: AudioStreamPlayer = manager.get_ambience_player()
	assert_true(bed.playing and bed.bus == AudioManager.MUSIC_BUS, "the bed plays on the music bus with the boss music")
	assert_true(bed.stream is AudioStreamOggVorbis and (bed.stream as AudioStreamOggVorbis).loop, "and loops")
	assert_almost_eq(bed.volume_db, entry.ambience_db, "at its own quiet level")
	manager.play_music_track(&"battle", 0.0)
	assert_true(not bed.playing, "it stops when the boss music does")


func test_the_gore_sounds_come_from_the_pixabay_recordings_with_the_generated_ones_as_fallback() -> void:
	var manager: AudioManager = _manager()
	for id: StringName in GORE:
		assert_true(manager.uses_recorded_sfx(id), "%s plays a recorded sound" % id)
		assert_eq(manager.get_sfx_variant_count(id), GORE[id], "%s picks from %d recordings" % [id, GORE[id]])
		var entry: SfxEntry = SFX_LIBRARY.find(id)
		assert_true(entry.stream != null and FileAccess.file_exists("res://assets/audio/sfx/%s.wav" % id), "%s keeps its generated sound as the fallback" % id)
		for path: String in entry.override_paths:
			assert_true(path.begins_with(GORE_DIR) and ResourceLoader.exists(path), "%s is a gore file that exists" % path.get_file())
		var short: bool = true
		for path: String in entry.override_paths:
			short = short and (load(path) as AudioStream).get_length() <= 2.2
		assert_true(short or (entry.max_length > 0.0 and entry.max_length < 2.0), "%s is trimmed or cut off after %.1f s (the recordings run 1-2 s)" % [id, entry.max_length])
	assert_true(manager.play_sfx(&"sword_swing") and manager.play_sfx(&"flesh_heavy"), "they play")
	var probe: SfxEntry = SfxEntry.new()
	probe.id = &"probe_gore"
	probe.stream = load("res://assets/audio/sfx/hit.wav") as AudioStream
	probe.override_paths = PackedStringArray([GORE_DIR + "this_recording_was_deleted.mp3"])
	var library: SfxLibrary = SfxLibrary.new()
	library.entries = [probe] as Array[SfxEntry]
	var bare: AudioManager = AudioManager.new()
	bare.library = library
	add_to_tree(bare)
	assert_true(not bare.uses_recorded_sfx(&"probe_gore") and bare.play_sfx(&"probe_gore"), "a deleted recording falls back to the generated sound")


func test_a_long_recording_is_cut_off_by_its_max_length() -> void:
	var manager: AudioManager = _manager()
	assert_true(manager.play_sfx(&"flesh_heavy"), "plays")
	var cut: bool = false
	for child: Node in manager.get_children():
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		if player != null and player.has_meta(&"play_token"):
			cut = true
	assert_true(cut, "its player is set to be stopped after the max length")


func test_enemies_are_hit_with_the_gore_sounds_and_everyone_else_with_metal() -> void:
	var audio: AudioManager = AudioManager.instance
	if audio == null:
		return
	var feedback: BattleFeedback = BattleFeedback.new()
	add_to_tree(feedback)
	var enemy: Node = track(ENEMY_SCENE.instantiate())
	var ally: Node = track(ALLY_SCENE.instantiate())
	var hit: HitData = HitData.new(10.0, Vector2(100.0, 0.0), null)
	feedback.handle_hit(enemy, Vector2.ZERO, hit)
	assert_eq(audio.last_played, &"flesh_hit", "a light cut into an enemy sounds like flesh")
	var heavy: HitData = HitData.new(30.0, Vector2(100.0, 0.0), null)
	heavy.heavy = true
	feedback.handle_hit(enemy, Vector2.ZERO, heavy)
	assert_eq(audio.last_played, &"flesh_heavy", "a heavy blow with the heavy gore sound")
	feedback.handle_hit(ally, Vector2.ZERO, hit)
	assert_eq(audio.last_played, &"hit", "an ally struck by an enemy rings like metal")


func test_a_missing_recorded_sound_falls_back_to_the_generated_one() -> void:
	var entry: SfxEntry = SfxEntry.new()
	entry.id = &"probe"
	entry.stream = load("res://assets/audio/sfx/hit.wav") as AudioStream
	entry.override_paths = PackedStringArray([KENNEY_DIR + "this_file_was_deleted.ogg"])
	var library: SfxLibrary = SfxLibrary.new()
	library.entries = [entry] as Array[SfxEntry]
	var manager: AudioManager = AudioManager.new()
	manager.library = library
	add_to_tree(manager)
	assert_true(not manager.uses_recorded_sfx(&"probe"), "with no recorded file it uses the generated one")
	assert_eq(manager.get_sfx_variant_count(&"probe"), 1, "one sound")
	assert_true(manager.play_sfx(&"probe"), "and it still plays")
	entry.override_paths = PackedStringArray([KENNEY_DIR + "this_file_was_deleted.ogg", KENNEY_DIR + "click_001.ogg"])
	var again: AudioManager = AudioManager.new()
	again.library = library
	add_to_tree(again)
	assert_eq(again.get_sfx_variant_count(&"probe"), 1, "a missing file among real ones is skipped")
	assert_true(again.uses_recorded_sfx(&"probe"), "and the real one plays")


# --- Credits ----------------------------------------------------------------------------

func test_credits_text_turns_the_markdown_into_bbcode() -> void:
	var text: String = CreditsText.to_bbcode("# Title\n\n## Part\n\n**Bold** and `code` [x]\nsecond line\n\n- item with https://example.com/a.\n")
	assert_true(text.contains("[b]Title[/b]"), "a heading is bold")
	assert_true(text.contains("[b]Bold[/b]") and text.contains("[lb]x]"), "bold works and a bracket is escaped, not read as a tag")
	assert_true(text.contains("[lb]x] second line"), "wrapped lines join into one paragraph")
	assert_true(text.contains("\u2022"), "a bullet is a bullet")
	assert_true(text.contains("[url]https://example.com/a[/url]."), "a link is clickable and the full stop stays outside it")
	assert_true(CreditsText.is_openable("https://music.storyinvention.com/en/"), "web links open")
	assert_true(not CreditsText.is_openable("file:///c:/windows"), "nothing else does")
	assert_true(CreditsText.load_markdown("res://docs/no_such_file.md").contains(REQUIRED_CREDIT), "if the file is missing the required credit is still shown")


func test_the_credits_show_only_the_creator_and_the_required_music_credit() -> void:
	var markdown: String = FileAccess.get_file_as_string("res://docs/CREDITS.md")
	var creator: String = "Created by Muhammad Nazhan Syahmi"
	var music: String = "Music: " + REQUIRED_CREDIT
	assert_true(markdown.contains(creator), "docs/CREDITS.md names the creator")
	assert_true(markdown.contains(music), "and has the required music credit exactly")
	assert_true(markdown.find(creator) < markdown.find(music), "the creator comes first")
	assert_eq(markdown.count("Created by"), 1, "it is the only creator line")
	for text: String in [markdown, CreditsText.FALLBACK]:
		var lines: Array[String] = []
		for line: String in text.split("\n"):
			if not line.strip_edges().is_empty():
				lines.append(line)
		assert_eq(lines.size(), 3, "the title, the creator line and the music line, nothing else")
		for word: String in ["kenney", "pixabay", "sonniss", "cc0", "licen", "claude", "anthropic", " ai ", "artificial", "generated", "ai-"]:
			assert_true(not text.to_lower().contains(word), "the credits do not mention '%s'" % word.strip_edges())
	assert_true(CreditsText.FALLBACK.contains(creator) and CreditsText.FALLBACK.contains(music), "the fallback text has the creator and the required credit too")
	var credits: Node = add_to_tree(CREDITS_SCENE.instantiate())
	var shown: String = (credits.find_child("Text", true, false) as RichTextLabel).get_parsed_text()
	assert_true(shown.contains(creator) and shown.contains(music), "the Credits screen shows the creator line and the music credit")
	assert_true(shown.find(creator) < shown.find(music), "in that order")
	for word: String in ["Kenney", "Pixabay", "Sonniss", "Momiziba", "Claude", "Anthropic"]:
		assert_true(not shown.contains(word), "the Credits screen does not mention %s" % word)


func test_the_credits_screen_shows_everything_in_the_credits_file() -> void:
	var credits: Node = add_to_tree(CREDITS_SCENE.instantiate())
	var label: RichTextLabel = credits.find_child("Text", true, false) as RichTextLabel
	assert_true(label != null, "the screen has its text")
	var shown: String = label.get_parsed_text()
	assert_true(shown.contains("MOMIZizm MUSiC"), "the required music credit is on it")
	assert_true(shown.contains("https://music.storyinvention.com/en/"), "with its link")
	for track: String in ["Voice of Evening Calm", "Honobono Teahouse", "Mountain God's Shrine", "Shamisen Samurai Rock"]:
		assert_true(not shown.contains(track), "%s is not listed (the licence does not ask for it)" % track)
	for line: String in CreditsText.load_markdown().split("\n"):
		if line.begins_with("## "):
			assert_true(shown.contains(line.trim_prefix("## ")), "the heading '%s' is on the screen" % line.trim_prefix("## "))
	assert_true(credits.find_child("BackButton", true, false) != null, "and there is a Back button")


func test_the_main_menu_has_a_credits_button_that_opens_the_screen() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var menu: Node = MAIN_MENU_SCENE.instantiate()
	menu.set("save_path", SAVE_DIR + "credits_menu_save.json")
	menu.set("settings_path", SAVE_DIR + "credits_menu_settings.cfg")
	add_to_tree(menu)
	var button: Button = menu.find_child("CreditsButton", true, false) as Button
	assert_true(button != null, "there is a Credits button")
	assert_true(button.custom_minimum_size.y >= TouchLayout.MIN_TOUCH_TARGET, "big enough for a finger")
	assert_true(button.pressed.get_connections().size() >= 1, "and it does something")
	assert_true(ResourceLoader.exists(SceneRoutes.CREDITS), "the route exists")


# --- The credits rule ---------------------------------------------------------------------

func test_every_third_party_file_is_used_and_recorded() -> void:
	assert_true(FileAccess.get_file_as_string("res://docs/CREDITS.md").contains(REQUIRED_CREDIT), "the Momiziba credit line is in docs/CREDITS.md exactly")
	var credits: String = FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md")
	assert_true(credits.contains("CC0") and credits.contains("Kenney"), "Kenney and its licence are recorded")
	assert_true(credits.contains("Pixabay Content License"), "Pixabay and its licence are recorded")
	assert_true(credits.contains("Sonniss GDC 2024") and credits.contains("royalty-free"), "Sonniss and its licence are recorded")
	assert_true(credits.contains("Momiziba") and credits.contains(REQUIRED_CREDIT), "the music source and its required credit are recorded")
	for entry: SfxEntry in SFX_LIBRARY.entries:
		for path: String in entry.override_paths:
			if path.begins_with(GORE_DIR) or path.begins_with(SONNISS_DIR):
				var listed: bool = credits.contains(path.get_file()) or (path.get_file().begins_with("zombie_groan_") and credits.contains("`zombie_groan_1.ogg` to"))
				assert_true(listed, "%s is listed in docs/ASSET_LICENSES.md" % path.get_file())
	var used: Dictionary = {}
	for entry: SfxEntry in SFX_LIBRARY.entries:
		for path: String in entry.override_paths:
			used[path.get_file()] = true
			assert_true(ResourceLoader.exists(path), "%s exists" % path)
	var regex: RegEx = RegEx.create_from_string("_?\\d+$")
	for file: String in DirAccess.get_files_at(KENNEY_DIR):
		if file.get_extension() != "ogg":
			continue
		assert_true(used.has(file), "%s is used by the sound library (keep only what the game uses)" % file)
		var stem: String = regex.sub(file.get_basename(), "")
		assert_true(credits.contains(stem), "%s is listed in docs/ASSET_LICENSES.md" % file)
	for slot: StringName in [&"menu", &"stage_select", &"battle", &"boss"]:
		var track_file: String = MUSIC_LIBRARY.find(slot).resolve_path().get_file()
		assert_true(credits.contains(track_file), "%s is listed in docs/ASSET_LICENSES.md" % track_file)
	for licence: String in ["Impact-Sounds", "Interface-Sounds", "RPG-Audio"]:
		var text: String = FileAccess.get_file_as_string(KENNEY_DIR + "licenses/Kenney-%s-License.txt" % licence)
		assert_true(text.contains("Creative Commons Zero") or text.contains("CC0"), "the %s licence text is kept and is CC0" % licence)
	assert_true(_zip_files("res://assets").is_empty(), "no .zip archive is left in assets (%s)" % str(_zip_files("res://assets")))
	assert_true(FileAccess.get_file_as_string("res://.gitignore").contains("*.zip"), "zip archives are git-ignored")


func test_the_project_rules_record_assets_in_the_licences_file_and_credit_only_when_required() -> void:
	for path: String in ["res://CLAUDE.md", "res://AGENTS.md"]:
		var rules: String = FileAccess.get_file_as_string(path)
		assert_true(rules.contains("commercial use"), "%s says assets need a commercial licence" % path)
		assert_true(rules.contains("Record every third-party asset in `docs/ASSET_LICENSES.md`"), "%s says to record every asset in docs/ASSET_LICENSES.md" % path)
		assert_true(rules.contains("`docs/CREDITS.md`") and rules.contains("only if its licence requires attribution"), "%s says to credit only when the licence requires it" % path)
		assert_true(not rules.contains("No third-party assets"), "%s no longer forbids third-party assets" % path)


func test_the_licences_file_is_never_shown_or_exported() -> void:
	assert_true(FileAccess.file_exists("res://docs/ASSET_LICENSES.md"), "the licences file exists")
	assert_eq(CreditsText.FILE_PATH, "res://docs/CREDITS.md", "the Credits screen reads the credits file")
	for dir: String in ["res://scripts", "res://scenes"]:
		for path: String in _gd_files(dir):
			assert_true(not FileAccess.get_file_as_string(path).contains("res://docs/ASSET_LICENSES"), "%s does not load the licences file" % path)
	if FileAccess.file_exists("res://export_presets.cfg"):
		var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
		assert_true(presets.contains("docs/ASSET_LICENSES.md") and presets.contains("exclude_filter"), "an export preset excludes the licences file")


func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			found.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_gd_files(dir_path.path_join(sub)))
	return found


func _zip_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension().to_lower() == "zip":
			found.append(dir_path.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_zip_files(dir_path.path_join(sub)))
	return found
