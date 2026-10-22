class_name FirePillar
extends Node2D
## One of the Burning General's pillars of fire: it bursts from the ground (where his warning burned during the wind-up),
## burns everything standing in it once while it roars, then sinks back to embers. Damage only flows through a
## HitboxComponent, like every other attack.

const RISE_TIME: float = 0.12
const LIFETIME: float = 0.9

var _damage: float = 40.0
var _knockback: float = 300.0
var _size: Vector2 = Vector2(110.0, 260.0)
var _active_time: float = 0.35
var _source: Node
var _age: float = 0.0
var _hitbox: HitboxComponent
var _phase: float = 0.0


## Call before adding to the tree. The node's position is on the ground at the pillar's centre.
func setup(damage: float, knockback: float, size: Vector2, active_time: float, source: Node) -> void:
	_damage = damage
	_knockback = knockback
	_size = size
	_active_time = active_time
	_source = source


func _ready() -> void:
	z_index = 2
	_phase = randf() * TAU
	_hitbox = HitboxComponent.new()
	_hitbox.name = "Hitbox"
	_hitbox.faction = Faction.Type.ENEMIES
	add_child(_hitbox)
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = _size
	shape_node.shape = rect
	shape_node.position = Vector2(0.0, -_size.y * 0.5)
	_hitbox.add_child(shape_node)
	if is_instance_valid(_source):
		_hitbox.source = _source
	_hitbox.activate(_damage, _knockback, _active_time, true)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func is_burning() -> bool:
	return _hitbox != null and _hitbox.is_active()


func _draw() -> void:
	var rise: float = clampf(_age / RISE_TIME, 0.0, 1.0)
	var fade: float = 1.0 - smoothstep(_active_time, LIFETIME, _age)
	var height: float = _size.y * ease(rise, 0.4) * (0.55 + 0.45 * fade)
	var half: float = _size.x * 0.5
	# The first frame has no height yet: nothing to draw (a flat flame cannot be triangulated).
	if height < 4.0:
		return
	InkBrush.glow(self, Vector2(0.0, -height * 0.4), _size.x * 1.4, Color(InkPalette.HATAMOTO_ORANGE, 0.35 * fade))
	# Three layers of flame, outer to core, each a column of licking tongues.
	var layers: Array[Color] = [Color(InkPalette.ONI_EMBER, 0.85 * fade), Color(InkPalette.HATAMOTO_ORANGE, 0.9 * fade),
			Color(InkPalette.PAPER, 0.75 * fade)]
	for layer: int in layers.size():
		var scale_w: float = 1.0 - 0.3 * float(layer)
		var scale_h: float = 1.0 - 0.22 * float(layer)
		var outline: PackedVector2Array = PackedVector2Array()
		var steps: int = 9
		# Each side waves by at most half its own distance from the middle, so the sides never cross.
		for k: int in steps + 1:
			var u: float = float(k) / float(steps)
			var width: float = half * scale_w * (1.0 - 0.75 * u)
			var wave: float = sin(u * 9.0 + _age * 22.0 + _phase + float(layer)) * width * 0.45 * u
			outline.append(Vector2(-width + wave, -height * scale_h * u))
		for k: int in range(steps, -1, -1):
			var u: float = float(k) / float(steps)
			var width: float = half * scale_w * (1.0 - 0.75 * u)
			var wave: float = sin(u * 8.0 + _age * 19.0 + _phase * 1.7 + float(layer)) * width * 0.45 * u
			outline.append(Vector2(width + wave, -height * scale_h * u))
		draw_colored_polygon(outline, layers[layer])
	# Scorched ground under it.
	draw_set_transform(Vector2(0.0, -2.0), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, half * 1.1, Color(InkPalette.INK, 0.45 * fade))
	draw_set_transform(Vector2.ZERO)
