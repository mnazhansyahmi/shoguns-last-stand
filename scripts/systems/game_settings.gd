class_name GameSettings
extends RefCounted
## Player settings (separate from progression). Persisted by SettingsStore.

enum TouchMode { AUTO, ALWAYS, OFF }

const MIN_UI_SCALE: float = 0.9
const MAX_UI_SCALE: float = 1.4
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

var music_volume: float = 0.8
var sfx_volume: float = 0.8
var vibration: bool = true
var screen_shake: bool = true
var ui_scale: float = 1.0
var left_handed: bool = false
## AUTO shows touch controls only on touchscreens; ALWAYS is for testing with a mouse.
var touch_mode: TouchMode = TouchMode.AUTO

## Set once a real (not mouse-emulated) touch is seen; lasts for the session.
static var real_touch_detected: bool = false


## Whether this device should be treated as a touchscreen for AUTO mode.
## On desktop, DisplayServer.is_touchscreen_available() only mirrors the project's
## "emulate touch from mouse" setting (verified on Windows: true with emulation on, false off),
## so it cannot be trusted there. Desktop instead switches on after the first real touch.
static func detect_touchscreen() -> bool:
	if real_touch_detected:
		return true
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return DisplayServer.is_touchscreen_available()
	return false


## Real finger input, not a touch Godot emulated from the mouse (those use DEVICE_ID_EMULATION).
static func is_real_touch(event: InputEvent) -> bool:
	var is_touch: bool = event is InputEventScreenTouch or event is InputEventScreenDrag
	return is_touch and event.device != InputEvent.DEVICE_ID_EMULATION


func sanitize() -> void:
	music_volume = clampf(music_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	ui_scale = clampf(ui_scale, MIN_UI_SCALE, MAX_UI_SCALE)
	if touch_mode < TouchMode.AUTO or touch_mode > TouchMode.OFF:
		touch_mode = TouchMode.AUTO


func should_show_touch_controls(touchscreen_available: bool) -> bool:
	match touch_mode:
		TouchMode.ALWAYS:
			return true
		TouchMode.OFF:
			return false
	return touchscreen_available


## Sets the Music/SFX bus volumes (from default_bus_layout.tres). Audio state is global, so
## applying once per scene start keeps it correct without an autoload.
func apply_audio() -> void:
	_apply_bus(MUSIC_BUS, music_volume)
	_apply_bus(SFX_BUS, sfx_volume)


func duplicate_settings() -> GameSettings:
	var copy: GameSettings = GameSettings.new()
	copy.music_volume = music_volume
	copy.sfx_volume = sfx_volume
	copy.vibration = vibration
	copy.screen_shake = screen_shake
	copy.ui_scale = ui_scale
	copy.left_handed = left_handed
	copy.touch_mode = touch_mode
	return copy


func _apply_bus(bus_name: StringName, volume: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("GameSettings: audio bus '%s' not found; volume not applied." % bus_name)
		return
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
