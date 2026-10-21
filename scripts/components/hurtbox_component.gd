class_name HurtboxComponent
extends Area2D
## Receives hits from hostile hitboxes and forwards damage to a HealthComponent.

signal hit_received(hit: HitData)

## What hit_filter says about a hit: take it, stop it (a shield: the hitbox counts it as its hit and stops trying), or let
## it pass through untouched (a flying enemy and a blade that cannot reach it).
enum Filter { ACCEPT, BLOCK, IGNORE }

@export var faction: Faction.Type = Faction.Type.DEFENDERS
## Falls back to a sibling named "HealthComponent" when unassigned.
@export var health_component: HealthComponent

## Optional owner check, called with the HitboxComponent before damage: returns a Filter. Unset = accept every hit.
var hit_filter: Callable
## The last receive_hit() was stopped by hit_filter (Filter.BLOCK).
var last_hit_blocked: bool = false

var _enabled: bool = true


func _ready() -> void:
	if health_component == null and get_parent() != null:
		health_component = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if health_component == null:
		push_error("HurtboxComponent '%s': no HealthComponent assigned." % name)
	monitoring = false
	monitorable = true
	collision_layer = Faction.hurtbox_layer(faction)
	collision_mask = 0


func set_enabled(value: bool) -> void:
	_enabled = value
	set_deferred("monitorable", value)


func is_enabled() -> bool:
	return _enabled


## One health pool counts as one target, even with several hurtboxes.
func get_target_id() -> int:
	return health_component.get_instance_id() if health_component != null else get_instance_id()


## Validates faction, liveness and invulnerability, then applies damage.
func receive_hit(hitbox: HitboxComponent) -> bool:
	last_hit_blocked = false
	if not _enabled or hitbox == null:
		return false
	if not Faction.are_hostile(hitbox.faction, faction):
		return false
	if health_component == null or health_component.is_dead() or health_component.is_invulnerable():
		return false
	if hit_filter.is_valid():
		var verdict: Filter = hit_filter.call(hitbox)
		if verdict != Filter.ACCEPT:
			last_hit_blocked = verdict == Filter.BLOCK
			return false
	var direction_x: float = hitbox.get_knockback_direction_x(global_position.x)
	var hit: HitData = HitData.new(hitbox.damage, Vector2(direction_x * hitbox.knockback, 0.0), hitbox.get_source())
	hit.heavy = hitbox.heavy
	hit.spirit = hitbox.spirit
	var applied: float = health_component.take_damage(hit.damage, hit.source)
	if applied <= 0.0:
		return false
	hit.damage = applied
	hit.killed = health_component.is_dead()
	hit_received.emit(hit)
	BattleFeedback.report_hit(get_parent(), get_feedback_position(), hit)
	return true


## Top-center of the first rectangular shape (where damage numbers appear).
func get_feedback_position() -> Vector2:
	for child: Node in get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node != null and shape_node.shape is RectangleShape2D:
			var rect: RectangleShape2D = shape_node.shape
			return shape_node.global_position - Vector2(0.0, rect.size.y * 0.5)
	return global_position
