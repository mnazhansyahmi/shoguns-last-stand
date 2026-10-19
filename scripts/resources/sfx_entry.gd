class_name SfxEntry
extends Resource
## One sound effect. Swap `stream` (or overwrite its .wav) to replace a placeholder sound.

@export var id: StringName = &""
@export var stream: AudioStream
@export_range(-40.0, 12.0) var volume_db: float = 0.0
## Random pitch spread (0.05 = ±5%) so repeated sounds do not feel mechanical.
@export_range(0.0, 0.5) var pitch_variation: float = 0.05
## Ignore repeats closer together than this (stops 20 hits in one frame from stacking).
@export var min_interval: float = 0.04
