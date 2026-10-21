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


## The stage the main menu's Continue starts: the first one not cleared yet; once every stage is cleared, the one played
## last (the last stage of the region if that is not known).
static func continue_stage(progress: PlayerProgress, region: RegionData) -> StageData:
	if region == null or region.stages.is_empty():
		return null
	for stage: StageData in region.stages:
		if stage != null and (progress == null or not progress.is_stage_cleared(stage.stage_id)):
			return stage
	if progress != null:
		for stage: StageData in region.stages:
			if stage != null and stage.stage_id == progress.last_stage_id:
				return stage
	return region.stages[region.stages.size() - 1]


## A save that has never played a battle (Continue says "Start").
static func is_fresh(progress: PlayerProgress) -> bool:
	return progress == null or (progress.stages_cleared.is_empty() and progress.last_stage_id.is_empty() and progress.battles_played == 0)


## "Stage 3 - Misty Grove".
static func stage_line(region: RegionData, stage: StageData) -> String:
	var index: int = region.index_of(stage) if region != null else -1
	return "Stage %d - %s" % [index + 1, stage.display_name] if index >= 0 and stage != null else ""


## The stage after `stage` in its region, or null for the last stage / unknown stages.
static func next_stage(region: RegionData, stage: StageData) -> StageData:
	var index: int = region.index_of(stage) if region != null else -1
	if index < 0 or index + 1 >= region.stages.size():
		return null
	return region.stages[index + 1]
