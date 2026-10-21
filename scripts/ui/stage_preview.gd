class_name StagePreview
extends Control
## The picture on a stage card: the real Bamboo Outskirts backdrop layers (sky, sun or eclipse, clouds, mountains, mist,
## hills, bamboo, ground) painted with the stage's own AtmosphereTheme, scaled to cover the control and clipped to it.
## It is drawn once and kept, so it costs nothing while the card is on screen. It never touches the global
## atmosphere (the painter takes the theme as a parameter).

## The part of the battlefield the picture shows: the reference view of the backdrop (the ground line is y 880).
const VIEW: Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0)
const SEED: int = 1
const LAYERS: Array[BambooOutskirtsPainter.Layer] = [
	BambooOutskirtsPainter.Layer.SKY, BambooOutskirtsPainter.Layer.MOON,
	BambooOutskirtsPainter.Layer.CLOUDS_HIGH, BambooOutskirtsPainter.Layer.CLOUDS_LOW,
	BambooOutskirtsPainter.Layer.DISTANT_MOUNTAINS, BambooOutskirtsPainter.Layer.MOUNTAINS,
	BambooOutskirtsPainter.Layer.MIST_HIGH, BambooOutskirtsPainter.Layer.HILLS,
	BambooOutskirtsPainter.Layer.BAMBOO_FAR, BambooOutskirtsPainter.Layer.MIST_LOW,
	BambooOutskirtsPainter.Layer.BAMBOO_NEAR, BambooOutskirtsPainter.Layer.GROUND]

var theme_to_paint: AtmosphereTheme


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Paints with `atmosphere` (null = the default sunset).
func setup(atmosphere: AtmosphereTheme) -> void:
	theme_to_paint = atmosphere
	queue_redraw()


## The scale and offset that make VIEW cover a control of `control_size`, centred.
static func cover_transform(control_size: Vector2) -> Transform2D:
	var scale_factor: float = maxf(control_size.x / VIEW.size.x, control_size.y / VIEW.size.y)
	var origin: Vector2 = (control_size - VIEW.size * scale_factor) * 0.5 - VIEW.position * scale_factor
	return Transform2D(Vector2(scale_factor, 0.0), Vector2(0.0, scale_factor), origin)


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	var fit: Transform2D = cover_transform(size)
	draw_set_transform(fit.origin, 0.0, Vector2(fit.x.x, fit.y.y))
	for layer: BambooOutskirtsPainter.Layer in LAYERS:
		BambooOutskirtsPainter.paint(self, layer, SEED, theme_to_paint)
	draw_set_transform(Vector2.ZERO)
