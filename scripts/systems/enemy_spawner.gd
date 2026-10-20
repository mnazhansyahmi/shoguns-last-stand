class_name EnemySpawner
extends Node2D
## Spawns enemies at this node's position. Used by debug keys now, by the WaveDirector in Phase 3.

signal enemy_spawned(enemy: Enemy)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")

## Where spawned enemies are parented. Defaults to this node's parent.
@export var container: Node
## Performance guard: maximum enemies alive (including dying corpses) at once.
@export var max_alive: int = 40
@export var spawn_jitter_x: float = 40.0

var _alive: int = 0


func spawn(enemy_data: EnemyData) -> Enemy:
	if enemy_data == null:
		push_error("EnemySpawner: spawn() called with null EnemyData.")
		return null
	if _alive >= max_alive:
		push_warning("EnemySpawner: enemy limit (%d) reached, spawn skipped." % max_alive)
		return null
	var parent: Node = container if is_instance_valid(container) else get_parent()
	var scene: PackedScene = enemy_data.scene if enemy_data.scene != null else ENEMY_SCENE
	var enemy: Enemy = scene.instantiate() as Enemy
	enemy.setup(enemy_data)
	parent.add_child(enemy)
	enemy.global_position = global_position + Vector2(randf_range(-spawn_jitter_x, spawn_jitter_x), 0.0)
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited)
	enemy_spawned.emit(enemy)
	return enemy


func get_alive_count() -> int:
	return _alive


func _on_enemy_tree_exited() -> void:
	_alive = maxi(_alive - 1, 0)
