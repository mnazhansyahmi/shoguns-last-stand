class_name Afterimage
extends CanvasGroup
## A pale spirit copy of a figure left behind during a dash, fading out in place. A CanvasGroup
## so the copy fades as one shape. top_level, so it stays where it was left while the unit moves.

const LIFETIME: float = 0.22
const OPACITY: float = 0.5

var _age: float = 0.0


## Copies `source`'s current look. Call before adding to the tree.
func setup(source: InkFigure) -> void:
	top_level = true
	var copy: InkFigure = InkFigure.new()
	copy.height = source.height
	copy.kind = source.kind
	copy.pose.copy_from(source.pose)
	copy.stride = source.stride
	copy.stride_phase = source.stride_phase
	copy.trail = source.trail
	copy.clock = source.clock
	copy.flash = 0.6
	add_child(copy)
	self_modulate = Color(InkPalette.SPIRIT, OPACITY)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	self_modulate.a = OPACITY * (1.0 - _age / LIFETIME)
