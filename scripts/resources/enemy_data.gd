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
@export var body_size: Vector2 = Vector2(46.0, 110.0)
@export var body_color: Color = Color(0.45, 0.5, 0.45)
@export var head_color: Color = Color(0.75, 0.75, 0.68)
@export var weapon_length: float = 50.0
@export var show_horns: bool = false
