class_name SpiritSlashVisual
extends Node2D
## The Spirit Slash projectile's look: a luminous crescent (paper core, spirit-blue edge) with an
## additive halo, fading ghost crescents trailing behind and drifting motes. Faces +x; the
## projectile mirrors it. The hitbox is on the projectile and is unaffected by this.

const RADIUS: float = 80.0
const ARC: float = 1.15
const GHOSTS: int = 3

var _clock: float = 0.0
var _glow_layer: Node2D


func _ready() -> void:
	_glow_layer = Node2D.new()
	_glow_layer.name = "Halo"
	_glow_layer.material = InkFigure.additive_material()
	_glow_layer.show_behind_parent = true
	add_child(_glow_layer)
	_glow_layer.draw.connect(_draw_halo)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	_glow_layer.queue_redraw()


## Crescent polygon: outer arc out to the tip, thinner inner arc back.
static func crescent_points(radius: float, thickness: float, offset_x: float) -> PackedVector2Array:
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var t: float = float(i) / 12.0
		var angle: float = lerpf(-ARC, ARC, t)
		var width: float = thickness * sin(t * PI)
		outer.append(Vector2(cos(angle) * radius + offset_x - radius, sin(angle) * radius * 1.05))
		inner.append(Vector2(cos(angle) * (radius - width) + offset_x - radius - width * 0.4, sin(angle) * (radius - width) * 1.05))
	inner.reverse()
	outer.append_array(inner)
	return outer


func _draw() -> void:
	var flicker: float = 0.9 + 0.1 * sin(_clock * 40.0)
	for ghost: int in range(GHOSTS, 0, -1):
		var back: float = -26.0 * ghost
		InkBrush.fill(self, crescent_points(RADIUS * (1.0 - 0.08 * ghost), 16.0, 36.0 + back),
				Color(InkPalette.SPIRIT, 0.22 / ghost))
	InkBrush.fill(self, crescent_points(RADIUS, 26.0, 40.0), Color(InkPalette.SPIRIT, 0.85 * flicker))
	InkBrush.fill(self, crescent_points(RADIUS * 0.98, 11.0, 38.0), Color(InkPalette.PAPER, flicker))
	for i: int in 7:
		var phase: float = fposmod(_clock * 2.2 + float(i) * 0.37, 1.0)
		var mote: Vector2 = Vector2(-20.0 - phase * 120.0, sin(float(i) * 2.1) * 60.0 + sin(_clock * 9.0 + i) * 6.0)
		draw_circle(mote, 3.0 * (1.0 - phase), Color(InkPalette.PAPER, 0.8 * (1.0 - phase)))


func _draw_halo() -> void:
	InkBrush.glow(_glow_layer, Vector2(10.0, 0.0), 120.0, Color(InkPalette.SPIRIT, 0.5))
	InkBrush.glow(_glow_layer, Vector2(-40.0, 0.0), 80.0, Color(InkPalette.SPIRIT, 0.25))
