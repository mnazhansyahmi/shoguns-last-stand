extends SceneTree
## Generates the placeholder sound effects as .wav files (no downloads, fully synthetic).
##   godot_console --headless --path . -s res://tools/generate_sfx.gd
## Output: res://assets/audio/sfx/<id>.wav (16-bit mono, 22050 Hz). Deterministic: the same
## script always produces the same files. To use real sounds later, replace a .wav with the same
## name, or point its entry in data/audio/sfx_library.tres at a different file.

const OUTPUT_DIR: String = "res://assets/audio/sfx"
const MIX_RATE: int = 22050
const PEAK: float = 0.8

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var sounds: Dictionary = {
		"sword_swing": _sword_swing,
		"hit": _hit,
		"heavy_hit": _heavy_hit,
		"dash": _dash,
		"spirit_slash": _spirit_slash,
		"summon": _summon,
		"enemy_death": _enemy_death,
		"gate_hit": _gate_hit,
		"victory": _victory,
		"defeat": _defeat,
		"button_click": _button_click,
	}
	var failures: int = 0
	for id: String in sounds:
		_rng.seed = hash(id)
		var samples: PackedFloat32Array = (sounds[id] as Callable).call()
		var error: Error = _save(id, samples)
		print("%-13s %5d samples (%.2f s) -> %s" % [id, samples.size(), samples.size() / float(MIX_RATE), error_string(error)])
		if error != OK:
			failures += 1
	quit(1 if failures > 0 else 0)


# --- Sounds -----------------------------------------------------------------

## Airy whoosh: band-passed noise swept upward, bell-shaped envelope.
func _sword_swing() -> PackedFloat32Array:
	return _whoosh(0.2, 700.0, 3200.0)


## Short punch: falling sine thump plus a noise click.
func _hit() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.13)
	var phase: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		phase += TAU * lerpf(190.0, 85.0, t / 0.13) / MIX_RATE
		out[i] = sin(phase) * exp(-t * 28.0) + _noise() * exp(-t * 70.0) * 0.6
	return _normalize(out)


## Deep impact: low falling sine, filtered noise, soft clipping.
func _heavy_hit() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.3)
	var phase: float = 0.0
	var lowpassed: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		phase += TAU * lerpf(120.0, 42.0, t / 0.3) / MIX_RATE
		lowpassed = _lowpass(lowpassed, _noise(), 900.0)
		out[i] = tanh((sin(phase) * exp(-t * 11.0) + lowpassed * exp(-t * 22.0) * 1.4) * 2.0)
	return _normalize(out)


## Quick whoosh swept downward.
func _dash() -> PackedFloat32Array:
	return _whoosh(0.16, 2600.0, 600.0)


## Rising shimmer: sine sweep with an octave partial and a little air.
func _spirit_slash() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.42)
	var phase: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		phase += TAU * lerpf(480.0, 1500.0, minf(t / 0.25, 1.0)) / MIX_RATE
		var envelope: float = minf(t / 0.01, 1.0) * exp(-t * 5.5)
		out[i] = (sin(phase) + 0.35 * sin(phase * 2.0) + 0.15 * sin(phase * 3.01)) * envelope + _noise() * 0.05 * envelope
	return _normalize(out)


## Three-note rising arpeggio (C5 E5 G5).
func _summon() -> PackedFloat32Array:
	return _notes([523.25, 659.25, 783.99], 0.13, 0.22, 0.45, 0.3)


## Falling square-ish growl, filtered.
func _enemy_death() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.42)
	var phase: float = 0.0
	var lowpassed: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		phase += TAU * lerpf(320.0, 65.0, t / 0.42) / MIX_RATE
		var square: float = signf(sin(phase)) * 0.6 + sin(phase) * 0.4
		lowpassed = _lowpass(lowpassed, square, 1800.0)
		out[i] = lowpassed * minf(t / 0.005, 1.0) * exp(-t * 4.5)
	return _normalize(out)


## Wooden knock: two damped sines and a short noise burst.
func _gate_hit() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.24)
	var lowpassed: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		lowpassed = _lowpass(lowpassed, _noise(), 1500.0)
		out[i] = sin(TAU * 140.0 * t) * exp(-t * 17.0) + 0.45 * sin(TAU * 265.0 * t) * exp(-t * 30.0) \
				+ lowpassed * exp(-t * 45.0) * 1.2
	return _normalize(out)


## Short ascending fanfare (C5 E5 G5 C6), last note held.
func _victory() -> PackedFloat32Array:
	return _notes([523.25, 659.25, 783.99, 1046.5], 0.15, 0.6, 1.15, 0.45)


## Slow descending minor line (G4 F4 Eb4 C4).
func _defeat() -> PackedFloat32Array:
	return _notes([392.0, 349.23, 311.13, 261.63], 0.26, 0.45, 1.25, 0.2)


## Tiny UI tick.
func _button_click() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.05)
	for i: int in out.size():
		var t: float = _t(i)
		out[i] = sin(TAU * 1250.0 * t) * exp(-t * 95.0) + _noise() * exp(-t * 300.0) * 0.3
	return _normalize(out)


# --- Building blocks --------------------------------------------------------

func _whoosh(duration: float, from_hz: float, to_hz: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(duration)
	var low_a: float = 0.0
	var low_b: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		var noise: float = _noise()
		var cutoff: float = lerpf(from_hz, to_hz, t / duration)
		low_a = _lowpass(low_a, noise, cutoff)
		low_b = _lowpass(low_b, noise, cutoff * 0.35)
		out[i] = (low_a - low_b) * pow(sin(PI * t / duration), 2.0)
	return _normalize(out)


## Sequence of soft sine notes; each starts `step` after the previous and rings for `ring`.
func _notes(frequencies: Array, step: float, ring: float, duration: float, harmonic: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(duration)
	for n: int in frequencies.size():
		var start: float = n * step
		var length: float = ring if n < frequencies.size() - 1 else duration - start
		var frequency: float = frequencies[n]
		for i: int in range(int(start * MIX_RATE), mini(out.size(), int((start + length) * MIX_RATE))):
			var t: float = _t(i) - start
			var envelope: float = minf(t / 0.008, 1.0) * exp(-t * 3.0 / length)
			out[i] += (sin(TAU * frequency * t) + harmonic * sin(TAU * frequency * 2.0 * t)) * envelope
	return _normalize(out)


func _buffer(duration: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(int(duration * MIX_RATE))
	return out


func _t(index: int) -> float:
	return float(index) / MIX_RATE


func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


## One-pole low-pass step.
func _lowpass(state: float, input: float, cutoff_hz: float) -> float:
	var alpha: float = 1.0 - exp(-TAU * cutoff_hz / MIX_RATE)
	return state + alpha * (input - state)


func _normalize(samples: PackedFloat32Array) -> PackedFloat32Array:
	var peak: float = 0.0001
	for value: float in samples:
		peak = maxf(peak, absf(value))
	for i: int in samples.size():
		samples[i] = samples[i] / peak * PEAK
	# 3 ms fade-out avoids a click at the end.
	var fade: int = mini(int(0.003 * MIX_RATE), samples.size())
	for i: int in fade:
		samples[samples.size() - 1 - i] *= float(i) / fade
	return samples


func _save(id: String, samples: PackedFloat32Array) -> Error:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, clampi(roundi(samples[i] * 32767.0), -32768, 32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream.save_to_wav("%s/%s.wav" % [OUTPUT_DIR, id])
