class_name SlashTrail
extends InkEffect
## A weapon's swing as a crescent ribbon: sampled blade positions from the windup pose to the
## strike pose, a paper-white core along the cutting edge fading into the wielder's colour.
## The tail retracts toward the leading edge as it fades.

const LIFETIME: float = 0.18
const HEAVY_LIFETIME: float = 0.24

var _bases: PackedVector2Array = PackedVector2Array()
var _tips: PackedVector2Array = PackedVector2Array()
var _core: Color = InkPalette.PAPER
var _edge: Color = InkPalette.SAMURAI_RED
## How far the ribbon reaches from the tip toward the hilt (0..1).
var _depth: float = 0.55


## `bases` / `tips` are matching blade samples from the start to the end of the swing.
func setup(bases: PackedVector2Array, tips: PackedVector2Array, core: Color, edge: Color, heavy: bool) -> void:
	_bases = bases
	_tips = tips
	_core = core
	_edge = edge
	_depth = 0.85 if heavy else 0.65
	lifetime = HEAVY_LIFETIME if heavy else LIFETIME


func _draw() -> void:
	var count: int = _tips.size()
	if count < 2:
		return
	var p: float = progress()
	var fade: float = 1.0 - p
	var start: int = mini(int(p * float(count - 1) * 0.85), count - 2)
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var core_inner: PackedVector2Array = PackedVector2Array()
	var outer_colors: PackedColorArray = PackedColorArray()
	var inner_colors: PackedColorArray = PackedColorArray()
	var core_colors: PackedColorArray = PackedColorArray()
	var core_clear: PackedColorArray = PackedColorArray()
	for i: int in range(start, count):
		var t: float = float(i - start) / float(count - 1 - start)
		var tip: Vector2 = _tips[i]
		var reach: float = _depth * (0.35 + 0.65 * t)
		var strength: float = fade * (0.25 + 0.75 * t)
		outer.append(tip)
		inner.append(tip.lerp(_bases[i], reach))
		core_inner.append(tip.lerp(_bases[i], reach * 0.45))
		outer_colors.append(Color(_edge, _edge.a * strength))
		inner_colors.append(Color(_edge, _edge.a * strength * 0.3))
		core_colors.append(Color(_core, _core.a * strength))
		core_clear.append(Color(_core, _core.a * strength * 0.15))
	InkBrush.ribbon(self, outer, inner, outer_colors, inner_colors)
	InkBrush.ribbon(self, outer, core_inner, core_colors, core_clear)
	# Crisp cutting edge: tapered accent stroke with a paper line inside, thickest at the lead.
	var edge_width: float = (9.0 if _depth > 0.8 else 7.0) * (1.0 - 0.5 * p)
	InkBrush.stroke(self, outer, 1.0, edge_width, Color(_edge, _edge.a * fade))
	InkBrush.stroke(self, outer, 0.6, edge_width * 0.38, Color(_core, _core.a * fade))
