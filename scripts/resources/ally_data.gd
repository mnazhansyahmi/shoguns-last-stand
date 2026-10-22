class_name AllyData
extends Resource
## Configuration for one summonable ally type. One generic ally scene reads this.

## What an ally does: FIGHTER attacks enemies (melee or with arrows), HEALER restores injured
## allies (attack_damage is the amount healed, attack_range the reach), MAGE casts a burst that
## hits every enemy within area_radius of its target.
enum Role { FIGHTER, HEALER, MAGE }

## Stable key used by upgrades (UpgradeData.ally_id).
@export var id: String = ""
@export var display_name: String = "Ally"
@export var role: Role = Role.FIGHTER
@export_multiline var description: String = ""

@export_group("Roster")
## The stage that must have been cleared before this ally can be summoned ("" = from the start).
@export var unlock_stage_id: String = ""

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

@export_group("Support")
## MAGE: radius of the burst around the target. HEALER: allies below this health ratio are healed.
@export var area_radius: float = 0.0
@export_range(0.0, 1.0) var heal_below_ratio: float = 0.9
## Enemies within this horizontal distance of the ally pick it as their target before other
## allies (a tank's taunt). 0 = no taunt.
@export var taunt_range: float = 0.0
## Its blows break a Shield Bearer's shield like the samurai's heavy attack (the counter to shields).
@export var breaks_shields: bool = false

@export_group("Visuals")
## Collision and hurtbox size; the figure is drawn at this height.
@export var body_size: Vector2 = Vector2(42.0, 100.0)
@export var figure: InkFigure.Kind = InkFigure.Kind.ASHIGARU


## Archers' arrows and the mage's fire reach flying enemies; blades and spears do not.
func can_hit_air() -> bool:
	return is_ranged or role == Role.MAGE


## Ranged-style allies (archers, healers, mages) may stand behind others and keep their distance.
func is_ranged_like() -> bool:
	return is_ranged or role != Role.FIGHTER
