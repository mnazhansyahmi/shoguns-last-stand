class_name RegionData
extends Resource
## A group of stages played in order. Stage N unlocks when stage N-1 has been cleared.

@export var region_id: String = "region"
@export var display_name: String = "Region"
@export var stages: Array[StageData] = []


func index_of(stage: StageData) -> int:
	if stage == null:
		return -1
	for i: int in stages.size():
		if stages[i] != null and stages[i].stage_id == stage.stage_id:
			return i
	return -1
