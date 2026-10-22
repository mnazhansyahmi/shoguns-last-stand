class_name StageProgression
extends RefCounted
## Unlock rules for the campaign's stages. Uses PlayerProgress.stages_cleared (already saved),
## so unlocks persist with the save file and need no extra data.
## The campaign is the regions in REGION_PATHS, played in order: a region's first stage opens when the last stage of the
## region before it has been cleared, and stages are numbered across the whole campaign (Region 2 starts at stage 6).

const DEFAULT_REGION_PATH: String = "res://data/regions/bamboo_outskirts.tres"
const REGION_PATHS: Array[String] = [
	"res://data/regions/bamboo_outskirts.tres",
	"res://data/regions/burning_village.tres",
]


static func default_region() -> RegionData:
	return load(DEFAULT_REGION_PATH) as RegionData


## Every region of the campaign, in play order.
static func regions() -> Array[RegionData]:
	var result: Array[RegionData] = []
	for path: String in REGION_PATHS:
		var region: RegionData = load(path) as RegionData
		if region != null:
			result.append(region)
	return result


## Every stage of the campaign, in play order.
static func all_stages() -> Array[StageData]:
	var result: Array[StageData] = []
	for region: RegionData in regions():
		for stage: StageData in region.stages:
			if stage != null:
				result.append(stage)
	return result


## The campaign region `stage` belongs to, or null.
static func region_of(stage: StageData) -> RegionData:
	if stage == null:
		return null
	for region: RegionData in regions():
		if region.index_of(stage) >= 0:
			return region
	return null


## The campaign number of the region's first stage (1 for Region 1, 6 for Region 2). A region outside the campaign
## starts at 1.
static func first_stage_number(region: RegionData) -> int:
	var number: int = 1
	if region == null:
		return number
	for other: RegionData in regions():
		if other.region_id == region.region_id:
			return number
		number += other.stages.size()
	return 1


## The campaign number of `stage` ("Stage 7"), or 0 for a stage outside the campaign.
static func stage_number(stage: StageData) -> int:
	var region: RegionData = region_of(stage)
	return first_stage_number(region) + region.index_of(stage) if region != null else 0


## The stage that must be cleared before stage `index` of `region` opens: the one before it, or for a region's first
## stage the last stage of the previous region (null when nothing is needed).
static func required_stage(region: RegionData, index: int) -> StageData:
	if region == null or index < 0 or index >= region.stages.size():
		return null
	if index > 0:
		return region.stages[index - 1]
	var previous: RegionData = null
	for other: RegionData in regions():
		if other.region_id == region.region_id:
			break
		previous = other
	if previous == null or previous.stages.is_empty():
		return null
	return previous.stages[previous.stages.size() - 1]


## Stage 1 is always open; every other stage needs the one before it (across regions) cleared.
static func is_unlocked(progress: PlayerProgress, region: RegionData, index: int) -> bool:
	if region == null or index < 0 or index >= region.stages.size():
		return false
	var required: StageData = required_stage(region, index)
	if required == null:
		return index == 0
	return progress != null and progress.is_stage_cleared(required.stage_id)


## A region is open once its first stage is.
static func is_region_unlocked(progress: PlayerProgress, region: RegionData) -> bool:
	return is_unlocked(progress, region, 0)


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


## continue_stage() over the whole campaign: the first stage not cleared in any region, else the one played last, else
## the campaign's last stage.
static func campaign_continue_stage(progress: PlayerProgress) -> StageData:
	var stages: Array[StageData] = all_stages()
	if stages.is_empty():
		return null
	for stage: StageData in stages:
		if progress == null or not progress.is_stage_cleared(stage.stage_id):
			return stage
	for stage: StageData in stages:
		if stage.stage_id == progress.last_stage_id:
			return stage
	return stages[stages.size() - 1]


## A save that has never played a battle (Continue says "Start").
static func is_fresh(progress: PlayerProgress) -> bool:
	return progress == null or (progress.stages_cleared.is_empty() and progress.last_stage_id.is_empty() and progress.battles_played == 0)


## "Stage 3 - Misty Grove", numbered across the campaign ("Stage 7 - ..." in Region 2).
static func stage_line(region: RegionData, stage: StageData) -> String:
	var index: int = region.index_of(stage) if region != null else -1
	return "Stage %d - %s" % [first_stage_number(region) + index, stage.display_name] if index >= 0 and stage != null else ""


## The stage after `stage`: the next one in its region, or the first stage of the next region; null after the
## campaign's last stage and for unknown stages.
static func next_stage(region: RegionData, stage: StageData) -> StageData:
	var index: int = region.index_of(stage) if region != null else -1
	if index < 0:
		return null
	if index + 1 < region.stages.size():
		return region.stages[index + 1]
	var found: bool = false
	for other: RegionData in regions():
		if found and not other.stages.is_empty():
			return other.stages[0]
		if other.region_id == region.region_id:
			found = true
	return null
