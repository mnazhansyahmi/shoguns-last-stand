class_name StageData
extends Resource
## A battle: an ordered list of waves with breaks between them.

@export var display_name: String = "Stage"
@export var waves: Array[WaveData] = []
## Delay before wave 1 starts.
@export var first_wave_delay: float = 3.0
## Break between a cleared wave and the next one.
@export var break_duration: float = 5.0
