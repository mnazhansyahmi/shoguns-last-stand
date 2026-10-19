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


## Band-pass biquad (RBJ cookbook, 0 dB peak) used as a vowel formant resonator.
class Biquad:
	var b0: float = 0.0
	var b2: float = 0.0
	var a1: float = 0.0
	var a2: float = 0.0
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0

	func set_bandpass(frequency: float, q: float) -> void:
		var w0: float = TAU * frequency / MIX_RATE
		var alpha: float = sin(w0) / (2.0 * q)
		var a0: float = 1.0 + alpha
		b0 = alpha / a0
		b2 = -alpha / a0
		a1 = -2.0 * cos(w0) / a0
		a2 = (1.0 - alpha) / a0

	func process(x: float) -> float:
		var y: float = b0 * x + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		return y


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
		"ultimate": _ultimate,
		"ultimate_ready": _ultimate_ready,
		"heal": _heal,
		"magic_burst": _magic_burst,
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


## "Whoosh" (rising air, 0.22 s) followed by a soft "appear" pop with a bell-like chime.
func _summon() -> PackedFloat32Array:
	var whoosh_length: float = 0.22
	var out: PackedFloat32Array = _buffer(0.8)
	var whoosh: PackedFloat32Array = _whoosh(whoosh_length, 500.0, 2800.0)
	for i: int in whoosh.size():
		out[i] = whoosh[i] * 0.55
	var pop_start: float = whoosh_length - 0.02
	var pop_phase: float = 0.0
	for i: int in range(int(pop_start * MIX_RATE), out.size()):
		var t: float = _t(i) - pop_start
		# Pop: a short sine whose pitch drops quickly, like a bubble.
		pop_phase += TAU * lerpf(950.0, 480.0, minf(t / 0.035, 1.0)) / MIX_RATE
		var pop: float = sin(pop_phase) * exp(-t * 38.0)
		# Chime: bell partials (E6, B6, E7) with a soft attack and slower decay.
		var attack: float = minf(t / 0.006, 1.0)
		var chime: float = (sin(TAU * 1318.5 * t) * exp(-t * 5.0) + 0.5 * sin(TAU * 1975.5 * t) * exp(-t * 7.0)
				+ 0.25 * sin(TAU * 2637.0 * t) * exp(-t * 10.0)) * attack
		out[i] += pop * 0.9 + chime * 0.45
	return _normalize(out)


## Low groan "arh": a buzzy voice source with falling, slightly unsteady pitch, shaped by
## vowel formants ("ah" drifting to "uh") and mixed with breath that takes over as it fades.
func _enemy_death() -> PackedFloat32Array:
	var duration: float = 0.75
	var out: PackedFloat32Array = _buffer(duration)
	var formants: Array[Biquad] = [Biquad.new(), Biquad.new(), Biquad.new()]
	var gains: Array[float] = [1.0, 0.55, 0.22]
	var phase: float = 0.0
	var jitter: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		var progress: float = t / duration
		if i % 64 == 0:
			# Vowel "ah" (F1 760, F2 1150) sliding toward "uh" (F1 600, F2 1000).
			formants[0].set_bandpass(lerpf(760.0, 600.0, progress), 8.0)
			formants[1].set_bandpass(lerpf(1150.0, 1000.0, progress), 10.0)
			formants[2].set_bandpass(2450.0, 14.0)
		jitter = clampf(jitter + _noise() * 0.004, -0.03, 0.03)
		var f0: float = 165.0 * pow(80.0 / 165.0, progress) * (1.0 + jitter + 0.015 * sin(TAU * 5.5 * t))
		phase = fmod(phase + f0 / MIX_RATE, 1.0)
		# Glottal-like pulse: a sawtooth softened by a little rounding.
		var pulse: float = (1.0 - 2.0 * phase) * 0.8 + sin(TAU * phase) * 0.2
		var breath_mix: float = lerpf(0.25, 0.9, smoothstep(0.45, 1.0, progress))
		var source: float = pulse * (1.0 - breath_mix) + _noise() * breath_mix
		var voiced: float = 0.0
		for f: int in formants.size():
			voiced += formants[f].process(source) * gains[f]
		var envelope: float = smoothstep(0.0, 0.07, t) * (1.0 - smoothstep(0.45, 1.0, progress))
		out[i] = voiced * envelope
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


## The Ultimate: a rising swell while the blade goes up (0.35 s), then a huge low boom with a
## crack and a shimmering tail at the moment the sweep lands.
func _ultimate() -> PackedFloat32Array:
	var swell: float = 0.35
	var out: PackedFloat32Array = _buffer(1.5)
	var phase: float = 0.0
	var boom_phase: float = 0.0
	var low_a: float = 0.0
	var low_b: float = 0.0
	var air: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		var noise: float = _noise()
		if t < swell:
			var k: float = t / swell
			phase += TAU * lerpf(140.0, 720.0, k * k) / MIX_RATE
			var cutoff: float = lerpf(300.0, 3800.0, k)
			low_a = _lowpass(low_a, noise, cutoff)
			low_b = _lowpass(low_b, noise, cutoff * 0.35)
			out[i] = ((low_a - low_b) * 1.4 + sin(phase) * 0.5) * k * k
		else:
			var u: float = t - swell
			boom_phase += TAU * lerpf(95.0, 34.0, minf(u / 0.5, 1.0)) / MIX_RATE
			air = _lowpass(air, noise, 1400.0)
			var boom: float = tanh(sin(boom_phase) * exp(-u * 3.2) * 2.6)
			var crack: float = noise * exp(-u * 38.0) * 0.9
			var tail: float = (sin(TAU * 880.0 * u) * 0.12 + sin(TAU * 1320.0 * u) * 0.08) * exp(-u * 3.5)
			out[i] = boom + crack + air * exp(-u * 9.0) * 0.8 + tail
	return _normalize(out)


## Two bright rising chime notes: the Ultimate is ready.
func _ultimate_ready() -> PackedFloat32Array:
	return _notes([783.99, 1174.66], 0.11, 0.38, 0.6, 0.32)


## A gentle rising bell arpeggio: a healing blessing.
func _heal() -> PackedFloat32Array:
	return _notes([523.25, 659.25, 783.99, 1046.5], 0.08, 0.34, 0.75, 0.15)


## An onmyoji's spell: rising shimmer, then a soft thump of spirit energy.
func _magic_burst() -> PackedFloat32Array:
	var out: PackedFloat32Array = _buffer(0.8)
	var phase: float = 0.0
	var thump_phase: float = 0.0
	var low_a: float = 0.0
	var low_b: float = 0.0
	for i: int in out.size():
		var t: float = _t(i)
		var noise: float = _noise()
		var k: float = minf(t / 0.3, 1.0)
		low_a = _lowpass(low_a, noise, lerpf(500.0, 3000.0, k))
		low_b = _lowpass(low_b, noise, lerpf(500.0, 3000.0, k) * 0.4)
		phase += TAU * (lerpf(520.0, 1560.0, k) + 18.0 * sin(TAU * 22.0 * t)) / MIX_RATE
		var swell: float = ((low_a - low_b) * 0.8 + sin(phase) * 0.4 + sin(phase * 1.5) * 0.18) * (k * k if t < 0.3 else exp(-(t - 0.3) * 5.0))
		var u: float = maxf(t - 0.28, 0.0)
		thump_phase += TAU * lerpf(140.0, 52.0, minf(u / 0.25, 1.0)) / MIX_RATE
		var thump: float = sin(thump_phase) * exp(-u * 11.0) * (1.0 if t >= 0.28 else 0.0)
		out[i] = swell + thump * 1.1
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
