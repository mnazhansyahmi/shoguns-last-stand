class_name FigurePortrait
extends RefCounted
## A portrait of a real in-game character for the upgrade shop: the InkFigure itself rendered once into a small
## SubViewport (on a dusk backdrop) and shown as a texture. A locked ally is shown as a black silhouette.

const SIZE: float = 144.0
## The figure stands this tall (pixels) in the portrait.
const FIGURE_HEIGHT: float = 112.0


## A SubViewport that renders `kind` once; add it to the scene tree (it renders on the next frame) and use its
## texture. `silhouette` blacks the figure out.
static func make_viewport(kind: InkFigure.Kind, silhouette: bool = false) -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(int(SIZE), int(SIZE))
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var backdrop: Control = Control.new()
	backdrop.size = Vector2(SIZE, SIZE)
	backdrop.set_script(PortraitBackdrop)
	viewport.add_child(backdrop)
	var figure: InkFigure = InkFigure.new()
	figure.height = FIGURE_HEIGHT * _fit(kind)
	figure.position = Vector2(SIZE * _shift(kind), SIZE - 10.0)
	figure.kind = kind
	viewport.add_child(figure)
	figure.refresh()
	if silhouette:
		figure.modulate = Color(0.01, 0.01, 0.03, 1.0)
	return viewport


## Draws the dusk backdrop (sky to ground) every portrait and icon sits on.
static func draw_backdrop(ci: CanvasItem, size: Vector2) -> void:
	var steps: int = 12
	for i: int in steps:
		var t: float = float(i) / float(steps - 1)
		var color: Color = InkPalette.SKY_HORIZON.darkened(0.25).lerp(InkPalette.GROUND_TOP.darkened(0.35), smoothstep(0.55, 1.0, t))
		ci.draw_rect(Rect2(0.0, size.y * float(i) / float(steps), size.x, size.y / float(steps) + 1.0), color)
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(InkPalette.GOLD, 0.6), false, 2.0)


## Big figures are drawn smaller so their whole body fits.
static func _fit(kind: InkFigure.Kind) -> float:
	match kind:
		InkFigure.Kind.ONI_BRUTE, InkFigure.Kind.FALLEN_DAIMYO:
			return 0.8
		InkFigure.Kind.HATAMOTO, InkFigure.Kind.SPEAR_GUARDIAN:
			return 0.92
	return 1.0


## Where the figure stands across the portrait (a fraction of its width): the long weapons point right, so a little left.
static func _shift(_kind: InkFigure.Kind) -> float:
	return 0.42


## The portrait's backdrop as a drawing control.
class PortraitBackdrop extends Control:
	func _draw() -> void:
		FigurePortrait.draw_backdrop(self, size)
