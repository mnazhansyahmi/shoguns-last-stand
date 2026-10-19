class_name RewardCalculator
extends RefCounted
## Turns the enemies killed in a battle into gold and XP.
## Victory: full kill rewards + the stage clear bonus.
## Defeat: kill rewards × stage.defeat_reward_ratio (rounded down), no bonus.
## Replay (stage already cleared): all gold × stage.replay_gold_multiplier (rounded down); XP unchanged.


static func calculate(killed: Array[EnemyData], stage: StageData, victory: bool, replay: bool = false) -> BattleReward:
	var reward: BattleReward = BattleReward.new()
	reward.victory = victory
	var raw_gold: int = 0
	var raw_xp: int = 0
	for enemy: EnemyData in killed:
		if enemy == null:
			continue
		reward.enemies_defeated += 1
		raw_gold += maxi(enemy.gold_reward, 0)
		raw_xp += maxi(enemy.xp_reward, 0)

	var ratio: float = 1.0
	if not victory:
		ratio = clampf(stage.defeat_reward_ratio, 0.0, 1.0) if stage != null else 0.0
	reward.kill_ratio = ratio
	reward.kill_gold = floori(raw_gold * ratio)
	reward.kill_xp = floori(raw_xp * ratio)
	if victory and stage != null:
		reward.bonus_gold = maxi(stage.clear_gold_bonus, 0)
		reward.bonus_xp = maxi(stage.clear_xp_bonus, 0)
	if replay and stage != null:
		reward.replay = true
		reward.replay_multiplier = clampf(stage.replay_gold_multiplier, 0.0, 1.0)
		reward.kill_gold = floori(reward.kill_gold * reward.replay_multiplier)
		reward.bonus_gold = floori(reward.bonus_gold * reward.replay_multiplier)
	reward.gold = reward.kill_gold + reward.bonus_gold
	reward.xp = reward.kill_xp + reward.bonus_xp
	return reward
