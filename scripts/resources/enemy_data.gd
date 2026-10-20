class_name EnemyData
extends Resource
## Configuration for one enemy type. One generic enemy scene reads this.

enum TargetKind { PLAYER, ALLY, GATE }

@export var display_name: String = "Enemy"

@export_group("Stats")
@export var max_health: float = 75.0
@export var attack_damage: float = 12.0
@export var move_speed: float = 70.0
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
## If false the enemy keeps attacking when hit (super armor). Damage still applies.
@export var interruptible: bool = true
@export var hurt_duration: float = 0.3

@export_group("Rewards")
@export var gold_reward: int = 5
@export var xp_reward: int = 10

@export_group("AI")
## Horizontal distance at which a target is noticed.
@export var aggro_range: float = 260.0
## Horizontal distance at which the enemy stops and attacks.
@export var attack_range: float = 70.0
## Checked in order; the nearest valid target of the first kind found is chosen.
@export var target_priorities: Array[TargetKind] = [TargetKind.PLAYER, TargetKind.ALLY, TargetKind.GATE]
@export var spawn_duration: float = 0.5

@export_group("Attack")
@export var attack: AttackProfile

@export_group("Visuals")
## Collision and hurtbox size; the figure is drawn at this height.
@export var body_size: Vector2 = Vector2(46.0, 110.0)
@export var figure: InkFigure.Kind = InkFigure.Kind.HOLLOW_SOLDIER
## A different scene to spawn this enemy with (a boss uses scenes/enemies/boss.tscn). Null = the generic enemy.
@export var scene: PackedScene
