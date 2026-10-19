class_name StageProgression
extends RefCounted
## Unlock rules for a region's stages. Uses PlayerProgress.stages_cleared (already saved),
## so unlocks persist with the save file and need no extra data.

const DEFAULT_REGION_PATH: String = "res://data/regions/bamboo_outskirts.tres"


static func default_region() -> RegionData:
	return load(DEFAULT_REGION_PATH) as RegionData


## Stage 1 is always open; stage N needs stage N-1 cleared.
static func is_unlocked(progress: PlayerProgress, region: RegionData, index: int) -> bool:
	if region == null or index < 0 or index >= region.stages.size():
		return false
	if index == 0:
		return true
	var previous: StageData = region.stages[index - 1]
	return previous != null and progress != null and progress.is_stage_cleared(previous.stage_id)


static func unlocked_count(progress: PlayerProgress, region: RegionData) -> int:
	var count: int = 0
	for i: int in region.stages.size():
		if is_unlocked(progress, region, i):
			count += 1
	return count


## The stage after `stage` in its region, or null for the last stage / unknown stages.
static func next_stage(region: RegionData, stage: StageData) -> StageData:
	var index: int = region.index_of(stage) if region != null else -1
	if index < 0 or index + 1 >= region.stages.size():
		return null
	return region.stages[index + 1]
