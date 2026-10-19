class_name BattleReward
extends RefCounted
## Gold and XP earned in one battle, with the breakdown shown on the result screen.

var victory: bool = false
var enemies_defeated: int = 0
var kill_gold: int = 0
var kill_xp: int = 0
var bonus_gold: int = 0
var bonus_xp: int = 0
## Fraction of kill rewards granted (1.0 on victory, the stage's defeat ratio otherwise).
var kill_ratio: float = 1.0
var gold: int = 0
var xp: int = 0
## The stage had been cleared before this battle, so gold was multiplied by replay_multiplier.
var replay: bool = false
var replay_multiplier: float = 1.0
