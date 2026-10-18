class_name WaveEntry
extends Resource
## A group of identical enemies inside a wave.

@export var enemy: EnemyData
@export var count: int = 1
## Delay before the first enemy of this entry spawns.
@export var start_delay: float = 0.0
## Delay between consecutive enemies of this entry.
@export var spawn_interval: float = 1.5
