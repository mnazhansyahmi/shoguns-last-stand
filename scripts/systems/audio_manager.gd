class_name AudioManager
extends Node
## Plays sound effects from data/audio/sfx_library.tres on the "SFX" bus (so the SFX volume
## setting applies). Registered as the "Audio" autoload: it must outlive scene changes (a button
## click that changes scene) and keep playing while the tree is paused (victory/defeat stings).
## Gameplay code calls the static AudioManager.play(id); it is a no-op when no manager exists,
## so scenes and tests work without the autoload. Every Button anywhere gets a click sound.

const LIBRARY_PATH: String = "res://data/audio/sfx_library.tres"
const BUS: StringName = &"SFX"
const POOL_SIZE: int = 12
const CLICK_ID: StringName = &"button_click"
## Set this meta on a button to silence its click.
const NO_CLICK_META: StringName = &"no_click_sfx"

static var instance: AudioManager

var library: SfxLibrary
var last_played: StringName = &""
var play_count: int = 0

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _last_played_msec: Dictionary = {}
var _warned: Dictionary = {}


## Plays `id` through the active manager. Returns false if nothing was played.
static func play(id: StringName, pitch_scale: float = 1.0) -> bool:
	if not is_instance_valid(instance):
		return false
	return instance.play_sfx(id, pitch_scale)


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
	for player: AudioStreamPlayer in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if library == null:
		library = load(LIBRARY_PATH) as SfxLibrary
	if library == null:
		push_error("AudioManager: could not load %s; sounds disabled." % LIBRARY_PATH)
	if AudioServer.get_bus_index(BUS) < 0:
		push_warning("AudioManager: audio bus '%s' missing; sounds use Master." % BUS)
	for i: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)


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
	player.stream = entry.stream
	player.volume_db = entry.volume_db
	player.pitch_scale = maxf(pitch_scale * (1.0 + randf_range(-entry.pitch_variation, entry.pitch_variation)), 0.05)
	player.play()
	last_played = id
	play_count += 1
	return true


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
