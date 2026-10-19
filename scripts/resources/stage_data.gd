class_name StageData
extends Resource
## A battle: an ordered list of waves with breaks between them.

## Stable key stored in the save file (stages_cleared).
@export var stage_id: String = "stage"
@export var display_name: String = "Stage"
@export var waves: Array[WaveData] = []
## Delay before wave 1 starts.
@export var first_wave_delay: float = 3.0
## Break between a cleared wave and the next one.
@export var break_duration: float = 5.0

@export_group("Rewards")
@export var clear_gold_bonus: int = 100
@export var clear_xp_bonus: int = 50
## Share of kill rewards kept on defeat (no clear bonus).
@export_range(0.0, 1.0) var defeat_reward_ratio: float = 0.5
