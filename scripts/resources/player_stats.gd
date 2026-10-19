class_name PlayerStats
extends Resource
## Samurai tuning data. Upgrades (Phase 4) will modify a copy of this resource.

@export_group("Vitals")
@export var max_health: float = 200.0
@export var hurt_duration: float = 0.25
@export var hurt_invulnerability: float = 0.7
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0

@export_group("Movement")
@export var move_speed: float = 210.0
@export var acceleration: float = 2400.0
@export var dash_distance: float = 135.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 3.0

@export_group("Melee")
@export var base_damage: float = 20.0
@export var combo_hit_1: AttackProfile
@export var combo_hit_2: AttackProfile
@export var combo_hit_3: AttackProfile
@export var heavy_attack: AttackProfile
@export var heavy_cooldown: float = 1.5

@export_group("Spirit Slash")
@export var spirit_slash_damage: float = 45.0
@export var spirit_slash_speed: float = 950.0
@export var spirit_slash_range: float = 1100.0
@export var spirit_slash_knockback: float = 220.0
@export var spirit_slash_cooldown: float = 6.0
@export var spirit_slash_windup: float = 0.15
@export var spirit_slash_recovery: float = 0.25

@export_group("Ultimate")
## Damage to every enemy on screen = base_damage x this (so attack upgrades raise it too).
@export var ultimate_damage_multiplier: float = 9.0
@export var ultimate_knockback: float = 520.0
## The samurai raises his blade this long (invulnerable), then the sweep lands.
@export var ultimate_windup: float = 0.35
@export var ultimate_recovery: float = 0.4
## Charge needed, and how fast it fills (see UltimateMeter).
@export var ultimate_charge_max: float = 100.0
@export var ultimate_charge_per_damage_dealt: float = 0.1
@export var ultimate_charge_per_damage_taken: float = 0.25
## Damage dealt by allies counts this fraction of the samurai's own toward the charge.
@export_range(0.0, 1.0) var ultimate_ally_share: float = 0.3


## Combo hits in order. Missing entries are replaced by defaults with an error.
func get_combo() -> Array[AttackProfile]:
	var combo: Array[AttackProfile] = []
	for profile: AttackProfile in [combo_hit_1, combo_hit_2, combo_hit_3]:
		if profile == null:
			push_error("PlayerStats: missing combo AttackProfile, using defaults.")
			profile = AttackProfile.new()
		combo.append(profile)
	return combo


func get_heavy_attack() -> AttackProfile:
	if heavy_attack == null:
		push_error("PlayerStats: missing heavy AttackProfile, using defaults.")
		heavy_attack = AttackProfile.new()
	return heavy_attack
