class_name SfxEntry
extends Resource
## One sound effect. Swap `stream` (or overwrite its .wav) to replace a placeholder sound.

@export var id: StringName = &""
## The generated placeholder. It plays when none of `override_paths` exists (a fallback that always works).
@export var stream: AudioStream
## Recorded sounds (Kenney, Pixabay and Sonniss, recorded in docs/ASSET_LICENSES.md) that replace the placeholder: one is picked at
## random each time. A path that does not exist is skipped.
@export var override_paths: PackedStringArray = PackedStringArray()
@export_range(-40.0, 12.0) var volume_db: float = 0.0
## Random pitch spread (0.05 = ±5%) so repeated sounds do not feel mechanical.
@export_range(0.0, 0.5) var pitch_variation: float = 0.05
## Ignore repeats closer together than this (stops 20 hits in one frame from stacking).
@export var min_interval: float = 0.04
## A recording longer than this is cut off after this many seconds (its quiet tail), so a fast fight does not pile up
## two-second sounds. 0 = play to the end.
@export var max_length: float = 0.0
