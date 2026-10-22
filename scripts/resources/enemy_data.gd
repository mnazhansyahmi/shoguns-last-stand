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
## Light/ally hits deal damage without flinching or pushing. Player heavy/spirit
## attacks (including the heavy Ultimate) still interrupt this enemy.
@export var light_hit_armour: bool = false
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
## Shoots an arrow at the end of the windup instead of swinging (the Spectral Archer).
@export var ranged: bool = false
@export var projectile_speed: float = 650.0
@export var projectile_range: float = 620.0
## A ranged enemy backs away from a target closer than this (0 = never).
@export var keep_distance: float = 0.0

@export_group("Defence")
## Carries a shield: hits from in front are blocked; a heavy hit breaks the shield for good, and hits from behind always
## land (the Shield Bearer).
@export var shielded: bool = false
## Floats above the ground: only hits that reach the air land (HitboxComponent.reaches_air: arrows and the Onmyoji's
## fire), and melee allies leave it alone (the Flying Spirit).
@export var flying: bool = false
## How high a flying enemy floats (its hurtbox and look are lifted this far).
@export var hover_height: float = 0.0

@export_group("Visuals")
## Collision and hurtbox size; the figure is drawn at this height.
@export var body_size: Vector2 = Vector2(46.0, 110.0)
@export var figure: InkFigure.Kind = InkFigure.Kind.HOLLOW_SOLDIER
## Multiplies the figure's colours (a ghostly or burning version of a body that has no art of its own yet).
@export var tint: Color = Color.WHITE
## A weapon or effect drawn with the figure instead of its own weapon (see EnemyProp).
@export var prop: EnemyProp.Kind = EnemyProp.Kind.NONE
## A different scene to spawn this enemy with (a boss uses scenes/enemies/boss.tscn). Null = the generic enemy.
@export var scene: PackedScene

@export_group("Info")
## How to beat it, in a few words (the stage select and the pre-battle info show it). Empty for the familiar foes.
@export var counter_hint: String = ""
