class_name StageBriefing
extends RefCounted
## What a stage brings, for the stage select's side panel and the pre-battle info at the start of a battle: how many of
## each foe ("42 soldiers", "3 Oni Brutes", "12 Flying Spirits"), and how to beat the foes that need a plan
## (EnemyData.counter_hint: the Spectral Archer, the Shield Bearer, the Flying Spirit, the Burning General).

const HOLLOW_SOLDIER: EnemyData = preload("res://data/enemies/hollow_soldier.tres")


## "soldier" / "soldiers" for the Hollow Soldiers, the display name (with an "s" for more than one) for the rest.
static func foe_name(enemy: EnemyData, count: int) -> String:
	if enemy == HOLLOW_SOLDIER:
		return "soldier" if count == 1 else "soldiers"
	return enemy.display_name if count == 1 else enemy.display_name + "s"


## One line per kind of foe (bosses left out: they get their own line), in the order they first appear.
static func count_lines(stage: StageData) -> Array[String]:
	var lines: Array[String] = []
	for enemy: EnemyData in stage.enemy_types():
		if enemy is BossData:
			continue
		var count: int = stage.count_enemy(enemy)
		lines.append("%d %s" % [count, foe_name(enemy, count)])
	return lines


## The stage's foes that come with a counter hint, in the order they first appear.
static func special_foes(stage: StageData) -> Array[EnemyData]:
	var found: Array[EnemyData] = []
	for enemy: EnemyData in stage.enemy_types():
		if not enemy.counter_hint.is_empty():
			found.append(enemy)
	return found


## The special foes the campaign shows for the first time in this stage (none on a stage outside the campaign).
static func new_foes(stage: StageData) -> Array[EnemyData]:
	var seen: Array[EnemyData] = []
	for earlier: StageData in StageProgression.all_stages():
		if earlier.stage_id == stage.stage_id:
			break
		seen.append_array(earlier.enemy_types())
	var found: Array[EnemyData] = []
	for enemy: EnemyData in special_foes(stage):
		if not seen.has(enemy):
			found.append(enemy)
	return found


## "Shield Bearer: blocks blows from the front: ...".
static func hint_line(enemy: EnemyData) -> String:
	return "%s: %s" % [enemy.display_name, enemy.counter_hint]


## The pre-battle info: the foes coming, then how to beat each one that needs a plan (empty for a stage of plain foes).
static func battle_text(stage: StageData) -> String:
	var specials: Array[EnemyData] = special_foes(stage)
	if specials.is_empty():
		return ""
	var names: Array[String] = []
	for enemy: EnemyData in stage.enemy_types():
		names.append(enemy.display_name)
	var lines: Array[String] = ["Foes: " + ", ".join(names)]
	for enemy: EnemyData in specials:
		lines.append(hint_line(enemy))
	return "\n".join(lines)
