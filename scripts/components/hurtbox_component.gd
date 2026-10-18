class_name HurtboxComponent
extends Area2D
## Receives hits from hostile hitboxes and forwards damage to a HealthComponent.

signal hit_received(hit: HitData)

@export var faction: Faction.Type = Faction.Type.DEFENDERS
## Falls back to a sibling named "HealthComponent" when unassigned.
@export var health_component: HealthComponent

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
	if not _enabled or hitbox == null:
		return false
	if not Faction.are_hostile(hitbox.faction, faction):
		return false
	if health_component == null or health_component.is_dead() or health_component.is_invulnerable():
		return false
	var direction_x: float = hitbox.get_knockback_direction_x(global_position.x)
	var hit: HitData = HitData.new(hitbox.damage, Vector2(direction_x * hitbox.knockback, 0.0), hitbox.get_source())
	var applied: float = health_component.take_damage(hit.damage, hit.source)
	if applied <= 0.0:
		return false
	hit.damage = applied
	hit_received.emit(hit)
	return true
