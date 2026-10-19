class_name AllyRoster
extends Resource
## The allies the player can summon, in summon-key order (key 1 = the first unlocked ally...).
## Each ally unlocks when its AllyData.unlock_stage_id has been cleared.

@export var allies: Array[AllyData] = []


func is_unlocked(data: AllyData, progress: PlayerProgress) -> bool:
	if data == null:
		return false
	if data.unlock_stage_id.is_empty():
		return true
	return progress != null and progress.is_stage_cleared(data.unlock_stage_id)


## The allies available now, in roster order.
func get_unlocked(progress: PlayerProgress) -> Array[AllyData]:
	var result: Array[AllyData] = []
	for data: AllyData in allies:
		if is_unlocked(data, progress):
			result.append(data)
	return result


func find(ally_id: String) -> AllyData:
	for data: AllyData in allies:
		if data != null and data.id == ally_id:
			return data
	return null
