class_name BossData
extends EnemyData
## A boss: an enemy with named phases and a list of telegraphed attacks (see Boss). Everything about
## the fight is data here: stats come from EnemyData, the rest from `phases` and `attacks`.

## In order: phase 1 (from full health), phase 2, phase 3.
@export var phases: Array[BossPhaseData] = []
@export var attacks: Array[BossAttackData] = []


## 1-based phase for a health ratio (the last phase whose start_ratio has been reached).
func phase_for_ratio(ratio: float) -> int:
	var result: int = 1
	for i: int in phases.size():
		if ratio <= phases[i].start_ratio + 0.0001:
			result = i + 1
	return result


func get_phase(number: int) -> BossPhaseData:
	if phases.is_empty():
		return BossPhaseData.new()
	return phases[clampi(number - 1, 0, phases.size() - 1)]
