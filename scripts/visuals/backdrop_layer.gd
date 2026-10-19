class_name BackdropLayer
extends Node2D
## One layer of a code-drawn region backdrop. The layer is drawn once (static art). It then
## moves for parallax: a layer at depth d follows the camera by (1 - d), so depth 0 stays fixed
## on screen (sky), depth 1 is locked to the world (ground), and layers in between move less
## than the world as the camera follows the player, lifts or shakes. With a zoomed camera the
## far layers are also magnified less (see layer_transform). Fog layers also drift sideways by
## `drift_speed`; their art repeats every `tile_width` pixels and is drawn twice, so the drift
## wraps seamlessly.

## Which picture this layer paints (see BambooOutskirtsPainter).
@export var layer: BambooOutskirtsPainter.Layer = BambooOutskirtsPainter.Layer.SKY
## 0 = infinitely far (fixed on screen), 1 = on the battlefield plane.
@export_range(0.0, 1.2) var depth: float = 1.0
## Sideways drift in pixels per second (fog). 0 = still.
@export var drift_speed: float = 0.0
## Width after which a drifting layer's art repeats.
@export var tile_width: float = 3600.0
## World point at the screen centre when the camera is at rest (battlefield camera position).
@export var reference_center: Vector2 = Vector2(960.0, 540.0)
@export var seed_value: int = 1

var _drift: float = 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if drift_speed != 0.0:
		_drift = fposmod(_drift + drift_speed * delta, tile_width)
	var viewport: Viewport = get_viewport()
	var zoom: float = viewport.get_canvas_transform().get_scale().x if viewport != null else 1.0
	var xf: Transform2D = layer_transform(view_center(), reference_center, depth, zoom)
	scale = xf.get_scale()
	position = xf.origin - Vector2(_drift * xf.get_scale().x, 0.0)


## World point at the centre of the screen (includes camera offset, i.e. screen shake).
func view_center() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return reference_center
	return viewport.get_canvas_transform().affine_inverse() * (viewport.get_visible_rect().size * 0.5)


## Layer offset for an unzoomed camera at `center`: it follows the camera by (1 - depth).
static func parallax_offset(center: Vector2, reference: Vector2, layer_depth: float) -> Vector2:
	return (center - reference) * (1.0 - layer_depth)


## Layer transform for a camera at `center` with `zoom`. On screen a layer is magnified by
## lerp(1, zoom, depth) (the sky is never magnified, the ground fully) and moves by `depth` of
## the camera's movement, around the reference view it was painted for. With zoom 1 this is
## exactly parallax_offset().
static func layer_transform(center: Vector2, reference: Vector2, layer_depth: float, zoom: float) -> Transform2D:
	var screen_scale: float = lerpf(1.0, zoom, layer_depth)
	var layer_scale: float = screen_scale / zoom
	var origin: Vector2 = center * (1.0 - layer_depth) + reference * layer_depth - reference * layer_scale
	return Transform2D(0.0, Vector2(layer_scale, layer_scale), 0.0, origin)


func _draw() -> void:
	if drift_speed == 0.0:
		BambooOutskirtsPainter.paint(self, layer, seed_value)
		return
	# Three copies so the drift wraps without a visible seam at either screen edge.
	for copy: int in [-1, 0, 1]:
		draw_set_transform(Vector2(tile_width * copy, 0.0))
		BambooOutskirtsPainter.paint(self, layer, seed_value)
	draw_set_transform(Vector2.ZERO)
