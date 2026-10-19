class_name AllyData
extends Resource
## Configuration for one summonable ally type. One generic ally scene reads this.

## Stable key used by upgrades (UpgradeData.ally_id).
@export var id: String = ""
@export var display_name: String = "Ally"

@export_group("Summon")
@export var cost: float = 30.0
@export var summon_cooldown: float = 2.0

@export_group("Stats")
@export var max_health: float = 120.0
@export var attack_damage: float = 14.0
@export var move_speed: float = 120.0
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
@export var interruptible: bool = true
@export var hurt_duration: float = 0.25

@export_group("AI")
## Horizontal distance at which an enemy is noticed and engaged.
@export var aggro_range: float = 600.0
## Horizontal distance at which the ally stops and attacks.
@export var attack_range: float = 70.0
@export var spawn_duration: float = 0.4

@export_group("Attack")
@export var attack: AttackProfile
## Ranged allies fire a projectile at the end of windup instead of using their hitbox.
@export var is_ranged: bool = false
@export var projectile_speed: float = 900.0
@export var projectile_range: float = 700.0

@export_group("Visuals")
## Collision and hurtbox size; the figure is drawn at this height.
@export var body_size: Vector2 = Vector2(42.0, 100.0)
@export var figure: InkFigure.Kind = InkFigure.Kind.ASHIGARU
