class_name WaveData
extends Resource
## One wave: entries spawn in order. The wave is cleared when every spawned enemy is gone.

@export var entries: Array[WaveEntry] = []


func get_enemy_count() -> int:
	var total: int = 0
	for entry: WaveEntry in entries:
		if entry != null and entry.enemy != null:
			total += maxi(entry.count, 0)
	return total
