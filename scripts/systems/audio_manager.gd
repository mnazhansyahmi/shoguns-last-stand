class_name AudioManager
extends Node
## Plays sound effects from data/audio/sfx_library.tres on the "SFX" bus (so the SFX volume
## setting applies). Registered as the "Audio" autoload: it must outlive scene changes (a button
## click that changes scene) and keep playing while the tree is paused (victory/defeat stings).
## Gameplay code calls the static AudioManager.play(id); it is a no-op when no manager exists,
## so scenes and tests work without the autoload. Every Button anywhere gets a click sound.
## It also plays the music (play_music): one looping track per slot (menu, stage select, battle, boss) on the
## "Music" bus, crossfaded when the slot changes. The Music volume setting is that bus's volume.

const LIBRARY_PATH: String = "res://data/audio/sfx_library.tres"
const MUSIC_LIBRARY_PATH: String = "res://data/audio/music_library.tres"
const MUSIC_BUS: StringName = &"Music"
## Seconds a track takes to fade in while the one before fades out.
const MUSIC_FADE_TIME: float = 1.6
const MUSIC_SILENT_DB: float = -60.0
const BUS: StringName = &"SFX"
const POOL_SIZE: int = 12
const CLICK_ID: StringName = &"button_click"
## Set this meta on a button to silence its click.
const NO_CLICK_META: StringName = &"no_click_sfx"

static var instance: AudioManager

var library: SfxLibrary
var music_library: MusicLibrary
## The music slot playing now (&"" = none).
var current_music: StringName = &""
var last_played: StringName = &""
var play_count: int = 0

var _players: Array[AudioStreamPlayer] = []
## Two players take turns: one fades in the new track while the other fades the old one out.
var _music_players: Array[AudioStreamPlayer] = []
var _music_active: int = 0
var _music_tween: Tween
var _music_warned: Dictionary = {}
## SFX id -> the streams to pick from (the recorded sounds that exist, else the generated placeholder).
var _streams: Dictionary = {}
var _next_player: int = 0
var _last_played_msec: Dictionary = {}
var _warned: Dictionary = {}


## Plays `id` through the active manager. Returns false if nothing was played.
static func play(id: StringName, pitch_scale: float = 1.0) -> bool:
	if not is_instance_valid(instance):
		return false
	return instance.play_sfx(id, pitch_scale)


## Plays the music of a slot ("menu", "stage_select", "battle", "boss"), crossfading from what plays now.
## The same slot again does nothing. Returns false if the slot has no playable file.
static func play_music(id: StringName, fade: float = MUSIC_FADE_TIME) -> bool:
	if not is_instance_valid(instance):
		return false
	return instance.play_music_track(id, fade)


static func stop_music_fading(fade: float = MUSIC_FADE_TIME) -> void:
	if is_instance_valid(instance):
		instance.stop_music(fade)


func _enter_tree() -> void:
	if not is_instance_valid(instance):
		instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null
	stop_all()


## Call before quitting: stops all sounds and gives the audio thread time to release them
## (otherwise Godot reports still-playing streams as leaked at exit).
static func shutdown_audio(tree: SceneTree) -> void:
	if is_instance_valid(instance):
		instance.stop_all()
	for i: int in 3:
		await tree.process_frame
	OS.delay_msec(100)


## Stops every sound and drops the streams, so nothing is left playing (or leaked) at exit.
func stop_all() -> void:
	if _music_tween != null:
		_music_tween.kill()
	for player: AudioStreamPlayer in _players + _music_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	current_music = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if library == null:
		library = load(LIBRARY_PATH) as SfxLibrary
	if library == null:
		push_error("AudioManager: could not load %s; sounds disabled." % LIBRARY_PATH)
	if AudioServer.get_bus_index(BUS) < 0:
		push_warning("AudioManager: audio bus '%s' missing; sounds use Master." % BUS)
	_build_streams()
	if music_library == null:
		music_library = load(MUSIC_LIBRARY_PATH) as MusicLibrary
	if music_library == null:
		push_error("AudioManager: could not load %s; no music." % MUSIC_LIBRARY_PATH)
	# The two music players live under their own node, apart from the sound-effect pool.
	var music_root: Node = Node.new()
	music_root.name = "MusicPlayers"
	add_child(music_root)
	for i: int in 2:
		var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
		music_player.bus = MUSIC_BUS
		music_player.volume_db = MUSIC_SILENT_DB
		music_root.add_child(music_player)
		_music_players.append(music_player)
	for i: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)


## Picks, for every effect, the recorded sounds that exist (they replace the generated placeholder);
## an effect with none of them keeps its placeholder.
func _build_streams() -> void:
	_streams.clear()
	if library == null:
		return
	for entry: SfxEntry in library.entries:
		if entry == null:
			continue
		var found: Array[AudioStream] = []
		for path: String in entry.override_paths:
			if ResourceLoader.exists(path):
				var stream: AudioStream = load(path) as AudioStream
				if stream != null:
					found.append(stream)
		if found.is_empty() and entry.stream != null:
			found.append(entry.stream)
		_streams[entry.id] = found


## How many different sounds `id` picks from (several recorded takes, or the one placeholder).
func get_sfx_variant_count(id: StringName) -> int:
	return (_streams.get(id, []) as Array).size()


## True if `id` plays a recorded sound (not the generated placeholder).
func uses_recorded_sfx(id: StringName) -> bool:
	var entry: SfxEntry = library.find(id) if library != null else null
	if entry == null:
		return false
	for stream: AudioStream in _streams.get(id, []):
		if stream != entry.stream:
			return true
	return false


func has_sfx(id: StringName) -> bool:
	return library != null and library.find(id) != null and library.find(id).stream != null


func play_sfx(id: StringName, pitch_scale: float = 1.0) -> bool:
	var entry: SfxEntry = library.find(id) if library != null else null
	if entry == null or entry.stream == null:
		if not _warned.has(id):
			_warned[id] = true
			push_warning("AudioManager: no sound for '%s'." % id)
		return false
	var now: int = Time.get_ticks_msec()
	if now - int(_last_played_msec.get(id, -100000)) < int(entry.min_interval * 1000.0):
		return false
	_last_played_msec[id] = now
	var player: AudioStreamPlayer = _pick_player()
	var choices: Array = _streams.get(id, [])
	player.stream = choices.pick_random() as AudioStream if not choices.is_empty() else entry.stream
	player.volume_db = entry.volume_db
	player.pitch_scale = maxf(pitch_scale * (1.0 + randf_range(-entry.pitch_variation, entry.pitch_variation)), 0.05)
	player.play()
	last_played = id
	play_count += 1
	if entry.max_length > 0.0:
		_cut_off_later(player, entry.max_length * player.pitch_scale)
	return true


## Stops `player` after `seconds` of real time (hit-stop slows the game clock, not this) unless it has been given
## another sound by then.
func _cut_off_later(player: AudioStreamPlayer, seconds: float) -> void:
	var token: int = play_count
	player.set_meta(&"play_token", token)
	get_tree().create_timer(seconds, true, false, true).timeout.connect(_stop_if_current.bind(player.get_instance_id(), token))


func _stop_if_current(player_id: int, token: int) -> void:
	var player: AudioStreamPlayer = instance_from_id(player_id) as AudioStreamPlayer
	if player != null and int(player.get_meta(&"play_token", -1)) == token:
		player.stop()


# --- Music ------------------------------------------------------------------

## See the static play_music().
func play_music_track(id: StringName, fade: float = MUSIC_FADE_TIME) -> bool:
	if id == current_music and _music_players.size() == 2 and _music_players[_music_active].playing:
		return true
	var entry: MusicEntry = music_library.find(id) if music_library != null else null
	var path: String = entry.resolve_path() if entry != null else ""
	var stream: AudioStream = load(path) as AudioStream if not path.is_empty() else null
	if stream == null:
		if not _music_warned.has(id):
			_music_warned[id] = true
			push_warning("AudioManager: no music for '%s'." % id)
		return false
	_loop(stream)
	var outgoing: AudioStreamPlayer = _music_players[_music_active]
	_music_active = 1 - _music_active
	var incoming: AudioStreamPlayer = _music_players[_music_active]
	incoming.stream = stream
	incoming.volume_db = entry.volume_db if fade <= 0.0 else MUSIC_SILENT_DB
	incoming.play()
	if _music_tween != null:
		_music_tween.kill()
	if fade <= 0.0:
		outgoing.stop()
		outgoing.volume_db = MUSIC_SILENT_DB
	else:
		_music_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.tween_property(incoming, "volume_db", entry.volume_db, fade)
		if outgoing.playing:
			_music_tween.tween_property(outgoing, "volume_db", MUSIC_SILENT_DB, fade)
			_music_tween.chain().tween_callback(outgoing.stop)
	current_music = id
	return true


## Fades the music out and stops it.
func stop_music(fade: float = MUSIC_FADE_TIME) -> void:
	if _music_players.size() < 2:
		return
	var active: AudioStreamPlayer = _music_players[_music_active]
	current_music = &""
	if _music_tween != null:
		_music_tween.kill()
	if fade <= 0.0 or not active.playing:
		active.stop()
		return
	_music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(active, "volume_db", MUSIC_SILENT_DB, fade)
	_music_tween.tween_callback(active.stop)


func is_music_playing() -> bool:
	return _music_players.size() == 2 and _music_players[_music_active].playing


## The player that has the current track (tests read its stream and volume).
func get_music_player() -> AudioStreamPlayer:
	return _music_players[_music_active] if _music_players.size() == 2 else null


## Music loops until it is changed.
static func _loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


## Prefers an idle player; otherwise reuses the oldest (round-robin).
func _pick_player() -> AudioStreamPlayer:
	for i: int in _players.size():
		var candidate: AudioStreamPlayer = _players[(_next_player + i) % _players.size()]
		if not candidate.playing:
			_next_player = (_next_player + i + 1) % _players.size()
			return candidate
	var oldest: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return oldest


func _on_node_added(node: Node) -> void:
	var button: BaseButton = node as BaseButton
	if button == null or button.has_meta(NO_CLICK_META):
		return
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play_sfx(CLICK_ID)
