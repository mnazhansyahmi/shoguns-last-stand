class_name BossPhaseData
extends Resource
## One phase of a boss fight. A phase starts when the boss's health falls to `start_ratio`.

## Health ratio (0..1) at which this phase begins: 1.0, 0.66, 0.33.
@export_range(0.0, 1.0) var start_ratio: float = 1.0
## Walking speed and attack speed (wind-ups, recoveries and cooldowns shrink by this).
@export var speed_multiplier: float = 1.0
## Damage of every attack.
@export var damage_multiplier: float = 1.0
## How long he roars, untouchable, when this phase begins (the dramatic pause).
@export var pause_time: float = 1.4
## Gap between one attack ending and the next being chosen.
@export var attack_gap: float = 1.2
## Short line shown on screen when the phase begins.
@export var banner: String = ""
